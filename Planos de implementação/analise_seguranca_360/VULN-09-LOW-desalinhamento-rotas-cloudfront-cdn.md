# 🟢 [VULN-09] [BAIXO / ARQUITETURA] Desalinhamento de Roteamento de Microsserviços no CloudFront CDN

| Metadado | Detalhe |
|---|---|
| **ID da Vulnerabilidade** | `VULN-09` |
| **Status da Correção** | [x] ✅ **CORRIGIDO E VALIDADO** (2026-09-28) |
| **Severidade** | 🟢 **BAIXA / ARQUITETURA (CVSS 3.7)** |
| **CVSS v3.1 Vector** | `CVSS:3.1/AV:N/AC:H/PR:N/UI:N/S:U/C:N/I:L/A:N` |
| **Classificação CWE** | [CWE-1188: Insecure Default Initialization of Resource](https://cwe.mitre.org/data/definitions/1188.html) |
| **Componentes Afetados** | [`fase_20_hairdule_infra_cdn/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_20_hairdule_infra_cdn/sst.config.ts#L133-L146)<br>[`INDICE_MESTRE.md`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/Hairdule%202.0/Planos%20de%20implementa%C3%A7%C3%A3o/INDICE_MESTRE.md#L169) |

---

## 1. Descrição Técnica da Falha

No documento de arquitetura [`INDICE_MESTRE.md`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/Hairdule%202.0/Planos%20de%20implementa%C3%A7%C3%A3o/INDICE_MESTRE.md#L169), a diretriz de rede estabelece:
> *"Roteamento de Borda Unificado: **AWS CloudFront** como Reverse Proxy unificado (`/*` -> S3 Web SPA; `/auth/*`, `/barbershop/*`, `/staff/*`, `/services/*`, `/public/*` -> API Gateway) **garantindo Same-Origin e eliminando problemas de CORS**."*

No entanto, no arquivo de provisionamento real da Fase 20 ([`fase_20_hairdule_infra_cdn/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_20_hairdule_infra_cdn/sst.config.ts#L133-L146)), a distribuição CloudFront foi configurada com apenas três comportamentos de cache ordenados para o API Gateway:

```typescript
// Trecho de fase_20_hairdule_infra_cdn/sst.config.ts (Linhas 133 a 146)
orderedCacheBehaviors: [
  {
    pathPattern: "/auth*",
    ...apiCacheBehavior,
  },
  {
    pathPattern: "/barbershop*",
    ...apiCacheBehavior,
  },
  {
    pathPattern: "/public*",
    ...apiCacheBehavior,
  },
],
```

### O Desalinhamento:
Todos os demais microsserviços implementados nas fases posteriores **foram omitidos** do CloudFront:
- `/staff*` (Fase 11)
- `/services*` (Fase 13)
- `/business-hours*`, `/availability*` (Fase 15)
- `/appointments*`, `/customers*` (Fase 17)
- `/notifications*`, `/push*` (Fase 24)
- `/analytics*` (Fase 26)

Como esses caminhos não estão mapeados no CloudFront, qualquer requisição direcionada para `https://d19dlqxhe17bcr.cloudfront.net/staff` cai no comportamento padrão (`defaultCacheBehavior`), que consulta o Bucket S3 e devolve o `index.html` (devido à regra customizada de erro 403/404 para SPAs).

---

## 2. Cenário de Ataque e Exploração Teórica

### Impacto na Postura de Segurança:
1. Para contornar a falha de roteamento no CDN, o frontend Angular foi obrigado a disparar chamadas diretamente para o domínio bruto do API Gateway (`https://<apiId>.execute-api.us-east-1.amazonaws.com`).
2. Isso quebrou o princípio de **Same-Origin** (Mesma Origem).
3. Ao tornar as requisições cross-origin, os cookies de autenticação com flag `SameSite=Lax` não são enviados automaticamente em determinadas chamadas assíncronas do navegador, forçando o frontend a utilizar e armazenar o token em cabeçalhos `Authorization: Bearer` e `localStorage` (contribuindo diretamente para a `VULN-06`).
4. Além disso, expõe o endpoint interno da AWS diretamente na internet, contornando proteções e certificados de borda.

---

## 3. Impacto de Negócio e de Segurança

- **Quebra do Modelo Same-Origin**: Aumenta a complexidade e a superfície de ataque por exigir CORS permissivo com `allowCredentials: true`.
- **Inconsistência de Roteamento**: Dificulta a adoção de WAF unificado e cabeçalhos de segurança (CSP, HSTS) centralizados no CloudFront.

---

## 4. Plano de Remediação Recomendado

### Passo 1: Atualizar os Cache Behaviors no CloudFront
No arquivo [`fase_20_hairdule_infra_cdn/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_20_hairdule_infra_cdn/sst.config.ts), incluir todos os prefixos de rota oficiais dos microsserviços:

```typescript
orderedCacheBehaviors: [
  { pathPattern: "/auth*", ...apiCacheBehavior },
  { pathPattern: "/barbershop*", ...apiCacheBehavior },
  { pathPattern: "/staff*", ...apiCacheBehavior },
  { pathPattern: "/services*", ...apiCacheBehavior },
  { pathPattern: "/business-hours*", ...apiCacheBehavior },
  { pathPattern: "/availability*", ...apiCacheBehavior },
  { pathPattern: "/appointments*", ...apiCacheBehavior },
  { pathPattern: "/customers*", ...apiCacheBehavior },
  { pathPattern: "/notifications*", ...apiCacheBehavior },
  { pathPattern: "/push*", ...apiCacheBehavior },
  { pathPattern: "/analytics*", ...apiCacheBehavior },
  { pathPattern: "/admin*", ...apiCacheBehavior },
  { pathPattern: "/public*", ...apiCacheBehavior },
],
```

### Passo 2: Padronizar o Frontend em URLs Relativas
Com o CloudFront atuando como Reverse Proxy completo, o frontend Web (`fase_08`) e Admin (`fase_31`) podem configurar a `apiUrl` simplesmente como string vazia `""` ou `"/api"` / caminhos relativos (`/auth/login`, `/appointments`), garantindo tráfego 100% Same-Origin sem necessidade de pre-flight CORS para a mesma origem.

---

## 5. Evidência da Correção Aplicada

- **Arquivo Modificado**: [`fase_20_hairdule_infra_cdn/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_20_hairdule_infra_cdn/sst.config.ts)
- **Implementação**:
  - `orderedCacheBehaviors` no CloudFront foi estendido para incluir todos os 14 prefixos e rotas do backend:
    - `/auth*`
    - `/barbershop*`
    - `/public*`
    - `/staff*`
    - `/services*`
    - `/business-hours*`
    - `/availability*`
    - `/appointments*`
    - `/customers*`
    - `/notifications*`
    - `/push*`
    - `/analytics*`
    - `/admin*`
    - `/health`
  - Restabelece a integridade da arquitetura de borda unificada com cache dinâmico desativado (`Managed-CachingDisabled`), repasse de cookies HttpOnly (`Managed-AllViewerExceptHostHeader`) e eliminação de falhas SPA 404/403 para rotas de microsserviços.

