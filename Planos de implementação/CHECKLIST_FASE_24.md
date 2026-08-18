# 🔔 Fase 24 — Notifications Service Lambda (`fase_24_hairdule_notifications_service`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_24_hairdule_notifications_service`
> **Tecnologia:** Python 3.12 + FastAPI + Mangum + Web Push VAPID | Porta local: `3008`
> **Dependências Diretas:** Fase 05 (hairdule-shared), Fase 06 (API Gateway)
> **Última verificação:** 2026-08-11

---

## 🎯 Objetivo da Fase

A Fase 24 implementa o **sistema de notificações in-app e push notifications** do Hairdule. É a "central de comunicações" do sistema — envia alertas tanto dentro do próprio dashboard quanto diretamente no celular do usuário, mesmo quando o navegador está fechado.

---

## 📢 Tipos de Notificação

```
┌─────────────────────────────────────────────────────────┐
│  NOTIFICAÇÕES IN-APP (badge na navbar do dashboard)     │
│                                                         │
│  🔔 João S. agendou Corte Clássico para 10/03 às 14:00 │
│  📅 Lembrete: você tem 3 atendimentos amanhã           │
│  ❌ Carlos cancelou o agendamento das 16:00            │
│  ⚙️  Sua assinatura vence em 3 dias                    │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  PUSH NOTIFICATIONS (chegam no celular / navegador)     │
│                                                         │
│  [Hairdule] 🔔 Novo agendamento para amanhã!           │
│  Corte às 14:00 com João — toque para ver              │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ Checklist Completo da Fase 24

### 🐍 1. Backend — Rotas FastAPI

- [ ] **`GET /notifications`** (JWT) — lista notificações da barbearia:
  - Paginação: `?page=1&limit=20`
  - Filtra por `read = false` (não lidas)
  - Ordenadas por `created_at DESC`
- [ ] **`PATCH /notifications/{id}/read`** (JWT) — marca como lida
- [ ] **`PATCH /notifications/read-all`** (JWT) — marca todas como lidas
- [ ] **`GET /notification-preferences`** (JWT) — preferências por tipo:
  - `notification_type_id`, `in_app_enabled`, `push_enabled`, `email_enabled`
- [ ] **`PUT /notification-preferences`** (JWT) — atualiza preferências
- [ ] **`POST /push/subscribe`** (JWT) — registra subscription de push:
  - Salva `endpoint`, `p256dh`, `auth` (chaves VAPID do browser)
- [ ] **`DELETE /push/subscribe`** (JWT) — remove subscription
- [ ] **`GET /push/vapid-key`** (público) — retorna `VAPID_PUBLIC_KEY` para o Angular
- [ ] **`POST /internal/notify`** (interna, sem JWT externo) — cria notificação:
  - Chamado por `appointments-service`, `subscriptions-service` etc.
  - Verifica preferências antes de disparar
  - Cria registro em `notifications`
  - Se `push_enabled` e subscription existe → envia push via `pywebpush`

---

### 🔑 2. VAPID Keys (Web Push)

- [ ] Chaves VAPID geradas e armazenadas no Secrets Manager (Fase 03)
- [ ] `VAPID_PRIVATE_KEY` na Lambda (env var de secret)
- [ ] `VAPID_PUBLIC_KEY` exposta via `GET /push/vapid-key` (pública)
- [ ] `pywebpush` integrado para envio de push

---

### 🔔 3. Integração com Outros Serviços

- [ ] `appointments-service` (Fase 19) chama `POST /internal/notify` ao:
  - Criar agendamento (tipo: `NOVO_AGENDAMENTO`)
  - Cancelar agendamento (tipo: `CANCELAMENTO`)
  - Enviar lembrete (tipo: `LEMBRETE`, via EventBridge Fase 08)
- [ ] `subscriptions-service` (Fase 22) chama ao vencimento próximo (tipo: `SISTEMA`)

---

### 🧪 4. Testes (pytest)

- [ ] `test_list_notifications` → retorna lista paginada
- [ ] `test_mark_as_read` → `read = true`
- [ ] `test_mark_all_read` → todas marcadas
- [ ] `test_preferences_disable_push` → push não enviado se `push_enabled = false`
- [ ] `test_register_push_subscription` → subscription salva
- [ ] `test_internal_notify_creates_record` → registro em `notifications`
- [ ] `test_internal_notify_respects_preferences` → não envia se desabilitado
- [ ] `test_push_send_mock` → `pywebpush` chamado com payload correto

---

### ⏳ 5. A Fazer — Pendências

- [ ] Criar repositório `fase_24_hairdule_notifications_service`
- [ ] Configurar VAPID keys e armazenar no Secrets Manager
- [ ] Implementar todas as rotas
- [ ] Integrar `pywebpush`
- [ ] Escrever todos os testes
- [ ] Deploy staging

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Rotas FastAPI (9 rotas) | 0 | 9 | **0%** ⬜ |
| VAPID / Push | 0 | 4 | **0%** ⬜ |
| Integração com outros serviços | 0 | 3 | **0%** ⬜ |
| Testes pytest (8 testes) | 0 | 8 | **0%** ⬜ |
| **TOTAL** | **0** | **24** | **0%** ⬜ |

> **Status:** ⬜ Aguardando Fases 05 e 06. Integração com Fases 19 e 22 após deploy.
