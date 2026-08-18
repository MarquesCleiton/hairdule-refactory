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

### 🧪 4. Testes (pytest)

- [ ] `test_list_plans` → retorna planos com preços em centavos
- [ ] `test_checkout_creates_stripe_session` → mock Stripe, retorna `session_url`
- [ ] `test_webhook_activates_subscription` → `checkout.session.completed` → status `Ativo`
- [ ] `test_webhook_invalid_signature` → 400 (proteção contra webhooks falsos)
- [ ] `test_webhook_idempotent` → mesmo evento duas vezes → sem duplicação
- [ ] `test_subscription_status_reflects_payment` → falha de pagamento → status `Atenção`
- [ ] `test_can_add_staff_free_plan` → bloqueia após limite
- [ ] `test_plan_downgrade_on_cancellation` → volta para Free

---

### ⏳ 5. A Fazer — Pendências

- [ ] Criar repositório `fase_22_hairdule_subscriptions_service`
- [ ] Configurar conta Stripe (sandbox)
- [ ] Implementar integração Stripe SDK
- [ ] Implementar webhook com verificação HMAC
- [ ] Criar planos no painel Stripe (Básico, Profissional, Ilimitado)
- [ ] Escrever todos os testes com mock Stripe
- [ ] Configurar webhook URL no painel Stripe (staging)
- [ ] Deploy staging e testar com `stripe listen --forward-to`

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Rotas FastAPI (5 rotas) | 0 | 5 | **0%** ⬜ |
| Segurança Webhook | 0 | 3 | **0%** ⬜ |
| Controle de Limites | 0 | 4 | **0%** ⬜ |
| Testes pytest (8 testes) | 0 | 8 | **0%** ⬜ |
| Configuração Stripe | 0 | 4 | **0%** ⬜ |
| **TOTAL** | **0** | **24** | **0%** ⬜ |

> **Status:** ⬜ Requer conta Stripe configurada antes do desenvolvimento.
