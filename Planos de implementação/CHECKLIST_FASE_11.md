# 👥 Fase 11 — Staff Service Lambda (`fase_11_hairdule_staff_service`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_11_hairdule_staff_service`  
> **Organização:** `MarquesCleitonOrg`  
> **Tecnologia:** Python 3.12 + FastAPI + Mangum + SQLAlchemy + Pydantic v2 | Porta local: `3003`  
> **Dependências Diretas:** Fase 01 (VPC), Fase 02 (SG/KMS), Fase 03 (Cognito/JWT), Fase 04 (Aurora PostgreSQL), Fase 05 (hairdule-shared), Fase 07 (API Gateway), Fase 09 (Barbershop Service)  
> **Última atualização:** 2026-08-19 (Marco 3 — 32/32 testes pytest verdes, 90% cobertura)  
> **Status:** 🟩 **CONCLUÍDO COM SUCESSO**

---

## 🎯 Objetivo da Fase

A Fase 11 implementa o **microsserviço de gestão de colaboradores e profissionais (Staff Service)** do Hairdule 2.0. É o departamento de Recursos Humanos do estabelecimento: cuida do cadastro, listagem, atualização de perfis, controle de permissões (Dono vs Barbeiro/Colaborador), horários de trabalho customizados com pausas e vínculo dos serviços que cada profissional executa.

Ela abre o **Marco 3 de Entrega Testável E2E** (Equipe & Catálogo de Serviços).

---

## 🔐 Matriz de Permissões & Proteção de Campos Sensíveis

```
┌──────────────────────────────────────┬─────────────────┬────────────────────┐
│ Ação / Recurso                       │ OWNER / ADMIN   │ BARBER / RECEPT    │
├──────────────────────────────────────┼─────────────────┼────────────────────┤
│ Listar Profissionais (GET /staff)    │ Vê PII de todos │ PII só do próprio  │
│ Obter Profissional (GET /staff/{id}) │ Acesso total    │ PII só do próprio  │
│ Criar Profissional (POST /staff)     │ Permite (201)   │ Bloqueado (403)    │
│ Editar Outro Profissional            │ Permite (200)   │ Bloqueado (403)    │
│ Editar Próprio Perfil (PUT)          │ Permite (200)   │ Campos básicos ✅  │
│ Alterar Cargo (role_code)            │ Permite (200)   │ Bloqueado (403/422)│
│ Alterar Status (is_active)           │ Permite (200)   │ Bloqueado (403/422)│
│ Alterar Visibilidade da Agenda       │ Permite (200)   │ Bloqueado (403/422)│
│ Desativar Profissional (DELETE)      │ Permite (200)   │ Bloqueado (403)    │
│ Gerenciar Horários (GET/PUT hours)   │ Permite (200)   │ Próprio horário ✅ │
│ Listar Staff Público (GET /public)   │ Sem PII         │ Sem PII            │
└──────────────────────────────────────┴─────────────────┴────────────────────┘
```

---

## ✅ Checklist Completo da Fase 11

### 🔗 1. Pré-requisitos
- [x] Fase 05 instalável (`hairdule-shared` com ORM `Staff`, `StaffHours`, `StaffService`, `UserRole`)
- [x] Fase 06 e 09 funcionais (JWT com claims `user_id`, `email`, `barbershop_id`, `role`)
- [x] Tabelas `staff`, `staff_hours`, `staff_services`, `domain_staff_roles`, `domain_agenda_visibilities` prontas no PostgreSQL (Fase 04)

---

### 📁 2. Estrutura do Repositório
- [x] **`pyproject.toml`** configurado com FastAPI, Mangum, SQLAlchemy, Pydantic v2, boto3, structlog e `hairdule_shared`
- [x] **`handler.py`** com Mangum adapter para AWS Lambda
- [x] **`src/app.py`** com CORS, LoggingMiddleware, Exception Handlers e Warmup do DB
- [x] **`config/environments.ts`** com portas, VPC, Secrets e SG da Lambda
- [x] **`sst.config.ts`** com deploy SST v4 (Pulumi nativo) e publicação de parâmetros SSM (`/sst/hairdule/${stage}/staff-service/*`)
- [x] Workflows CI/CD (`feature-validation.yml`, `deploy-staging.yml`, `deploy-production.yml`, `hotfix-pipeline.yml`) com `GH_PAT`

---

### 🐍 3. Backend — Rotas FastAPI (Porta 3003)

- [x] **`GET /staff`** (JWT) — Lista profissionais do estabelecimento:
  - Filtro por `active_only` (default true) e `service_id`
  - OWNER: visualiza e-mail, telefone, cargo e visibilidade de agenda de todos
  - BARBER: visualiza e-mail e telefone apenas do seu próprio perfil (demais mascarados/ocultos)
- [x] **`GET /staff/{id}`** (JWT) — Dados detalhados de um profissional específico
- [x] **`POST /staff`** (JWT OWNER/ADMIN) — Cadastro de profissional:
  - Valida unicidade de e-mail se informado
  - Vincula lista de `service_ids` na tabela `staff_services`
  - Cria 7 registros padrão em `staff_hours` (jornada padrão com pausas)
  - Valida código de cargo e visibilidade
- [x] **`PUT /staff/{id}`** (JWT) — Atualização de profissional:
  - OWNER: atualiza qualquer campo de qualquer membro
  - BARBER: atualiza apenas seu próprio perfil
  - Proteção `protect_staff_sensitive_fields`: bloqueia alteração de `role_code`, `is_active`, `agenda_visibility_code` e `barbershop_id` por não-proprietários
  - Atualiza vínculos de serviços (`staff_services`) se informados
- [x] **`DELETE /staff/{id}`** (JWT OWNER) — Desativação do profissional (Soft delete: `is_active = false`):
  - Trava de segurança: impede que o último OWNER ativo do estabelecimento seja desativado
- [x] **`GET /staff/{id}/hours`** (JWT) — Retorna a jornada de trabalho semanal (7 dias) com pausas (`breaks`)
- [x] **`PUT /staff/{id}/hours`** (JWT OWNER ou próprio Staff) — Atualiza a grade de horários de trabalho semanal e pausas
- [x] **`POST /staff/{id}/avatar`** (JWT OWNER ou próprio Staff) — Atualiza a foto/avatar do colaborador
- [x] **`GET /public/staff`** (Público) — Listagem pública de profissionais por `barbershop_id` ou `slug` (Zero PII — sem e-mail, telefone ou dados sensíveis)

---

### 🧪 4. Testes Automatizados e Documentação de Bateria
- [x] Fixtures em `tests/conftest.py` com SQLite em memória e seeds de domínio
- [x] `tests/test_staff.py` cobrindo fluxos felizes e exceções de autorização (OWNER vs BARBER)
- [x] `tests/test_staff_hours.py` cobrindo atualização e validação de jornadas e pausas
- [x] `tests/test_public.py` garantindo que nenhuma PII vaze no endpoint público
- [x] Pasta `docs/testes_manuais/` com `TESTES_SUCESSO.md` e `TESTES_ERROS.md` (Massas JSON API Gateway v2 Payload 2.0)

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Pré-requisitos | 3 | 3 | **100%** 🟩 |
| Estrutura & CI/CD | 6 | 6 | **100%** 🟩 |
| Rotas FastAPI (9 rotas) | 9 | 9 | **100%** 🟩 |
| Testes Unitários & Manuais | 5 | 5 | **100%** 🟩 |
| **TOTAL** | **23** | **23** | **100%** 🟩 |

> **Status:** 🟩 **Fase 11 Concluída com Sucesso.** 32/32 testes aprovados no pytest (90% de cobertura) e suíte manual pronta.
