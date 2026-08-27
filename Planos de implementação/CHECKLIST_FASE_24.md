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

- [x] **`GET /notifications`** (JWT) — lista notificações da barbearia:
  - Paginação: `?page=1&limit=20`
  - Filtra por `read = false` (não lidas)
  - Ordenadas por `created_at DESC`
- [x] **`PATCH /notifications/{id}/read`** (JWT) — marca como lida
- [x] **`PATCH /notifications/read-all`** (JWT) — marca todas como lidas
- [x] **`GET /notification-preferences`** (JWT) — preferências por tipo:
  - `user_id`, `in_app_enabled`, `push_enabled`, `email_enabled`
- [x] **`PUT /notification-preferences`** (JWT) — atualiza preferências
- [x] **`POST /push/subscribe`** (JWT) — registra subscription de push:
  - Salva `endpoint`, `p256dh`, `auth` (chaves VAPID do browser)
- [x] **`DELETE /push/subscribe`** (JWT) — remove subscription
- [x] **`GET /push/vapid-key`** (público) — retorna `VAPID_PUBLIC_KEY` para o Angular
- [x] **`POST /internal/notify`** (interna, com `X-Internal-Key`) — cria notificação:
  - Chamado por `appointments-service`, `subscriptions-service` etc.
  - Verifica preferências antes de disparar
  - Cria registro em `notifications`
  - Se `push_enabled` e subscription existe → envia push via `pywebpush`

---

### 🔑 2. VAPID Keys (Web Push)

- [x] Chaves VAPID geradas e configuradas com suporte ao Secrets Manager no SST v4
- [x] `VAPID_PRIVATE_KEY` na Lambda (env var de secret)
- [x] `VAPID_PUBLIC_KEY` exposta via `GET /push/vapid-key` (pública)
- [x] `pywebpush` integrado para envio de push com limpeza automática de endpoints expirados (410 Gone)

---

### 🔔 3. Integração com Outros Serviços

- [x] Contrato do endpoint `POST /internal/notify` implementado e pronto para consumo
- [x] Respeito às preferências de usuário por canal (`in_app`, `push`, `email`)
- [x] Schema `SendNotificationPayload` com tipagem estrita via `hairdule-shared`

---

### 🧪 4. Testes (pytest)

- [x] `test_list_notifications` → retorna lista paginada e contadores
- [x] `test_mark_as_read` → `read = true`
- [x] `test_mark_all_read` → todas marcadas
- [x] `test_preferences_disable_push` → push não enviado se `push_enabled = false`
- [x] `test_register_push_subscription` → subscription salva
- [x] `test_internal_notify_creates_record` → registro em `notifications`
- [x] `test_internal_notify_respects_preferences` → não envia se desabilitado
- [x] `test_push_send_mock` → `pywebpush` chamado com payload correto
- [x] `test_push_stale_subscription_cleaned` → auto-limpeza de 410 Gone
- [x] 27/27 testes pytest verdes com 97% de cobertura de código

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Rotas FastAPI (9 rotas) | 9 | 9 | **100%** ✅ |
| VAPID / Push (RFC 8292) | 4 | 4 | **100%** ✅ |
| Integração com outros serviços | 3 | 3 | **100%** ✅ |
| Testes pytest (27 testes) | 27 | 27 | **100%** ✅ |
| **TOTAL** | **43** | **43** | **100%** ✅ |

> **Status:** 🚀 **100% CONCLUÍDO** (27/27 testes pytest verdes, 97% de cobertura, SST v4 validado com 0 erros de tipagem).
