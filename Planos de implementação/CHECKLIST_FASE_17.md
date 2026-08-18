# 📅 Fase 17 — Availability Service Lambda (`fase_17_hairdule_availability_service`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_17_hairdule_availability_service`
> **Tecnologia:** Python 3.12 + FastAPI + Mangum | Porta local: `3005`
> **Dependências Diretas:** Fase 05 (hairdule-shared), Fase 06 (API Gateway)
> **Última verificação:** 2026-08-11

---

## 🎯 Objetivo da Fase

A Fase 17 é a **mais complexa do sistema** — implementa o motor de disponibilidade que calcula todos os slots de agendamento disponíveis respeitando uma hierarquia rigorosa de 6 camadas de restrições.

É como um **gerente de agenda ultra-preciso** que antes de marcar qualquer horário, consulta: o calendário da semana, as pausas do almoço, a agenda individual do barbeiro, os agendamentos já existentes, os bloqueios manuais e as férias.

---

## 🏗️ A Hierarquia de 6 Camadas de Disponibilidade

```
CAMADA 1: business_hours (horário de funcionamento da barbearia)
    "A barbearia abre de segunda a sábado, das 09:00 às 18:00"
           │ (se fechado no dia → sem slots)
           ▼
CAMADA 2: breaks no business_hours (pausas na agenda da barbearia)
    "Fechado das 12:00 às 13:00 (almoço)"
           │ (remove slots durante a pausa)
           ▼
CAMADA 3: staff_hours (horário individual do profissional)
    "João trabalha só segunda e quarta, das 10:00 às 17:00"
           │ (restringe aos horários do profissional)
           ▼
CAMADA 4: appointments existentes
    "João já tem um corte marcado de 14:00 às 14:30"
    "João já tem uma barba marcada de 15:00 às 15:20 (+ 10min buffer)"
           │ (remove slots ocupados + buffers)
           ▼
CAMADA 5: availability_blocks (bloqueios manuais)
    "João bloqueou 16:00-17:00 para treinamento"
           │ (remove slots bloqueados)
           ▼
CAMADA 6: time_off (férias/ausências prolongadas)
    "João está de férias de 15 a 22 de julho"
    (remove TODOS os slots no período de ausência)
           │
           ▼
    SLOTS DISPONÍVEIS REAIS
```

---

## ✅ Checklist Completo da Fase 17

### 🐍 1. Backend — Rotas FastAPI

#### Horários de Funcionamento
- [ ] **`GET /business-hours`** (JWT) — lista horários da semana (0=dom a 6=sab)
- [ ] **`PUT /business-hours`** (JWT owner) — atualiza horário de um dia:
  - `day_of_week`, `open`, `close`, `is_open` (boolean)
  - `breaks: [{start, end}]` — JSONB no banco
- [ ] **`GET /staff-hours/{staff_id}`** (JWT) — horários específicos do profissional
- [ ] **`PUT /staff-hours/{staff_id}`** (JWT owner) — configura horário do profissional

#### Bloqueios
- [ ] **`GET /availability-blocks`** (JWT) — lista bloqueios por `staff_id` e período
- [ ] **`POST /availability-blocks`** (JWT owner) — cria bloqueio:
  - Tipos: `PONTUAL` (data específica), `RECORRENTE` (dia da semana), `FERIAS` (período)
  - Valida que não há agendamentos no período (409 se houver)
- [ ] **`DELETE /availability-blocks/{id}`** (JWT owner) — remove bloqueio

#### Cálculo de Disponibilidade
- [ ] **`GET /public/availability`** (público) — **Motor Principal**:
  - Parâmetros: `barbershop_id`, `service_id`, `staff_id?`, `date`
  - Calcula slots com intervalo `slot_interval` da barbearia (default 30min)
  - Aplica as 6 camadas em ordem
  - Retorna lista de slots: `[{time: "09:00", available: true, staff_id: 1}]`
  - Retorna apenas slots `available: true`
  - Se `staff_id` não informado → agrupa slots de todos os profissionais
- [ ] **`GET /availability-check`** (JWT) — verifica disponibilidade de slot específico:
  - `staff_id`, `date`, `time`, `service_id`
  - Retorna `{available: bool, conflict_reason?: string}`

---

### 🧮 2. Motor de Cálculo — `calculate_available_slots()`

- [ ] Função `calculate_available_slots(barbershop_id, service_id, staff_id, date)` implementada:
  1. Carrega `business_hours` do dia da semana
  2. Retorna `[]` se `is_open = false`
  3. Gera slots base com `slot_interval`
  4. Remove slots durante `breaks` do `business_hours`
  5. Se `staff_hours` configurado, restringe aos horários do profissional
  6. Carrega `appointments` do dia → remove slots onde `start >= slot AND start < slot + duration`
  7. Aplica `buffer_after` do serviço (aumenta duração efetiva)
  8. Remove slots em `availability_blocks` do dia
  9. Remove TODOS os slots se há `time_off` no dia
  10. Retorna apenas slots onde `slot + duration <= close_time`

---

### 🧪 3. Testes (pytest) — Motor de Disponibilidade

- [ ] `test_slots_when_barbershop_closed` → lista vazia
- [ ] `test_slots_with_break` → slots durante pausa não aparecem
- [ ] `test_slots_with_appointment` → slot ocupado não aparece
- [ ] `test_slots_with_buffer` → slot imediatamente após appointment não aparece se buffer não cabe
- [ ] `test_slots_with_manual_block` → slot bloqueado não aparece
- [ ] `test_slots_with_time_off` → nenhum slot retornado no período de férias
- [ ] `test_all_6_layers_combined` → cenário completo com todas as camadas
- [ ] `test_create_block_with_existing_appointment` → 409 `APPOINTMENTS_IN_PERIOD`
- [ ] `test_availability_check_specific_slot` → `{available: true}`
- [ ] `test_slot_interval_respected` → slots em intervalos corretos (15min, 30min)

---

### ⏳ 4. A Fazer — Pendências

- [ ] Criar repositório `fase_17_hairdule_availability_service`
- [ ] Implementar `calculate_available_slots()` com as 6 camadas
- [ ] Implementar todas as rotas
- [ ] Escrever todos os testes do motor
- [ ] `pytest` → 100% passando
- [ ] Deploy staging

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Rotas FastAPI (8 rotas) | 0 | 8 | **0%** ⬜ |
| Motor de Cálculo (6 camadas) | 0 | 10 | **0%** ⬜ |
| Testes pytest (10 testes) | 0 | 10 | **0%** ⬜ |
| Deploy | 0 | 2 | **0%** ⬜ |
| **TOTAL** | **0** | **30** | **0%** ⬜ |

> **Status:** ⬜ A fase mais complexa do sistema — requer cuidado especial com os testes do motor de disponibilidade.
