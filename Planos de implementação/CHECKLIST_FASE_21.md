# ⏰ Fase 21 — EventBridge Scheduler (`fase_21_hairdule_infra_scheduler`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_21_hairdule_infra_scheduler`  
> **Tecnologia:** SST v4 — AWS EventBridge Scheduler + IAM Roles  
> **Dependências Diretas:** Fase 24 (Notification Service), Fase 26 (Analytics Service)  
> **Última verificação:** 2026-08-25  
> **Status:** 🟢 **Operacional na AWS Staging (Lembretes + Analytics Ativos)**

---

## 🎯 Objetivo da Fase

A Fase 21 implementa a **infraestrutura de agendamento automático de tarefas em segundo plano**. É o relógio despertador do Hairdule:
- Dispara o processamento contínuo de lembretes de agendamento (Push VAPID / In-App) via Notification Service.
- Executa a consolidação diária de métricas de faturamento, ocupação e sugestões de IA via Analytics Service.
- Fornece suporte desacoplado para a regra de verificação de assinaturas (Fase 22).

---

## 📊 Recursos Implantados na AWS (Homologação / Staging)

- **IAM Role:** `arn:aws:iam::351083991126:role/hairdule-scheduler-role-staging`
- **Schedule Lembretes (Reminders):** `arn:aws:scheduler:us-east-1:351083991126:schedule/default/hairdule-scheduler-reminders-staging`
  - Expressão: `rate(5 minutes)`
  - Destino: `hairdule-notification-service-staging`
- **Schedule Analytics Diário:** `arn:aws:scheduler:us-east-1:351083991126:schedule/default/hairdule-scheduler-analytics-staging`
  - Expressão: `cron(0 1 * * ? *)` (`America/Sao_Paulo`)
  - Destino: `hairdule-analytics-service-staging`

---

## ✅ Checklist Completo da Fase 21

### ⏰ 1. Entrega Inicial — Schedulers Operacionais (Pós-Fases 24 & 26)

- [x] **Lembretes de Agendamentos (a cada 5 minutos):** dispara Lambda de Notificações (`fase_24_hairdule_notification_service`) para envio de Push VAPID / In-App.
- [x] **Consolidação de Analytics (diário 01:00 BRT / 04:00 UTC):** dispara Lambda de Analytics (`fase_26_hairdule_analytics_service`) para consolidar métricas diárias, no-shows e ocupação.
- [x] **IAM Roles & Policies:** Permissão de `lambda:InvokeFunction` estrita e com least-privilege para `scheduler.amazonaws.com`.

---

### 💳 2. Entrega Incremental — Scheduler de Monetização (Pós-Fase 22)

- [ ] **Cobrança / Verificação de Assinaturas (diário 00:00 BRT):** dispara Lambda de Subscriptions (`fase_22_hairdule_subscription_service`) para verificar vencimentos, renovações e status de tolerância (Estrutura configurada, aguardando deploy da Fase 22 para ativação).

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Entrega Inicial (Lembretes & Analytics) | 2 | 2 | **100%** 🟢 |
| Entrega Incremental (Monetização) | 0 | 1 | **0%** ⬜ |
| **TOTAL OPERACIONAL ATUAL** | **2** | **2** | **100%** 🟢 |

> **Status:** 🟢 **Deploy realizado com sucesso na AWS Staging via SST v4 (Run #32914890727)!**
