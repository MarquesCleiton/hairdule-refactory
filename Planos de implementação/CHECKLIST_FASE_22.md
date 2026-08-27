# 💳 Fase 22 — Subscriptions Service Lambda (`fase_22_hairdule_subscriptions_service`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_22_hairdule_subscriptions_service`
> **Tecnologia:** Python 3.12 + FastAPI + Mangum + Stripe SDK | Porta local: `3007`
> **Dependências Diretas:** Fase 05 (hairdule-shared), Fase 06 (API Gateway)
> **Última verificação:** 2026-08-11

---

## 🎯 Objetivo da Fase

A Fase 22 implementa o **motor de monetização do Hairdule**. É onde os planos de assinatura são configurados, o checkout é iniciado via Stripe, e os webhooks da Stripe atualizam o status da assinatura em tempo real.

É como a **tesouraria + cobrança** da empresa: gerencia todos os planos, recebe os pagamentos, emite as notas e bloqueia acesso quando o boleto vence.

---

## 💳 Fluxo de Assinatura

```
BARBERSHOP cria conta (Trial 14 dias)
        │
        │ [Selecionar Plano]
        ▼
GET /plans → lista planos disponíveis
        │
        │ [Assinar Plano Mensal Básico]
        ▼
POST /subscription/checkout → Stripe Checkout Session
        │
        ▼
REDIRECT → Stripe Checkout (página segura da Stripe)
        │
        │ Pagamento aprovado
        ▼
STRIPE WEBHOOK → POST /stripe/webhook
        │    • checkout.session.completed
        │    • invoice.payment_succeeded
        │    • invoice.payment_failed
        │    • customer.subscription.deleted
        ▼
UPDATE subscriptions SET status = 'Ativo', plan_id = X
```

---

## ✅ Checklist Completo da Fase 22

### 🐍 1. Backend — Rotas FastAPI

- [ ] **`GET /plans`** (público) — lista planos com features e limites:
  - `name`, `price_monthly` (centavos), `price_annual` (centavos)
  - `max_staff`, `max_services`, `features` (JSON array)
  - `is_highlighted` (plano recomendado)
- [ ] **`GET /subscription`** (JWT) — status atual da assinatura:
  - `status`, `plan`, `trial_ends_at`, `renewal_date`, `payment_method` (últimos 4 dígitos)
- [ ] **`POST /subscription/checkout`** (JWT owner) — inicia Stripe Checkout:
  - Cria `stripe.checkout.sessions.create()`
  - Retorna `{session_url}` para redirect
  - Parâmetros: `plan_id`, `billing_cycle` (mensal/anual)
- [ ] **`POST /subscription/portal`** (JWT owner) — acesso ao portal Stripe:
  - `stripe.billing_portal.sessions.create()` → URL do portal
  - Cliente gerencia cartão, cancela, baixa notas
- [ ] **`POST /stripe/webhook`** (sem JWT, usa `Stripe-Signature`):
  - Verifica assinatura HMAC com `stripe.webhook_secret`
  - Processa eventos:
    - `checkout.session.completed` → ativa assinatura
    - `invoice.payment_succeeded` → renova
    - `invoice.payment_failed` → alerta, bloqueia após 3 falhas
    - `customer.subscription.deleted` → cancela + downgrade para Free

---

### 🔐 2. Segurança do Webhook

- [ ] **Verificação de assinatura Stripe** obrigatória:
  ```python
  stripe.Webhook.construct_event(payload, sig_header, webhook_secret)
  ```
- [ ] **Idempotência via `Idempotency-Key`**: mesmo evento processado duas vezes → sem efeito
- [ ] **Tolerância a falhas**: erro no processamento → retorna 500 para Stripe retentar

---

### 📊 3. Controle de Limites do Plano

- [ ] **`can_add_staff(barbershop_id)`** — verifica `current_staff < plan.max_staff`
- [ ] **`can_add_service(barbershop_id)`** — verifica `current_services < plan.max_services`
- [ ] **`check_subscription_active(barbershop_id)`** — bloqueia operações se status `BLOQUEADO`
- [ ] Funções disponíveis via `hairdule-shared` para uso em outras Lambdas

---

### ⏰ 4. Automação Diária — Integração Imediata com a Fase 21

> [!IMPORTANT]
> **Regra Obrigatória de Conclusão da Fase 22:**  
> Logo após finalizar e homologar o microsserviço de Subscriptions, DEVE-SE implementar imediatamente no repositório `fase_21_hairdule_infra_scheduler` a regra cron de **Cobrança / Verificação de Assinaturas (diário às 00:00 BRT)**, conectando-a à Lambda da Fase 22.

- [ ] **Rota / Handler de Rotina Diária (`POST /internal/check-expirations` ou Direct Invocation):**
  - Identifica assinaturas com trial expirado sem plano ativo (status `EXPIRADO` / `BLOQUEADO`)
  - Identifica faturas com tentativas de cobrança falhadas (status `ATENCAO` ou bloqueio após período de tolerância de 3 dias)
  - Dispara notificação de aviso de vencimento / falha de pagamento via `fase_24_hairdule_notification_service`
- [ ] **Regra EventBridge Scheduler (`fase_21_hairdule_infra_scheduler`):**
  - Cron: `cron(0 3 * * ? *)` (00:00 UTC-3 / Horário de Brasília)
  - Target: Lambda `fase_22_hairdule_subscriptions_service` com permissão IAM mínima

---

### 🧪 5. Testes (pytest)

- [ ] `test_list_plans` → retorna planos com preços em centavos
- [ ] `test_checkout_creates_stripe_session` → mock Stripe, retorna `session_url`
- [ ] `test_webhook_activates_subscription` → `checkout.session.completed` → status `Ativo`
- [ ] `test_webhook_invalid_signature` → 400 (proteção contra webhooks falsos)
- [ ] `test_webhook_idempotent` → mesmo evento duas vezes → sem duplicação
- [ ] `test_subscription_status_reflects_payment` → falha de pagamento → status `Atenção`
- [ ] `test_can_add_staff_free_plan` → bloqueia após limite
- [ ] `test_plan_downgrade_on_cancellation` → volta para Free
- [ ] `test_daily_expiration_check` → rotina diária atualiza status de trials vencidos e alerta inadimplentes

---

### ⏳ 6. A Fazer — Pendências

- [ ] Criar repositório `fase_22_hairdule_subscriptions_service`
- [ ] Configurar conta Stripe (sandbox)
- [ ] Implementar integração Stripe SDK
- [ ] Implementar webhook com verificação HMAC
- [ ] Implementar rota/handler de rotina diária (`POST /internal/check-expirations`)
- [ ] Criar planos no painel Stripe (Básico, Profissional, Ilimitado)
- [ ] Escrever todos os testes com mock Stripe
- [ ] Configurar webhook URL no painel Stripe (staging)
- [ ] Deploy staging e testar com `stripe listen --forward-to`
- [ ] **Implementar no `fase_21_hairdule_infra_scheduler` a regra diária 00:00 BRT apontando para esta Lambda**

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Rotas FastAPI (5 rotas) | 0 | 5 | **0%** ⬜ |
| Segurança Webhook | 0 | 3 | **0%** ⬜ |
| Controle de Limites | 0 | 4 | **0%** ⬜ |
| Automação Diária EventBridge (Fase 21) | 0 | 2 | **0%** ⬜ |
| Testes pytest (9 testes) | 0 | 9 | **0%** ⬜ |
| Configuração Stripe & Deploy | 0 | 5 | **0%** ⬜ |
| **TOTAL** | **0** | **28** | **0%** ⬜ |

> **Status:** ⬜ Requer conta Stripe configurada antes do desenvolvimento. A amarração com `fase_21_hairdule_infra_scheduler` para a rotina diária às 00:00 BRT é executada logo após a finalização do serviço.
