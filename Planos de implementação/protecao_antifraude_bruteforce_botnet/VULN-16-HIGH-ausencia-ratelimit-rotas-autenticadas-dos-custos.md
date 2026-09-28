# VULN-16 — Ausência de Rate Limit em Rotas Autenticadas (Denial of Wallet & Exaustão de Banco de Dados)

> **Status:** [x] ✅ **Corrigido e Validado em Homologação (PR #47 da fase_05, PR #46 da fase_06 e PR #10 da fase_17)**  
> **Severidade:** 🔶 **ALTA**  
> **CVSS v3.1:** 7.5 (`CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:N/I:N/A:H`)  
> **Repositórios Afetados:** [`fase_05_hairdule_shared`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_05_hairdule_shared) (Middleware Central), [`fase_07_hairdule_infra_api`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api) (API Gateway Throttling Global)  
> **Arquivos Alvo:** `fase_05_hairdule_shared/src/hairdule_shared/middleware/rate_limit.py`, `fase_07_hairdule_infra_api/sst.config.ts`

---

## 1. Descrição da Vulnerabilidade

Enquanto proteções foram aplicadas a rotas públicas, rotas que exigem autenticação (`/appointments`, `/staff`, `/services`, `/metrics`, `/reports`, `/customers`) permaneciam sem teto individual de requisições por usuário ou barbearia.

### Riscos Críticos Identificados:
1. **Denial of Wallet (Explosão de Fatura AWS):**
   - Um usuário legítimo mal-intencionado (ou credencial vazada/roubada) com script automatizado pode efetuar 5.000 requisições por segundo.
   - Cada chamada dispara execuções concorrentes de AWS Lambda e conexões ao pool do Aurora PostgreSQL.
2. **Escalonamento Indesejado de ACUs do Aurora Serverless v2:**
   - Consultas pesadas de agendamentos, relatórios analíticos e listagens de clientes exigem CPU e buffer pool do banco.
   - O Aurora escala suas ACUs (Aurora Capacity Units) para o teto máximo (ex: 16 ou 32 ACUs), multiplicando os custos em dezenas de vezes.
3. **Efeito "Noisy Neighbor" (Degradação Compartilhada):**
   - No modelo multi-tenant, se uma barbearia for alvo de loop infinito ou script abusivo, todo o banco de dados e as quotas de concorrência da conta AWS ficam saturadas, causando lentidão extrema (`504 Gateway Timeout`) para todas as outras barbearias da plataforma.

---

## 2. Cenário de Ataque

```
[ Usuário Autenticado Malicioso / Script em Loop Infinito ]
                       │
                       ▼ (Dispara 2.000 req/s: GET /appointments?start=...&end=...)
           [ API Gateway HTTP API ]
                       │
                       ▼ (Invoca centenas de instâncias concorrentes da Lambda)
          [ Appointment Service Lambda ]
                       │
                       ▼ (Executa dezenas de queries pesadas no PostgreSQL)
           [ Amazon Aurora Serverless v2 ]
        ┌──────────────────────────────────────┐
        │ CPU atinge 98%                       │
        │ Escala de 0.5 ACU para 16 ACUs       │
        │ Fatura AWS explode ($$$)             │
        │ Outros clientes recebem HTTP 504/500 │
        └──────────────────────────────────────┘
```

---

## 3. Solução Técnica Multi-Camadas

### Camada 1: Throttling no Edge via API Gateway (`fase_07`)
- Manter `defaultRouteSettings` restritivo no estágio `$default` do API Gateway HTTP API (`throttlingBurstLimit: 50`, `throttlingRateLimit: 25`).
- Qualquer rajada global acima desse limite é imediatamente cortada no Edge da AWS com `HTTP 429 Too Many Requests`, **sem custo de execução de Lambda e sem tocar no banco de dados**.

### Camada 2: Middleware Universal de Rate Limit no Backend (`fase_05`)
Implementar o `RateLimiterMiddleware` no pacote compartilhado `hairdule_shared`:
- **Chave de Identificação Hierárquica:**
  1. **Por Usuário Autenticado (`user_id` / `sub` do JWT):** Teto padrão de **120 requisições por minuto** (média 2 req/s, tolerância a burst).
  2. **Por Barbearia / Tenant (`barbershop_id`):** Teto padrão de **300 requisições por minuto** agregadas para todas as contas do mesmo estabelecimento.
  3. **Por IP de Origem (rotas públicas sem token):** Teto de **60 requisições por minuto**.
- **Cabeçalhos Padrão de Resposta HTTP:**
  - `Retry-After: <segundos>`
  - `X-RateLimit-Limit: <teto>`
  - `X-RateLimit-Remaining: <restante>`
  - `X-RateLimit-Reset: <timestamp>`
- **Exceções Transparentes:** Rotas de liveness/readiness (`/health`, `/healthz`, `/metrics`, `/docs`) e ambiente de testes unitários automatizados (`ENVIRONMENT=test`).

---

## 4. Checklist de Implementação & Validação

- [x] Implementar `hairdule_shared.middleware.rate_limit.RateLimiterMiddleware` em `fase_05_hairdule_shared`.
- [x] Exportar `RateLimiterMiddleware` em `hairdule_shared.middleware` e `hairdule_shared`.
- [x] Adicionar testes unitários com cobertura para usuários autenticados, tenants e IPs (`test_rate_limiter_middleware.py`).
- [x] Configurar registro do middleware no ciclo de inicialização do FastAPI (`fase_06` e `fase_17`).
- [x] Validar que chamadas acima de 120 req/min para o mesmo usuário autenticado recebem `HTTP 429`.
- [x] Confirmar que o API Gateway rejeita rajadas volumosas no Edge antes do backend.
