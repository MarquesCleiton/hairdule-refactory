# 📦 Fase 05 — Pacote Compartilhado (`fase_05_hairdule_shared`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_05_hairdule_shared`
> **Tecnologia:** Python 3.12 Package (Lambda Layer) — SQLAlchemy 2.0, Pydantic v2, FastAPI deps
> **Dependências Diretas:** Fase 04 (schema do banco existe para mapear os models ORM)
> **Última verificação:** 2026-08-11

---

## 🎯 Objetivo da Fase

O `hairdule-shared` é o **DNA compartilhado de todas as Lambdas**. É um pacote Python publicado como **Lambda Layer** na AWS e instalado localmente via `pip install -e ../hairdule-shared`.

Pense assim: em vez de cada Lambda ter sua própria cópia dos modelos ORM, schemas Pydantic e middleware de autenticação (gerando inconsistência e duplicação), **um único pacote centralizado** serve como fonte da verdade para todas as 9 Lambdas.

> **⚠️ Restrição Crítica:** O `hairdule-shared` **APENAS lê e escreve dados (DML)**. Ele **NUNCA altera a estrutura do banco** (DDL). Criar tabelas, índices e constraints é responsabilidade exclusiva da Fase 04.

---

## 🧬 Analogia — O DNA Corporativo Compartilhado

```
┌─────────────────────────────────────────────────────────────┐
│  📦 hairdule-shared (Lambda Layer)                          │
│  "O Manual de Operações Padrão da Empresa"                  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 🗃️  database/models/     "Os Formulários Padrão"     │   │
│  │     Mapeamentos ORM SQLAlchemy de cada tabela.      │   │
│  │     São os "formulários" para ler/gravar dados.     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 📋 schemas/              "Os Contratos de API"       │   │
│  │     Schemas Pydantic v2 que validam requests        │   │
│  │     e formatam responses — a "letra" dos contratos. │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 🛡️  auth/                "O Crachá de Identificação" │   │
│  │     IAuthProvider Protocol + CognitoAdapter         │   │
│  │     + LocalAdapter (dev) + JWT sign/verify          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ⚠️  errors/ + middleware/ "Os Procedimentos de RH"   │   │
│  │     Erros padronizados, CORS, logging, idempotency  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
        │ publicado como
        ▼
  Lambda Layer (ZIP)     ←── todas as 9 Lambdas dependem desta Layer
  + pip install -e .     ←── dev local com hot-reload instantâneo
```

---

## ✅ Checklist Completo da Fase 05

### 🔗 1. Pré-requisitos

- [x] Fase 04 executada — schema do banco criado e seeds aplicados
- [x] `schema.sql` da Fase 04 disponível como referência para os models ORM

---

### 📁 2. Estrutura do Pacote Python

- [x] **`pyproject.toml`** com:
  - `name = "hairdule-shared"`, `version = "0.1.0"`
  - `build-system = setuptools`
  - Deps: `sqlalchemy>=2.0`, `pydantic>=2.0`, `fastapi`, `PyJWT[crypto]`, `bcrypt`, `boto3`, `structlog`, `psycopg[binary]`, `email-validator`
- [x] **`src/hairdule_shared/__init__.py`** com versão e re-exports principais
- [x] **Validação local:** `pip install -e .` executa sem erros

---

### 🗃️ 3. Módulo `database/` — ORM Mappings (DML Only)

- [x] **`database/client.py`** — `create_engine()` factory:
  - Suporte sync e async (`create_async_engine`)
  - Connection pool configurável (`pool_size`, `max_overflow`)
  - `DATABASE_URL` lido de variável de ambiente / Secrets Manager
- [x] **`database/session.py`** — `SessionLocal` e `get_db()` como FastAPI Dependency
- [x] **`database/base.py`** — `DeclarativeBase` para todos os models com `JSON_TYPE` cross-dialect
- [x] **`database/models/domain.py`** — Models das 9 domain tables (read-mostly):
  - `DomainBusinessType`, `DomainBarbershopStatus`, `DomainStaffRole`
  - `DomainAgendaVisibility`, `DomainAppointmentStatus`, `DomainSubscriptionStatus`
  - `DomainBillingCycle`, `DomainBlockType`, `DomainNotificationType`
- [x] **`database/models/barbershop.py`** — Model `Barbershop` (todos os campos do schema)
- [x] **`database/models/user_role.py`** — Model `UserRole`
- [x] **`database/models/staff.py`** — Model `Staff` (com campos PII: email, phone)
- [x] **`database/models/service.py`** — Model `Service` (pausa, variável, buffer)
- [x] **`database/models/staff_service.py`** — Model `StaffService` (N:N)
- [x] **`database/models/business_hours.py`** — Model `BusinessHours` (JSONB breaks)
- [x] **`database/models/staff_hours.py`** — Model `StaffHours`
- [x] **`database/models/appointment.py`** — Model `Appointment` (todos os 30+ campos)
- [x] **`database/models/appointment_audit_log.py`** — Model `AppointmentAuditLog`
- [x] **`database/models/availability_block.py`** — Model `AvailabilityBlock`
- [x] **`database/models/time_off.py`** — Model `TimeOff` (legada)
- [x] **`database/models/customer.py`** — Model `Customer`
- [x] **`database/models/customer_consent.py`** — Model `CustomerConsent`
- [x] **`database/models/consent.py`** — Model `Consent` (LGPD plataforma)
- [x] **`database/models/plan.py`** — Model `Plan`
- [x] **`database/models/subscription.py`** — Model `Subscription`
- [x] **`database/models/notification.py`** — Model `Notification`
- [x] **`database/models/notification_preference.py`** — Model `NotificationPreference`
- [x] **`database/models/push_subscription.py`** — Model `PushSubscription`
- [x] **`database/models/role_permission.py`** — Model `RolePermission`
- [x] **`database/models/internal_admin.py`** — Model `InternalAdmin`
- [x] **`database/models/suggestion_tracking.py`** — Model `SuggestionTracking`
- [x] **`database/models/admin_activity_log.py`** — Model `AdminActivityLog`
- [x] **`database/models/__init__.py`** — re-exporta todos os models

---

### 📋 4. Módulo `schemas/` — Pydantic v2

- [x] **`schemas/auth.py`** — `SignupRequest`, `LoginRequest`, `TokenResponse`, `RefreshRequest`, `ForgotPasswordRequest`, `ResetPasswordRequest`, `ChangePasswordRequest`
- [x] **`schemas/barbershop.py`** — `BarbershopCreate`, `BarbershopUpdate`, `BarbershopResponse`, `OnboardingCompleteRequest`
- [x] **`schemas/staff.py`** — `StaffCreate`, `StaffUpdate`, `StaffResponse`, `StaffPublicResponse`
- [x] **`schemas/service.py`** — `ServiceCreate`, `ServiceUpdate`, `ServiceResponse`
- [x] **`schemas/appointment.py`** — `AppointmentCreate`, `AppointmentUpdate`, `AppointmentResponse`, `PublicBookingRequest`
- [x] **`schemas/availability.py`** — `BusinessHoursCreate`, `StaffHoursCreate`, `AvailabilityBlockCreate`, `AvailabilitySlotResponse`
- [x] **`schemas/subscription.py`** — `SubscriptionCheckResponse`, `SelectPlanRequest`
- [x] **`schemas/notification.py`** — `NotificationResponse`, `NotificationPreferenceUpdate`, `PushSubscriptionCreate`
- [x] **`schemas/common.py`** — `Pagination`, `ErrorResponse`, `SuccessResponse`, `HealthResponse`

---

### 🛡️ 5. Módulo `auth/` — Auth Adapter Pattern

- [x] **`auth/provider.py`** — `IAuthProvider` Protocol:
  - `sign_up(email, password) -> dict`
  - `sign_in(email, password) -> dict`
  - `forgot_password(email) -> None`
  - `reset_password(token, password) -> None`
  - `change_password(access_token, old, new) -> None`
  - `refresh_token(refresh_token) -> dict`
- [x] **`auth/cognito_adapter.py`** — Produção: usa `boto3` cognito-idp
- [x] **`auth/local_adapter.py`** — Dev local: usa `bcrypt` + `PyJWT` auto-assinado
- [x] **`auth/jwt_handler.py`** — Sign/verify JWT Hairdule (claims: `user_id`, `barbershop_id`, `role`, `exp`)
- [x] **`auth/middleware.py`** — FastAPI Dependency `get_current_user` → retorna `CurrentUser`

---

### ⚠️ 6. Módulo `errors/`

- [x] **`errors/app_error.py`** — Classe base `AppError(Exception)` com `status_code`, `code`, `message`
- [x] **`errors/error_handler.py`** — FastAPI `exception_handler` padronizado (retorna JSON consistente)

---

### 🔧 7. Módulos Auxiliares

- [x] **`middleware/cors.py`** — CORS config (dev: `allow_origins=["*"]`, prod: domínios oficiais)
- [x] **`middleware/logger.py`** — Request/response logging com `structlog`
- [x] **`middleware/idempotency.py`** — Handler do header `Idempotency-Key`
- [x] **`types/env.py`** — `Settings` Pydantic (variáveis de ambiente tipadas via `pydantic-settings`)
- [x] **`types/context.py`** — `CurrentUser` dataclass (`user_id`, `barbershop_id`, `role`)
- [x] **`utils/date.py`** — Helpers timezone `America/Sao_Paulo` via `zoneinfo.ZoneInfo`
- [x] **`utils/price.py`** — Conversão centavos ↔ Reais
- [x] **`utils/phone.py`** — Validação/formatação telefone BR (10-11 dígitos)

---

### 🧪 8. Testes

- [x] **`tests/conftest.py`** — Fixtures: DB em memória (SQLite), factories de objetos
- [x] **`tests/test_models.py`** — Criação e leitura de cada model ORM
- [x] **`tests/test_schemas.py`** — Validação Pydantic (campos obrigatórios, formatos)
- [x] **`tests/test_auth.py`** — `LocalAdapter` sign_up + sign_in + JWT verify + Cognito mock
- [x] **`tests/test_utils.py`** — Formatação de preços, telefones, datas

---

### 🚀 9. Deploy como Lambda Layer

- [x] **Script de empacotamento** para Lambda Layer (`scripts/build_layer.py`):
  ```bash
  python scripts/build_layer.py
  ```
- [x] ZIP gerado com todos os módulos e layout `python/hairdule_shared`
- [x] Layer provisionada via SST v3 (`sst.config.ts`) com export de SSM Parameter `/hairdule/{stage}/shared/layer-arn`

---

### ✔️ 10. Validação de Integração

- [x] `pip install -e .` em cada Lambda de desenvolvimento funciona
- [x] `from hairdule_shared.database.models import Barbershop` importa sem erro
- [x] `from hairdule_shared.auth import IAuthProvider` importa sem erro
- [x] `from hairdule_shared.schemas.auth import SignupRequest` importa sem erro
- [x] `pytest tests/` → todos os 14 testes passando com 88% de cobertura

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Pré-requisitos | 2 | 2 | **100%** ✅ |
| Estrutura do Pacote | 3 | 3 | **100%** ✅ |
| Models ORM (29 models) | 29 | 29 | **100%** ✅ |
| Schemas Pydantic (9 arquivos) | 9 | 9 | **100%** ✅ |
| Auth Adapter (5 arquivos) | 5 | 5 | **100%** ✅ |
| Errors + Middleware + Utils | 9 | 9 | **100%** ✅ |
| Testes | 5 | 5 | **100%** ✅ |
| Deploy como Layer | 3 | 3 | **100%** ✅ |
| Validação de Integração | 5 | 5 | **100%** ✅ |
| **TOTAL** | **70** | **70** | **100%** ✅ |

> **Status:** ✅ Fase 05 100% concluída e validada (Testes unitários, Typecheck, Build de Layer e Workflows CI/CD prontos).
