# VULN-10 — Ausência de Geo-blocking no CloudFront (Exposição a Scanners Internacionais e Botnets)

> **Status:** [x] ✅ **Corrigido e Validado em Homologação (PR #14 da fase_20)**  
> **Severidade:** 🔶 **ALTA**  
> **CVSS v3.1:** 7.5 (`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H`)  
> **Repositório Afetado:** [`fase_20_hairdule_infra_cdn`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_20_hairdule_infra_cdn)  
> **Arquivo Alvo:** [`sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_20_hairdule_infra_cdn/sst.config.ts)

---

## 1. Descrição da Vulnerabilidade

O CloudFront CDN que atua como distribuição principal do Web SPA e Reverse Proxy das APIs públicas e administrativas está configurado com `restrictions: { geoRestriction: { restrictionType: "none" } }`.

Isso permite que qualquer requisitante no mundo (China, Rússia, Europa, EUA) envie requisições irrestritas para as APIs do Hairdule. Mais de 85% dos ataques de botnets, crawlers maliciosos e scanners automatizados de portas e vulnerabilidades têm origem em datacenters e redes fora do Brasil.

Como o Hairdule é um SaaS exclusivo para o mercado brasileiro de beleza e barbearias, não há justificativa de negócio para permitir tráfego internacional nos endpoints de autenticação e agendamento.

---

## 2. Cenário de Ataque

```
[ Botnet / Scanner Internacional (ex: Rússia / China) ]
       │
       ▼ (Requisição HTTP direta para CloudFront CDN)
[ CloudFront aceita porque restrictionType = "none" ]
       │
       ▼
[ Encaminha chamada para API Gateway / Lambdas na AWS ]
       │
       ▼
[ Consome concorrência de Lambda, conexões de banco e custo AWS ]
```

---

## 3. Evidência no Código Atual

Arquivo: `fase_20_hairdule_infra_cdn/sst.config.ts` (linhas 206 a 210):

```typescript
      restrictions: {
        geoRestriction: {
          restrictionType: "none", // ⚠️ Aberto mundialmente
        },
      },
```

---

## 4. Solução Técnica Proposta

Configurar a restrição geográfica do CloudFront para o modo `whitelist` com `locations: ["BR"]`:

```typescript
      restrictions: {
        geoRestriction: {
          restrictionType: "whitelist",
          locations: ["BR"], // 🇧🇷 Permite exclusivamente o Brasil
        },
      },
```

* **Vantagens:**
  - 100% nativo e gratuito na AWS.
  - O descarte ocorre no Edge Location da AWS mais próximo do invasor com `HTTP 403 Forbidden`.
  - A requisição nunca chega na VPC ou nas Lambdas do Hairdule.

---

## 5. Checklist de Implementação & Validação

- [x] Modificar `sst.config.ts` na `fase_20_hairdule_infra_cdn` definindo `restrictionType: "whitelist"` e `locations: ["BR"]`.
- [x] Executar deploy em Homologação (`release/v7`) via esteira de CI/CD (PR #14 mergeado).
- [x] Validar que tráfego de IPs fora do Brasil é bloqueado no Edge com `403 Forbidden`.
- [x] Validar que conexões com IP brasileiro continuam recebendo `200 OK`.
