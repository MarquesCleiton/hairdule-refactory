# 🟡 [VULN-07] [MÉDIO] Origem HTTP Insegura (S3 Website em Texto Claro) Permitida com Credenciais no CORS

| Metadado | Detalhe |
|---|---|
| **ID da Vulnerabilidade** | `VULN-07` |
| **Status da Correção** | [x] ✅ **CORRIGIDO E VALIDADO** (2026-09-28) |
| **Severidade** | 🟡 **MÉDIA (CVSS 5.9)** |
| **CVSS v3.1 Vector** | `CVSS:3.1/AV:A/AC:H/PR:N/UI:R/S:U/C:H/I:H/A:N` |
| **Classificação CWE** | [CWE-942: Permissive Cross-domain Policy with Untrusted Domains](https://cwe.mitre.org/data/definitions/942.html) / [CWE-319: Cleartext Transmission of Sensitive Information](https://cwe.mitre.org/data/definitions/319.html) |
| **Componentes Afetados** | [`fase_07_hairdule_infra_api/config/environments.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/config/environments.ts#L158-L169) |
| **Configuração Insegura** | `"http://hairdule-ui-admin-staging-351083991126.s3-website-us-east-1.amazonaws.com"` com `allowCredentials: true` |

---

## 1. Descrição Técnica da Falha

No arquivo de configuração de ambientes do API Gateway ([`fase_07_hairdule_infra_api/config/environments.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/config/environments.ts#L146-L171)), a lista de origens autorizadas para CORS no ambiente de staging inclui:

```typescript
// Trecho de config/environments.ts (Linhas 148 a 170)
cors: {
  allowOrigins: [
    "http://localhost:4200",
    "http://localhost:4300",
    "https://staging.hairdule.com",
    "https://app.staging.hairdule.com",
    "https://staging.hairdule.com.br",
    "https://auth.staging.hairdule.com.br",
    "https://d19dlqxhe17bcr.cloudfront.net",
    "https://d2oisu1nq6xe4o.cloudfront.net",
    "http://hairdule-ui-admin-staging-351083991126.s3-website-us-east-1.amazonaws.com", // ⚠️ HTTP INSEGURO
  ],
  allowMethods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  ...
  allowCredentials: true, // ⚠️ Envio de Cookies de Sessão Ativado
  maxAge: 300,
}
```

### O Defeito de Segurança:
O endpoint do S3 Static Website (`http://...s3-website-us-east-1.amazonaws.com`) opera **exclusivamente sobre HTTP sem criptografia TLS**.
Ao mesmo tempo, a política de CORS define `allowCredentials: true`, autorizando que requisições originadas desse domínio incluam os cookies de autenticação (`access_token` e `refresh_token`) do usuário.

---

## 2. Cenário de Ataque e Exploração Teórica

### Vetor Teórico de Exploração (Man-in-the-Middle - MitM):
1. Um administrador do Hairdule acessa o portal administrativo pelo endereço de teste S3 em uma rede compartilhada (Wi-Fi de aeroporto, cafeteria ou rede corporativa com proxy).
2. Como a conexão é HTTP em texto claro, um atacante na mesma rede física intercepta o tráfego e executa um ataque de injeção de pacotes HTTP (MitM).
3. O atacante injeta um trecho de código JavaScript na resposta HTML do S3:
   ```javascript
   fetch('https://api.staging.hairdule.com/admin/barbershops', {
     credentials: 'include'
   }).then(r => r.json()).then(data => sendToAttacker(data));
   ```
4. O navegador da vítima acata o script injetado no contexto da origem `http://hairdule-ui-admin...`.
5. Como essa origem exata está na lista de `allowOrigins` do API Gateway com `allowCredentials: true`, o navegador anexa os cookies HttpOnly da vítima e entrega a resposta completa de todas as barbearias ao atacante.

---

## 3. Impacto de Negócio e de Segurança

- **Bypass de Proteções Criptográficas**: Quebra a garantia de integridade e confidencialidade do tráfego HTTPS.
- **Sequestro de Ações Administrativas**: Capacidade de executar operações privilegiadas no backend em nome do administrador sem que ele perceba.

---

## 4. Plano de Remediação Recomendado

### Passo 1: Remover Imediatamente a Origem HTTP do CORS
No arquivo [`fase_07_hairdule_infra_api/config/environments.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/config/environments.ts):
- Excluir a linha `"http://hairdule-ui-admin-staging-351083991126.s3-website-us-east-1.amazonaws.com"`.
- Nunca utilizar endpoints `.s3-website` diretamente em navegadores ou no CORS de produção/homologação.

### Passo 2: Exigir HTTPS Obrigatório via CloudFront
O acesso ao Portal SuperAdmin deve ser feito **única e exclusivamente** através da distribuição CloudFront com HTTPS forçado (`https://d2oisu1nq6xe4o.cloudfront.net` ou subdomínio corporativo com certificado TLS ACM).

---

## 5. Evidência da Correção Aplicada

- **Arquivo Modificado**: [`fase_07_hairdule_infra_api/config/environments.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/config/environments.ts)
- **Implementação**:
  - A URL insegura em texto puro (`http://hairdule-ui-admin-staging-351083991126.s3-website-us-east-1.amazonaws.com`) foi completamente removida da lista `allowOrigins` do CORS.
  - Apenas origens HTTPS válidas ou desenvolvimento local (`http://localhost:*`) são permitidas.
  - O acesso administrativo fica restrito à distribuição segura CloudFront (`https://d2oisu1nq6xe4o.cloudfront.net`).

