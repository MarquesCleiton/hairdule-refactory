# 🔔 Fase 25 — UI Central de Notificações (Angular 19) (`fase_08_hairdule_ui_web`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_08_hairdule_ui_web` (Pasta: `src/app/features/notifications/`)  
> **Tecnologia:** Angular 19 + Web Push API + SCSS | Porta local: `4300`  
> **Dependências Diretas:** Fase 24 (notification-service em `localhost:3008`)  
> **Regra de Centralização:** Esta fase é desenvolvida diretamente no repositório central `fase_08_hairdule_ui_web`, compartilhando autenticação, layout e design system.  
> **Última verificação:** 2026-08-18

---

## 🎯 Objetivo da Fase

A Fase 25 implementa a **central de notificações in-app** no Web Dashboard SPA e a **inscrição de push notifications (Web Push VAPID)** no navegador.

---

## ✅ Checklist Completo da Fase 25

### 🔔 1. Badge de Notificações na Navbar

- [ ] **`core/notifications/notification.service.ts`**:
  - `unread$: BehaviorSubject<number>` — contagem de não-lidas
  - Polling a cada 30 segundos (`GET /notifications?read=false`)
  - `markAsRead(id)`, `markAllAsRead()`
- [ ] **Badge na navbar** com contagem de não-lidas:
  - `mat-badge` sobre ícone de sino
  - Zera ao abrir o painel
- [ ] **Painel dropdown** ao clicar no sino:
  - Lista das últimas 10 notificações
  - Ícone por tipo (📅 agendamento, ❌ cancelamento, 💳 assinatura)
  - Timestamp relativo ("há 2 minutos")
  - Click → marca como lida + navega para tela relevante

---

### 📋 2. Página Central de Notificações

- [ ] **`features/notifications/notification-center.component.ts`**:
  - Lista completa com paginação infinita
  - Filtro "Todas / Não lidas"
  - Botão "Marcar todas como lidas"
  - Empty state: "Você está em dia! 🎉"

---

### ⚙️ 3. Preferências de Notificação

- [ ] **`features/notifications/preferences.component.ts`**:
  - Tabela de tipos × canais (In-App, Push, Email)
  - Toggles por linha
  - Autosave com debounce

---

### 📲 4. Push Notifications (Service Worker)

- [ ] **Service Worker** gerado pelo Angular (`ng add @angular/pwa`):
  - `SwPush` para gerenciar inscrições
- [ ] **`features/notifications/push-toggle.component.ts`**:
  - Botão "Ativar Notificações do Navegador"
  - Solicita permissão (`Notification.requestPermission()`)
  - Se aprovado → `SwPush.requestSubscription(vapidKey)` → `POST /push/subscribe`
  - Se negado → mostra instrução para habilitar manualmente
  - Estado "Ativado" com botão "Desativar"

---

### 🧪 5. Validação Manual

- [ ] Badge atualiza ao chegar nova notificação (via polling)
- [ ] Click na notificação navega para a tela correta
- [ ] Push notification chega no mobile (navegador fechado)
- [ ] "Marcar todas como lidas" zera o badge
- [ ] Desativar push funciona (subscription removida do banco)
- [ ] Preferências desabilitadas impedem notificação

---

### ⏳ 6. A Fazer — Pendências

- [ ] Implementar NotificationService com polling
- [ ] Implementar badge na navbar
- [ ] Implementar painel dropdown
- [ ] Configurar Service Worker e SwPush
- [ ] Implementar página de preferências
- [ ] Testar push no mobile (Chrome + Firefox)

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Badge + Serviço + Dropdown | 0 | 3 | **0%** ⬜ |
| Página Central | 0 | 1 | **0%** ⬜ |
| Preferências | 0 | 1 | **0%** ⬜ |
| Push / Service Worker | 0 | 2 | **0%** ⬜ |
| Validação Manual | 0 | 6 | **0%** ⬜ |
| **TOTAL** | **0** | **13** | **0%** ⬜ |

> **Status:** ⬜ Aguardando Fase 24 concluída (notifications-service).
