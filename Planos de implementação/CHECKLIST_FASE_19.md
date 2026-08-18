# 📋 Fase 19 — Appointments Service Lambda (`fase_19_hairdule_appointments_service`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_19_hairdule_appointments_service`
> **Tecnologia:** Python 3.12 + FastAPI + Mangum | Porta local: `3006`
> **Dependências Diretas:** Fase 05 (hairdule-shared), Fase 06 (API Gateway), Fase 17 (motor de disponibilidade)
> **Última verificação:** 2026-08-11

---

## 🎯 Objetivo da Fase

A Fase 19 implementa o **coração operacional do Hairdule** — criação e gestão de agendamentos. Toda a máquina (horários, profissionais, serviços) foi construída para servir esta fase.

É o **cartório de agendamentos**: cada reserva tem um código único (`BKG-XXXXXX`), é registrada com data, hora, profissional, serviço e cliente, e cada mudança de status é auditada.

---

## 📊 Máquina de Estados dos Agendamentos

```
                    AGENDADO
                   /    |    \
                  /     |     \
     CONFIRMADO  /  CANCELADO  \ CANCELAMENTO
     (futuro)   │              │  SOLICITADO
                │              │ (aguarda 24h)
                ▼              │
         EM_ATENDIMENTO    REVERTIDO
                │          (se não confirmado)
          ┌─────┴─────┐
          ▼           ▼
    FINALIZADO      NO_SHOW
    (+ audit log)   (+ audit log)
```

---

## ✅ Checklist Completo da Fase 19

### 🐍 1. Backend — Rotas FastAPI

- [ ] **`GET /appointments`** (JWT) — lista agendamentos da barbearia:
  - Filtros: `date`, `staff_id`, `status`, `date_start`/`date_end`
  - Dados retornados: `appointments_safe` (sem PII do cliente — apenas `customer_display_name`)
  - Barbeiro vê apenas próprios agendamentos
- [ ] **`POST /appointments`** (JWT) — cria agendamento (dashboard, pelo dono/barbeiro):
  - Valida slot disponível via `calculate_available_slots()`
  - Se slot indisponível → 409 `SLOT_NOT_AVAILABLE`
  - Gera `booking_code = "BKG-" + 6_chars_random_alphanumeric`
  - Registra em `appointment_audit_log` (ação: "CREATED")
  - Notifica cliente via `notifications-service` (assíncrono)
- [ ] **`PATCH /appointments/{id}/status`** (JWT) — muda status:
  - Máquina de estados rigorosa (valida transições permitidas)
  - Registra em `appointment_audit_log`
  - Notifica cliente se cancelamento ou confirmação
- [ ] **`GET /appointments/{id}`** (JWT) — detalhes completos
- [ ] **`GET /public/appointments/check`** (público) — status por `booking_code`:
  - Retorna status atual sem PII extra
- [ ] **`POST /public/appointments`** (público) — cria agendamento pelo cliente:
  - Valida slot disponível
  - Cria/recupera `customer` pelo email
  - Gera `booking_code`
  - Cria `customer_consent` (LGPD)
  - Retorna `booking_code` para o cliente

---

### 🔒 2. Proteção de PII — `appointments_safe`

- [ ] Todos os `GET /appointments` retornam apenas `customer_display_name` (ex: "João S.")
- [ ] Nunca retornam email completo, telefone ou CPF do cliente
- [ ] `GET /appointments/{id}` com JWT owner pode retornar dados completos (para contato)
- [ ] Rota pública nunca retorna PII

---

### 📝 3. Audit Log

- [ ] Toda mudança de status registrada em `appointment_audit_log`:
  - `appointment_id`, `changed_by_id`, `from_status`, `to_status`, `reason?`, `timestamp`
- [ ] Criação do agendamento também registrada (from: null, to: AGENDADO)
- [ ] Automação via EventBridge (Fase 08) registra como `system`

---

### 🧪 4. Testes (pytest)

- [ ] `test_create_appointment_valid_slot` → 201 com `booking_code`
- [ ] `test_create_appointment_unavailable_slot` → 409
- [ ] `test_booking_code_format` → começa com "BKG-", 10 chars total
- [ ] `test_booking_code_unique` → dois creates geram códigos diferentes
- [ ] `test_status_transition_valid` → AGENDADO → CONFIRMADO → EM_ATENDIMENTO → FINALIZADO
- [ ] `test_status_transition_invalid` → NO_SHOW → FINALIZADO → 422
- [ ] `test_pii_masking_in_list` → sem email completo, com `customer_display_name`
- [ ] `test_public_booking_creates_customer` → cliente criado automaticamente
- [ ] `test_audit_log_on_status_change` → registro criado
- [ ] `test_barber_sees_own_appointments_only` → filtrado por staff

---

### ⏳ 5. A Fazer — Pendências

- [ ] Criar repositório `fase_19_hairdule_appointments_service`
- [ ] Implementar máquina de estados
- [ ] Implementar geração de `booking_code`
- [ ] Implementar proteção de PII
- [ ] Implementar audit log
- [ ] Escrever todos os testes
- [ ] Deploy staging

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Rotas FastAPI (6 rotas) | 0 | 6 | **0%** ⬜ |
| Máquina de Estados | 0 | 3 | **0%** ⬜ |
| Proteção PII | 0 | 4 | **0%** ⬜ |
| Audit Log | 0 | 3 | **0%** ⬜ |
| Testes pytest (10 testes) | 0 | 10 | **0%** ⬜ |
| Deploy | 0 | 2 | **0%** ⬜ |
| **TOTAL** | **0** | **28** | **0%** ⬜ |

> **Status:** ⬜ Fase crítica — depende do motor de disponibilidade da Fase 17.
