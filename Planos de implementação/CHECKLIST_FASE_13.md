# 👥 Fase 13 — Staff Service Lambda (`fase_13_hairdule_staff_service`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_13_hairdule_staff_service`
> **Tecnologia:** Python 3.12 + FastAPI + Mangum | Porta local: `3003`
> **Dependências Diretas:** Fase 05 (hairdule-shared), Fase 06 (API Gateway)
> **Última verificação:** 2026-08-11

---

## 🎯 Objetivo da Fase

A Fase 13 implementa o **CRUD completo de profissionais** com sistema de permissões rigoroso. É o RH do sistema: quem pode criar funcionários, quem pode alterar salários, quem pode demitir.

A regra mais importante: **Barbeiro não pode alterar seu próprio cargo** (para não se auto-promover a dono).

---

## 🔐 Regras de Permissão — A Hierarquia de RH

```
OWNER (Dono)                 BARBER (Barbeiro)
├── Criar profissionais  ✅   ├── Criar profissionais  ❌
├── Remover profissionais✅   ├── Remover profissionais❌
├── Alterar qualquer staff✅  ├── Alterar apenas próprio perfil ✅
├── Alterar role ✅           ├── Alterar role (próprio) ❌ 🔒
├── Alterar active ✅         ├── Alterar active ❌ 🔒
├── Alterar agenda_visibility✅├── Alterar agenda_visibility ❌ 🔒
└── Ver todos os profissionais✅└── Ver todos os profissionais ✅
```

---

## ✅ Checklist Completo da Fase 13

### 🐍 1. Backend — Rotas FastAPI

- [ ] **`GET /staff`** (JWT) — lista com serviços associados:
  - Owner: vê email e phone de todos
  - Barber: vê email/phone apenas do próprio perfil
- [ ] **`POST /staff`** (JWT owner) — cria profissional:
  - Valida `can_add_staff()` — respeita limite do plano de assinatura
  - Campos: `name` (obrig), `email`, `phone`, `role`, `service_ids`, `agenda_visibility`
- [ ] **`PUT /staff`** (JWT) — atualiza profissional:
  - Owner: atualiza qualquer campo de qualquer profissional
  - Barber: atualiza apenas próprio perfil
  - `protect_staff_sensitive_fields()`: bloqueia `role`, `active`, `agenda_visibility` para barbers
- [ ] **`DELETE /staff/{id}`** (JWT owner) — remove profissional (soft delete: `active = false`)
- [ ] **`GET /public/staff`** (público) — staff sem PII (via view `staff_public`)

---

### 🛡️ 2. Proteções Implementadas

- [ ] **`protect_staff_sensitive_fields()`** — Barber NÃO pode alterar:
  - `role` — para não se auto-promover
  - `active` — para não se reativar
  - `agenda_visibility` — para não expandir acesso
  - `barbershop_id` — para não trocar de barbearia
- [ ] **`can_add_staff()`** — verifica `current_staff < max_staff` do plano antes de criar
- [ ] Barber editando staff de outro → 403 `FORBIDDEN`
- [ ] Owner editando staff de outra barbearia → 403

---

### 🧪 3. Testes (pytest)

- [ ] `test_list_staff_as_owner` → vê email/phone de todos
- [ ] `test_list_staff_as_barber` → vê email/phone apenas do próprio
- [ ] `test_create_staff_as_owner` → 201 + staff criado
- [ ] `test_create_staff_as_barber` → 403
- [ ] `test_update_own_profile_as_barber` → 200 (campos não-sensíveis)
- [ ] `test_update_role_as_barber` → campo ignorado / 403
- [ ] `test_delete_staff_as_owner` → 200 + staff desativado
- [ ] `test_delete_staff_as_barber` → 403
- [ ] `test_can_add_staff_plan_limit` → 403 no limite do plano
- [ ] `test_public_staff_no_pii` → sem email, sem phone

---

### ⏳ 4. A Fazer — Pendências

- [ ] Criar repositório `fase_13_hairdule_staff_service`
- [ ] Implementar rotas + proteções
- [ ] Escrever testes
- [ ] Deploy staging

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Rotas FastAPI (5 rotas) | 0 | 5 | **0%** ⬜ |
| Proteções (2 funções) | 0 | 5 | **0%** ⬜ |
| Testes pytest (10 testes) | 0 | 10 | **0%** ⬜ |
| Deploy | 0 | 2 | **0%** ⬜ |
| **TOTAL** | **0** | **22** | **0%** ⬜ |

> **Status:** ⬜ Aguardando Fases 05 e 06 concluídas.
