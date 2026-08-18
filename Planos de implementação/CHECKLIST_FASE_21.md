# ⏰ Fase 21 — EventBridge Scheduler (`fase_21_hairdule_infra_scheduler`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_21_hairdule_infra_scheduler`
> **Tecnologia:** SST v4 — AWS EventBridge Scheduler + IAM Roles
> **Dependências Diretas:** Fase 07 (API Gateway / Lambdas de backend)
> **Última verificação:** 2026-08-16

---

## 🎯 Objetivo da Fase

A Fase 21 implementa o **agendador automático de tarefas em segundo plano**. É o relógio despertador do Hairdule: dispara lembretes de agendamentos por WhatsApp/Push, verifica assinaturas expiradas e consolida métricas diárias.

---

## ✅ Checklist Completo da Fase 21

### ⏰ 1. EventBridge Schedules & Rules

- [ ] **Lembretes de Agendamentos (15 min antes):** dispara Lambda de Notificação
- [ ] **Cobrança/Verificação de Assinaturas (diário 00:00):** dispara Lambda de Subscriptions
- [ ] **Consolidação de Analytics (diário 01:00):** dispara Lambda de Analytics

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Agendadores EventBridge | 0 | 3 | **0%** ⬜ |
| **TOTAL** | **0** | **3** | **0%** ⬜ |

> **Status:** ⬜ Aguarda conclusão dos microsserviços.
