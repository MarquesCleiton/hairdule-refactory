# 🌐 Fase 07 — API Gateway + WAF (`fase_07_hairdule_infra_api`)
## Checklist de Execução — Status Completo & Otimizado

> **Repositório:** `fase_07_hairdule_infra_api`  
> **Tecnologia:** SST v4, TypeScript — AWS API Gateway v2 (HTTP API) + AWS WAF + Cognito JWT Authorizer  
> **Dependências Diretas:** Fase 03 (`userPoolId`, `userPoolClientId`) + Fase 06 (`fase_06_hairdule_auth_service`)  
> **Última atualização:** 2026-08-17 (Otimizações de Borda e Performance Homologadas na AWS)  

---

## 🎯 Objetivo da Fase

A Fase 07 é a **porta de entrada unificada para o backend do Hairdule 2.0**. Requisições do frontend Angular (Dashboard e Portal) passam obrigatoriamente por este API Gateway v2 HTTP API com proteção de WAF (Rate Limiting, WAF Rulesets) e autorização JWT via AWS Cognito.

---

## 🚪 Mapeamento de Responsabilidades de Borda (Otimizado)

```
                      🌍 INTERNET (Frontends Angular / Mobile)
                                        │
                                        ▼
                          [ 🛡️ AWS WAF v2 (Regional) ]
               ├── AWSManagedRulesCommonRuleSet (OWASP Top 10)
               ├── AWSManagedRulesKnownBadInputsRuleSet
               └── RateLimit: 300 req / 5 min por IP
                                        │
                                        ▼
                        [ 🌐 API Gateway v2 (HTTP API) ]
                              hairdule-api-{stage}
               ├── CORS 100% no Edge (Responde OPTIONS via 204 em ~1ms sem Lambda)
               ├── Rejeição de métodos/rotas inválidas com 404 direto no Gateway
               ├── $default Stage com Auto-Deploy & Access Logs
               └── JWT Authorizer (Cognito User Pool Fase 03)
                                        │
                       ┌────────────────┴────────────────┐
                       ▼                                 ▼
               Rotas Públicas                    Rotas Protegidas
            POST /auth/signup                  (Fases Futuras 09+)
            POST /auth/login                   GET /auth/me
            POST /auth/refresh                 POST /auth/logout
            POST /auth/forgot-password         GET /barbershop
            POST /auth/reset-password          PUT /barbershop
            POST /auth/change-password         POST /barbershop/onboarding-complete
                        │                      (Exigem Cookie HttpOnly ou Bearer JWT)
                        ▼
          [ ⚡ AWS Lambda (Auth Service - Fase 06) ]
                ├── Emissão de Cookies HttpOnly (Set-Cookie)
                ├── JOIN Único (UserRole + Barbershop) no PostgreSQL
                └── Bcrypt Rounds=10 (OWASP otimizado: 250ms CPU)
```

---

## ✅ Checklist Completo da Fase 07

### 🌐 1. API Gateway v2 HTTP API

- [x] **`aws.apigatewayv2.Api`** — `hairdule-api-staging` (ID: `nlrx258a8i`):
  - Protocol: `HTTP`
  - URL Endpoint: `https://nlrx258a8i.execute-api.us-east-1.amazonaws.com`
  - CORS global ativo com `allowCredentials: true` e origens explícitas autorizadas (`localhost:4300`, `localhost:4200`, CloudFront `d19dlqxhe17bcr.cloudfront.net`, `staging.hairdule.com.br`)
  - Interceptação de pre-flight `OPTIONS` respondendo `204 No Content` no edge
  - Access Logs dedicados no CloudWatch (`/aws/apigateway/hairdule-api-staging`)
- [x] **JWT Authorizer (`aws.apigatewayv2.Authorizer`):**
  - Integração com Cognito User Pool da Fase 03 (`us-east-1_tPfrA7wPP`)
  - Audience: `4vqg1sg2jfba793ctgo9r2l84h`
  - Authorizer ID: `5syzz5`

---

### 🛡️ 2. AWS WAF v2 (Web Application Firewall)

- [x] **`aws.wafv2.WebAcl`** — `hairdule-api-waf-staging`:
  - AWSManagedRulesCommonRuleSet (OWASP Top 10, SQLi, XSS, Path Traversal)
  - AWSManagedRulesKnownBadInputsRuleSet
  - RateLimitingRule: máximo 300 requisições por IP / 5 minutos
  - CloudWatch Metrics ativadas (`hairdule-api-waf-metrics-staging`)
  - ARN da WebACL exportado no SSM para a Fase 20 (CloudFront CDN)

---

### 🔀 3. Roteamento de Microsserviços & Bateria de Testes (13/13 PASS)

- [x] **Rotas estritamente tipadas do Auth Service:**
  - `GET /health` -> Lambda Auth Service (Fase 06) — 🟢 **200 OK** (~18ms AWS)
  - `POST /auth/signup` -> Lambda Auth Service (Fase 06) — 🟢 **201 Created** + `Set-Cookie`
  - `POST /auth/login` -> Lambda Auth Service (Fase 06) — 🟢 **200 OK** + `Set-Cookie`
  - `POST /auth/refresh` -> Lambda Auth Service (Fase 06) — 🟢 **200 OK** + `Set-Cookie`
  - `POST /auth/logout` -> Lambda Auth Service (Fase 06) — 🟢 **200 OK** (limpeza de cookies)
  - `GET /auth/me` -> Lambda Auth Service (Fase 06) — 🟢 **200 OK** (dados de sessão)
  - `POST /auth/forgot-password` -> Lambda Auth Service (Fase 06) — 🟢 **200 OK**
  - `POST /auth/change-password` -> Lambda Auth Service (Fase 06) — 🟢 **401 Unauthorized** (sem cookie/Bearer)
  - `OPTIONS /auth/login` -> Interceptado no Edge pelo API GW — 🟢 **204 No Content**
  - `GET /rota-inexistente` -> Rejeitado na Borda pelo API GW — 🟢 **404 Not Found**
- [x] Parâmetros SSM exportados:
  - `/sst/hairdule/staging/api/url` -> `https://nlrx258a8i.execute-api.us-east-1.amazonaws.com`
  - `/sst/hairdule/staging/api/id` -> `nlrx258a8i`
  - `/sst/hairdule/staging/api/authorizer-id` -> `5syzz5`
  - `/sst/hairdule/staging/waf/arn` -> `arn:aws:wafv2:us-east-1:351083991126:regional/webacl/...`

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| API Gateway & Authorizer | 2 | 2 | **100%** 🟩 |
| AWS WAF v2 | 2 | 2 | **100%** 🟩 |
| Roteamento & Otimizações | 2 | 2 | **100%** 🟩 |
| Workflows CI/CD | 2 | 2 | **100%** 🟩 |
| **TOTAL** | **8** | **8** | **100%** 🟩 |

> **Status:** ✅ **Fase 07 Concluída, Otimizada e Homologada em Staging na AWS com Sucesso!**
