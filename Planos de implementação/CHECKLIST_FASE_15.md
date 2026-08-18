# ✂️ Fase 15 — Services Service Lambda (`fase_15_hairdule_services_service`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_15_hairdule_services_service`
> **Tecnologia:** Python 3.12 + FastAPI + Mangum | Porta local: `3004`
> **Dependências Diretas:** Fase 05 (hairdule-shared), Fase 06 (API Gateway)
> **Última verificação:** 2026-08-11

---

## 🎯 Objetivo da Fase

A Fase 15 gerencia o **catálogo de serviços** da barbearia: cortes, barba, tratamentos — cada um com nome, preço (em centavos), duração, buffer de transição, pausa e visibilidade.

**Regra importante de preços:** Valores são armazenados **sempre em centavos** (R$ 35,00 = `3500`). Nunca float. A conversão é feita na camada de apresentação pelo `price.py` do hairdule-shared.

**Regra de variação:** Serviços podem ter `is_variable_price: true` e `price = null` (preço combinado na hora).

---

## ✅ Checklist Completo da Fase 15

### 🐍 1. Backend — Rotas FastAPI

- [ ] **`GET /services`** (JWT) — lista todos os serviços da barbearia com `display_order`
- [ ] **`POST /services`** (JWT owner) — cria serviço:
  - Campos: `name`*, `duration_minutes`* (min 15, max 480), `price` (em centavos, ou null se variável), `is_variable_price`, `buffer_after` (min), `requires_break`, `active`
  - Valida `can_add_service()` — verifica limite do plano
- [ ] **`PUT /services/{id}`** (JWT owner) — atualiza serviço
- [ ] **`DELETE /services/{id}`** (JWT owner) — desativa (soft delete)
- [ ] **`PATCH /services/reorder`** (JWT owner) — reordena via `display_order`:
  - Recebe lista `[{id, display_order}]`
  - Atualiza em batch em uma transação
- [ ] **`GET /public/services`** (público) — serviços ativos por `barbershop_id`:
  - Apenas `active: true`
  - Preço formatado (centavos → R$) na resposta

---

### 🧮 2. Regras de Negócio — Preços e Duração

- [ ] `price` validado como inteiro não-negativo (centavos)
- [ ] `is_variable_price = true` → `price` pode ser `null`
- [ ] `is_variable_price = false` + `price = null` → 422 `PRICE_REQUIRED`
- [ ] `duration_minutes` validado: 15 ≤ n ≤ 480
- [ ] `buffer_after` validado: 0 ≤ n ≤ 120
- [ ] `requires_break` é separado do `buffer_after` (break do profissional vs limpeza)

---

### 🧪 3. Testes (pytest)

- [ ] `test_create_service_valid` → 201 com preço em centavos
- [ ] `test_create_variable_price` → 201 com `is_variable_price: true, price: null`
- [ ] `test_create_without_price_not_variable` → 422
- [ ] `test_price_stored_as_cents` → `35.00` no input → 422 (deve ser `3500`)
- [ ] `test_duration_too_short` → 422 `DURATION_TOO_SHORT`
- [ ] `test_reorder_services` → `display_order` atualizado corretamente
- [ ] `test_can_add_service_plan_limit` → 403 no limite
- [ ] `test_public_services_filters_inactive` → apenas ativos retornados
- [ ] `test_public_services_formats_price` → preço em R$ no response

---

### ⏳ 4. A Fazer — Pendências

- [ ] Criar repositório `fase_15_hairdule_services_service`
- [ ] Implementar rotas e validações de preço
- [ ] Escrever testes
- [ ] Deploy staging

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Rotas FastAPI (6 rotas) | 0 | 6 | **0%** ⬜ |
| Regras de Preço/Duração | 0 | 6 | **0%** ⬜ |
| Testes pytest (9 testes) | 0 | 9 | **0%** ⬜ |
| Deploy | 0 | 2 | **0%** ⬜ |
| **TOTAL** | **0** | **23** | **0%** ⬜ |

> **Status:** ⬜ Aguardando Fases 05 e 06 concluídas.
