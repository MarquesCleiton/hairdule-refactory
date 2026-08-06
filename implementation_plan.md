# Hairdule 2.0 — Plano de Implementação Completo

> **Projeto:** Hairdule — SaaS de agendamentos online para estabelecimentos de beleza  
> **Arquitetura:** AWS Serverless (Lambda + Aurora + CloudFront + Cognito)  
> **Stack:** Angular 18 · FastAPI · SQLAlchemy 2.0 · SST v4 · PostgreSQL 16  
> **Última atualização:** 2026-08-04  
> **Diretório de Destino:** `d:\Documentos\Projetos\Hairdule\Hairdule 2.0\Projeto novo`  
> **Regra de Execução:** Nenhuma caixa de seleção (`- [ ]`) deve ser marcada (`- [x]`) sem a aprovação prévia e explícita do usuário para cada ponto concluído.

---

## Índice

1. [Visão Geral da Arquitetura](#1-visão-geral-da-arquitetura)
2. [Stack Tecnológica Definitiva](#2-stack-tecnológica-definitiva)
3. [Estratégia de Desenvolvimento Local-First](#3-estratégia-de-desenvolvimento-local-first)
4. [Estrutura de Repositórios](#4-estrutura-de-repositórios)
5. [Fase 0 — Setup do Ambiente](#fase-0--setup-do-ambiente-de-desenvolvimento)
6. [Fase 1 — Auth Service + Cadastro](#fase-1--auth-service--cadastro-signup)
7. [Fase 2 — Barbershop + Onboarding](#fase-2--barbershop-service--onboarding)
8. [Fase 3 — Staff & Services](#fase-3--staff--services-management)
9. [Fase 4 — Availability & Business Hours](#fase-4--availability--business-hours)
10. [Fase 5 — Appointments (Staff)](#fase-5--appointments-agendamentos-pelo-staff)
11. [Fase 6 — Portal Público (Booking)](#fase-6--portal-público-booking-online)
12. [Fase 7 — Subscriptions & Stripe](#fase-7--subscriptions--stripe)
13. [Fase 8 — Notifications & Push](#fase-8--notifications--push)
14. [Fase 9 — Analytics & AI](#fase-9--analytics--ai)
15. [Fase 10 — Segurança, WAF & Hardening](#fase-10--segurança-waf--hardening)
16. [Mapa de Dependências](#mapa-de-dependências-entre-fases)
17. [Mitigação de Riscos & Proteção Financeira](#mitigação-de-riscos--proteção-financeira)
18. [Progresso Geral](#progresso-geral)

---

## 1. Visão Geral da Arquitetura

```
              +-------------------------------------------------------+
              |                    CLIENT BROWSER                      |
              +---------------------------+---------------------------+
                                          |
                                  [ CloudFront CDN ]
                                          |
              +---------------------------+---------------------------+
              |        Angular Portal     |      Angular Dashboard    |
              |    (hairdule.com.br)       |    (app.hairdule.com.br)  |
              +---------------------------+---------------------------+
                                          |
                                  [ AWS WAF ] (Rate limit, Anti-Bot, Geo-IP)
                                          |
                                [ API Gateway ] (CORS, Throttling, JWT Auth)
                                          |
                   +----------------------+----------------------+
                   |                      |                      |
        [ auth-service ]      [ barbershop-service ]    [ appointments-service ]
        [ staff-service ]     [ services-service ]      [ availability-service ]
        [ subscriptions ]     [ notifications ]         [ analytics-service ]
         (Python 3.12)          (Python 3.12)             (Python 3.12)
                   |                      |                      |
                   +----------------------+----------------------+
                                          |
                            [ Aurora Serverless v2 ] (PostgreSQL 16)
                              (MinACU 0.5 / MaxACU 4.0)
```

Cada Lambda é um **microsserviço independente** com seu próprio repositório, deploy, e pipeline CI/CD. Todas compartilham o mesmo banco de dados Aurora e uma **Lambda Layer** Python (`hairdule-shared`) com models SQLAlchemy, tipos Pydantic e utilitários comuns.

---

## 2. Stack Tecnológica Definitiva

| Camada | Tecnologia | Justificativa |
|---|---|---|
| **Frontend Framework** | Angular 18+ | Tipagem forte, dependency injection, standalone components |
| **UI Library** | Angular Material | Oficial, design system Google, bem integrado |
| **Backend Runtime** | AWS Lambda (Python 3.12) | Serverless, pay-per-use, auto-scaling, ecossistema Python maduro |
| **HTTP Framework** | FastAPI + Mangum | Async nativo, docs Swagger automáticas, Pydantic integrado, Mangum adapta ASGI→Lambda |
| **ORM** | SQLAlchemy 2.0 | Type-safe, async support, maduro, excelente para PostgreSQL |
| **Validação** | Pydantic v2 | Integrado ao FastAPI, alta performance (core em Rust), validação declarativa |
| **Banco de Dados** | Aurora Serverless v2 (PostgreSQL 16) | Escala automática, teto financeiro controlável |
| **Migrações** | Alembic | Padrão com SQLAlchemy, autogenerate, versionamento incremental |
| **Autenticação** | AWS Cognito (via adapter pattern) | 50k MAU grátis, integração WAF nativa |
| **IaC** | SST v4 (Serverless Stack) | TypeScript nativo, `sst dev` hot-reload, deploy integrado |
| **CDN** | CloudFront | Cache global, SSL/TLS via ACM, custo quase zero |
| **CI/CD** | GitHub Actions | Integração nativa com GitHub, workflows paralelos |
| **Testes Backend** | pytest | Padrão da indústria Python, extensível com plugins, fixtures poderosas |
| **Linting/Typing** | Ruff + mypy | Ruff é ultra-rápido (Rust), mypy valida tipagem estática |
| **Testes E2E** | Playwright | Multi-browser, auto-wait, trace viewer |
| **Repositórios** | Multi-repo (GitHub) | 1 repo por Lambda, 1 por frontend, 1 shared (Layer), 1 infra |

---

## 3. Estratégia de Desenvolvimento Local-First

> **Filosofia:** Cada funcionalidade é construída e validada localmente **antes** de qualquer deploy na AWS. Serviços AWS que não podem rodar local são **virtualizados** com stubs/mocks.

### Ciclo de Desenvolvimento por Feature

```
┌─────────────────────────────────────────────────────┐
│  1. BANCO DE DADOS                                  │
│     Criar migrações Alembic → rodar no PostgreSQL   │
│     local (Docker) → popular com dados de seed      │
├─────────────────────────────────────────────────────┤
│  2. LAMBDA BACKEND (Python)                         │
│     Implementar rotas FastAPI → testar com pytest   │
│     → rodar localmente via `uvicorn` (hot-reload)   │
├─────────────────────────────────────────────────────┤
│  3. FRONTEND ANGULAR                                │
│     Criar componentes → integrar com API local      │
│     → validar fluxo completo no browser             │
├─────────────────────────────────────────────────────┤
│  4. TESTES LOCAIS                                   │
│     Unit tests (pytest) + E2E (Playwright)          │
│     + teste manual de fluxo completo                │
├─────────────────────────────────────────────────────┤
│  5. DEPLOY AWS (somente após aprovação local)       │
│     CI/CD via GitHub Actions → staging → produção   │
└─────────────────────────────────────────────────────┘
```

### Virtualização de Serviços AWS

| Serviço AWS | Emulação Local | Detalhes |
|---|---|---|
| **Aurora Serverless** | PostgreSQL 16 (Docker) | Mesma versão, mesmas migrações, dados de seed |
| **Cognito** | LocalStack + Auth Adapter | `IAuthProvider` com `CognitoAdapter` (prod) e `LocalAdapter` (dev) |
| **API Gateway** | Uvicorn local | Cada Lambda roda em sua porta com hot-reload |
| **S3** | LocalStack | Upload de fotos via mesmo SDK (boto3) |
| **Secrets Manager** | LocalStack + `.env.local` | Variáveis de ambiente em dev, Secrets Manager em prod |
| **Stripe** | Stripe CLI (modo teste) | `stripe listen --forward-to localhost:3001/stripe/webhook` |
| **Lambda Layer** | `pip install -e ../hairdule-shared` | Editable install — mudanças refletem instantaneamente |
| **WAF / CloudFront** | ❌ Não emulável | Testado apenas em staging; headers validados via unit tests |

### Docker Compose — Infraestrutura Local

```yaml
# docker-compose.yml (raiz do workspace)
services:
  postgres:
    image: postgres:16-alpine
    container_name: hairdule-postgres
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: hairdule
      POSTGRES_USER: hairdule_dev
      POSTGRES_PASSWORD: dev_password_123
      TZ: America/Sao_Paulo
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U hairdule_dev -d hairdule"]
      interval: 5s
      timeout: 3s
      retries: 5

  localstack:
    image: localstack/localstack:latest
    container_name: hairdule-localstack
    restart: unless-stopped
    ports:
      - "4566:4566"
    environment:
      SERVICES: cognito-idp,s3,secretsmanager
      DEFAULT_REGION: sa-east-1
      DEBUG: 0
    volumes:
      - localstack_data:/var/lib/localstack
      - /var/run/docker.sock:/var/run/docker.sock

volumes:
  pgdata:
  localstack_data:
```

**Validação:**
```bash
docker compose up -d
docker exec hairdule-postgres pg_isready -U hairdule_dev    # PostgreSQL OK
curl http://localhost:4566/_localstack/health                # LocalStack OK
```

### Ferramentas Necessárias

| Ferramenta | Versão | Propósito |
|---|---|---|
| **Python** | 3.12 | Runtime das Lambdas |
| **Node.js** | 22 LTS | SST v4 (IaC) + Angular CLI |
| **Docker Desktop** | Latest | PostgreSQL + LocalStack |
| **Angular CLI** | 18+ | Frontends |
| **SST CLI** | 4.x | IaC + deploy + dev local |
| **Stripe CLI** | Latest | Webhooks locais |
| **Git** | Latest | Versionamento |
| **uv** | Latest | Gerenciador de pacotes Python ultra-rápido (substitui pip/venv) |

---

## 4. Estrutura de Repositórios

Cada componente do sistema é um **repositório independente** no GitHub. As Lambdas compartilham código via a **Lambda Layer** `hairdule-shared`.

### Mapa de Repositórios

| # | Repositório | Tipo | Porta Local | Descrição |
|---|---|---|---|---|
| 1 | `hairdule-shared` | Lambda Layer (Python) | — | Models SQLAlchemy, schemas Pydantic, auth middleware, utils |
| 2 | `hairdule-infra` | IaC (SST) | — | Infraestrutura AWS (Aurora, Cognito, API GW, S3, CloudFront) |
| 3 | `hairdule-auth-service` | Lambda (Python) | 3001 | Signup, Login, Password, Refresh |
| 4 | `hairdule-barbershop-service` | Lambda (Python) | 3002 | Dados da barbearia, Onboarding |
| 5 | `hairdule-staff-service` | Lambda (Python) | 3003 | CRUD de profissionais |
| 6 | `hairdule-services-service` | Lambda (Python) | 3004 | CRUD de serviços |
| 7 | `hairdule-availability-service` | Lambda (Python) | 3005 | Horários, bloqueios, cálculo de slots |
| 8 | `hairdule-appointments-service` | Lambda (Python) | 3006 | Agendamentos, auditoria, máquina de estados |
| 9 | `hairdule-subscriptions-service` | Lambda (Python) | 3007 | Planos, Stripe, controle de escrita |
| 10 | `hairdule-notifications-service` | Lambda (Python) | 3008 | In-app, push VAPID, preferências |
| 11 | `hairdule-analytics-service` | Lambda (Python) | 3009 | Métricas, relatórios, AI insights |
| 12 | `hairdule-app-dashboard` | Frontend | 4300 | Angular — Painel de gestão |
| 13 | `hairdule-app` | Frontend | 4200 | Angular — Portal público de agendamento |

---

### 4.1 `hairdule-shared` — Lambda Layer (Pacote Python Compartilhado)

Publicado como **Lambda Layer** na AWS e consumido localmente via `pip install -e ../hairdule-shared`. Contém todos os models, schemas, middleware e utilitários compartilhados entre as Lambdas.

```
hairdule-shared/
├── pyproject.toml               # name = "hairdule-shared", build-system = setuptools
├── README.md
│
├── src/
│   └── hairdule_shared/
│       ├── __init__.py          # Versão e re-exports
│       │
│       ├── database/
│       │   ├── __init__.py
│       │   ├── client.py        # SQLAlchemy engine factory (sync/async, connection pool)
│       │   ├── session.py       # SessionLocal, get_db dependency (FastAPI Depends)
│       │   ├── base.py          # DeclarativeBase para todos os models
│       │   ├── models/
│       │   │   ├── __init__.py  # Re-exporta todos os models
│       │   │   ├── enums.py     # business_type, barbershop_status, appointment_status, etc.
│       │   │   ├── barbershop.py
│       │   │   ├── user_role.py
│       │   │   ├── staff.py
│       │   │   ├── service.py
│       │   │   ├── staff_service.py
│       │   │   ├── business_hours.py
│       │   │   ├── staff_hours.py
│       │   │   ├── appointment.py
│       │   │   ├── appointment_audit_log.py
│       │   │   ├── availability_block.py
│       │   │   ├── time_off.py
│       │   │   ├── customer.py
│       │   │   ├── customer_consent.py
│       │   │   ├── consent.py
│       │   │   ├── plan.py
│       │   │   ├── subscription.py
│       │   │   ├── notification.py
│       │   │   ├── notification_preference.py
│       │   │   ├── push_subscription.py
│       │   │   ├── role_permission.py
│       │   │   ├── internal_admin.py
│       │   │   ├── suggestion_tracking.py
│       │   │   └── admin_activity_log.py
│       │   └── views.py         # appointments_safe, staff_public, plans_public
│       │
│       ├── schemas/             # Pydantic v2 schemas (request/response)
│       │   ├── __init__.py
│       │   ├── auth.py          # SignupRequest, LoginRequest, TokenResponse, etc.
│       │   ├── barbershop.py    # BarbershopCreate, BarbershopUpdate, BarbershopResponse
│       │   ├── staff.py
│       │   ├── service.py
│       │   ├── appointment.py
│       │   ├── availability.py
│       │   ├── subscription.py
│       │   ├── notification.py
│       │   └── common.py        # Pagination, ErrorResponse, SuccessResponse
│       │
│       ├── auth/
│       │   ├── __init__.py
│       │   ├── provider.py      # IAuthProvider (Protocol class)
│       │   ├── cognito_adapter.py   # Produção — boto3 cognito-idp
│       │   ├── local_adapter.py     # Dev — passlib/bcrypt + PyJWT auto-assinado
│       │   ├── jwt_handler.py       # Sign/verify JWT próprio do Hairdule (PyJWT)
│       │   └── middleware.py        # FastAPI dependency de auth (valida JWT, injeta user_id/role)
│       │
│       ├── errors/
│       │   ├── __init__.py
│       │   ├── app_error.py     # Classe base (status_code, code, message)
│       │   └── error_handler.py # FastAPI exception_handler padronizado
│       │
│       ├── middleware/
│       │   ├── __init__.py
│       │   ├── cors.py          # CORS config (dev vs prod)
│       │   ├── logger.py        # Request/response logging (structlog)
│       │   └── idempotency.py   # Idempotency-Key handler
│       │
│       ├── types/
│       │   ├── __init__.py
│       │   ├── env.py           # Pydantic Settings (variáveis de ambiente tipadas)
│       │   └── context.py       # CurrentUser dataclass (user_id, barbershop_id, role)
│       │
│       └── utils/
│           ├── __init__.py
│           ├── date.py          # Helpers timezone America/Sao_Paulo (zoneinfo)
│           ├── price.py         # Centavos ↔ Reais
│           └── phone.py         # Validação/formatação telefone BR
│
├── alembic/                     # Migrações geradas pelo Alembic
│   ├── alembic.ini
│   ├── env.py                   # Configuração Alembic (usa models do hairdule_shared)
│   ├── versions/
│   │   ├── 0001_init_enums_and_barbershops.py
│   │   ├── 0002_staff_and_roles.py
│   │   ├── 0003_services_and_hours.py
│   │   └── ...
│   └── script.py.mako
│
├── scripts/
│   ├── seed.py                  # Dados de teste para dev local
│   ├── migrate.py               # Runner de migrações (wrapper Alembic)
│   └── setup_localstack.py      # Criar Cognito User Pool + S3 bucket no LocalStack
│
└── tests/
    ├── conftest.py              # Fixtures compartilhadas (db session, factories)
    └── test_models.py
```

**Uso local (editable install):**
```bash
cd hairdule-auth-service
pip install -e ../hairdule-shared   # Mudanças refletem instantaneamente
```

**Deploy como Lambda Layer:**
```bash
# CI/CD empacota para Layer
mkdir -p layer/python
pip install ../hairdule-shared --target layer/python
cd layer && zip -r hairdule-shared-layer.zip python/
# SST referencia o ZIP como Layer
```

---

### 4.2 `hairdule-infra` — Infraestrutura AWS (SST v4)

Define **todos** os recursos AWS de forma reproduzível. As Lambdas Python referenciam seus repos como sources.

```
hairdule-infra/
├── package.json
├── tsconfig.json
├── sst.config.ts                # Ponto de entrada SST
│
├── infra/
│   ├── database.ts              # Aurora Serverless v2 (PostgreSQL 16, MinACU 0.5, MaxACU 4.0)
│   ├── vpc.ts                   # VPC + Security Groups + Subnets
│   ├── auth.ts                  # Cognito User Pool + Client
│   ├── api.ts                   # API Gateway v2 (HTTP API) + rotas para cada Lambda
│   ├── functions.ts             # Definição das 9 Lambdas Python (source, handler, runtime, layers)
│   ├── layers.ts                # Lambda Layer hairdule-shared
│   ├── storage.ts               # S3 bucket para fotos
│   ├── cdn.ts                   # CloudFront distributions (portal + dashboard)
│   ├── waf.ts                   # AWS WAF rules
│   ├── secrets.ts               # Secrets Manager entries
│   ├── budgets.ts               # AWS Budgets + alertas
│   └── scheduler.ts             # EventBridge rules (tarefas agendadas)
│
└── scripts/
    └── deploy-staging.sh
```

**Exemplo de definição de Lambda Python no SST:**
```typescript
// infra/functions.ts
const sharedLayer = new lambda.LayerVersion(stack, "SharedLayer", {
  code: lambda.Code.fromAsset("../hairdule-shared/layer"),
  compatibleRuntimes: [lambda.Runtime.PYTHON_3_12],
  description: "Hairdule shared models, schemas, and utilities",
});

const authService = new sst.aws.Function("AuthService", {
  handler: "src/handler.handler",
  runtime: "python3.12",
  timeout: "30 seconds",
  memory: "256 MB",
  layers: [sharedLayer],
  environment: {
    DATABASE_URL: database.url,
    COGNITO_USER_POOL_ID: auth.userPoolId,
    JWT_SECRET: secrets.jwtSecret,
  },
});
```

---

### 4.3 Template de Lambda — Estrutura Padrão (Python)

Todas as 9 Lambdas seguem a mesma estrutura interna. Cada uma é uma aplicação FastAPI com múltiplas rotas dentro do seu domínio de negócio, servida via Mangum na AWS e Uvicorn localmente.

```
hairdule-<nome>-service/
├── pyproject.toml               # deps: hairdule-shared, fastapi, mangum, pydantic, sqlalchemy
├── requirements.txt             # Deps para deploy (sem hairdule-shared — vem da Layer)
├── requirements-dev.txt         # Deps de dev (pytest, ruff, mypy, httpx)
├── .env.local                   # Variáveis locais (nunca commitado)
├── .env.example
├── .gitignore
├── ruff.toml                    # Configuração Ruff (linting + formatting)
├── mypy.ini                     # Configuração mypy (type checking)
│
├── src/
│   ├── __init__.py
│   ├── handler.py               # Lambda handler (Mangum wrapper do FastAPI app)
│   ├── app.py                   # FastAPI app com rotas + middleware + exception handlers
│   ├── local_server.py          # Uvicorn runner para dev local (hot-reload)
│   │
│   ├── routes/
│   │   ├── __init__.py          # APIRouter principal que agrupa sub-routers
│   │   ├── <rota_1>.py          # Router com endpoints
│   │   ├── <rota_2>.py
│   │   └── ...
│   │
│   ├── services/                # Lógica de negócio (sem dependência de HTTP)
│   │   ├── __init__.py
│   │   ├── <dominio>_service.py
│   │   └── ...
│   │
│   ├── dependencies/            # FastAPI Dependencies (Depends)
│   │   ├── __init__.py
│   │   ├── auth.py              # get_current_user, require_owner
│   │   └── database.py          # get_db session
│   │
│   └── tests/
│       ├── __init__.py
│       ├── conftest.py          # Fixtures (TestClient, db session, factories)
│       ├── test_<rota_1>.py
│       ├── test_<rota_2>.py
│       └── ...
│
└── .github/
    └── workflows/
        └── ci.yml               # Ruff → mypy → pytest → Deploy via SST
```

**Exemplo — `handler.py` (entry point Lambda):**
```python
from mangum import Mangum
from src.app import app

handler = Mangum(app, lifespan="off")
```

**Exemplo — `app.py`:**
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from hairdule_shared.errors import app_error_handler, AppError
from hairdule_shared.middleware.logger import LoggingMiddleware
from src.routes import router

app = FastAPI(title="Hairdule Auth Service", docs_url="/docs")

app.add_middleware(CORSMiddleware, allow_origins=["*"], ...)
app.add_middleware(LoggingMiddleware)
app.add_exception_handler(AppError, app_error_handler)
app.include_router(router)
```

**Exemplo — `local_server.py`:**
```python
import uvicorn

if __name__ == "__main__":
    uvicorn.run("src.app:app", host="0.0.0.0", port=3001, reload=True)
```

**Exemplo — CI/CD (`ci.yml`):**
```yaml
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install -r requirements-dev.txt
      - run: pip install -e ../hairdule-shared
      - run: ruff check .          # Linting
      - run: mypy src/             # Type checking
      - run: pytest                # Testes
      - run: npx sst deploy       # Deploy via SST
```

---

### 4.4 Lambdas — Rotas por Domínio

#### `hairdule-auth-service` (porta 3001)

| Método | Rota | Auth | Descrição |
|---|---|---|---|
| POST | `/auth/signup` | Público | Cria usuário + barbearia + role + staff (atômico) |
| POST | `/auth/login` | Público | Autentica e retorna JWT |
| POST | `/auth/forgot-password` | Público | Envia link de reset |
| POST | `/auth/reset-password` | Público | Reseta senha com token |
| POST | `/auth/change-password` | JWT | Altera senha |
| POST | `/auth/refresh` | Refresh Token | Renova JWT |

---

#### `hairdule-barbershop-service` (porta 3002)

| Método | Rota | Auth | Descrição |
|---|---|---|---|
| GET | `/barbershop` | JWT | Dados completos do estabelecimento |
| PUT | `/barbershop` | JWT (owner) | Atualizar dados |
| POST | `/barbershop/onboarding-complete` | JWT (owner) | Finalizar onboarding (atômico) |
| POST | `/barbershop/photo-upload` | JWT (owner) | Upload de logo/foto |
| GET | `/public/barbershop` | Público | Dados públicos (por slug ou id) |
| GET | `/public/lookup` | Público | Buscar por slug/CNPJ |

---

#### `hairdule-staff-service` (porta 3003)

| Método | Rota | Auth | Descrição |
|---|---|---|---|
| GET | `/staff` | JWT | Listar profissionais (com serviços) |
| POST | `/staff` | JWT (owner) | Criar profissional |
| PUT | `/staff` | JWT | Atualizar profissional |
| DELETE | `/staff/{id}` | JWT (owner) | Remover profissional |
| GET | `/public/staff` | Público | Staff público (sem PII — view `staff_public`) |

---

#### `hairdule-services-service` (porta 3004)

| Método | Rota | Auth | Descrição |
|---|---|---|---|
| GET | `/services` | JWT | Listar serviços |
| POST | `/services` | JWT | Criar serviço |
| PUT | `/services` | JWT | Atualizar serviço |
| DELETE | `/services/{id}` | JWT | Remover serviço |
| GET | `/public/services` | Público | Serviços ativos de uma barbearia |

---

#### `hairdule-availability-service` (porta 3005)

| Método | Rota | Auth | Descrição |
|---|---|---|---|
| GET | `/business-hours` | JWT | Horários de funcionamento |
| POST | `/business-hours` | JWT (owner) | Criar/atualizar horário |
| GET | `/staff-hours` | JWT | Horários do profissional |
| POST | `/staff-hours` | JWT | Criar/atualizar horário |
| GET | `/availability-blocks` | JWT | Listar bloqueios |
| POST | `/availability-blocks` | JWT | Criar bloqueio (one_time, recurring, vacation) |
| PUT | `/availability-blocks` | JWT | Atualizar bloqueio |
| DELETE | `/availability-blocks/{id}` | JWT | Remover bloqueio |
| GET | `/public/availability` | Público | Slots disponíveis para data |

---

#### `hairdule-appointments-service` (porta 3006)

| Método | Rota | Auth | Descrição |
|---|---|---|---|
| GET | `/appointments?mode=list` | JWT | Listar por data |
| GET | `/appointments?mode=availability` | JWT | Slots com status dos profissionais |
| GET | `/appointments?mode=audit_log` | JWT | Log de auditoria |
| POST | `/appointments` | JWT | Criar agendamento (staff) |
| PUT | `/appointments` | JWT | Atualizar status/reagendar |
| POST | `/public/booking` | Público | Criar agendamento (cliente) |
| GET | `/public/appointments-by-phone` | Público | Agendamentos do cliente |
| POST | `/public/cancel-confirm` | Público | Confirmar cancelamento (magic link) |
| POST | `/public/cancel-revert` | Público | Reverter cancelamento |
| POST | `/public/reschedule-confirm` | Público | Confirmar reagendamento |
| POST | `/public/reschedule-revert` | Público | Reverter reagendamento |
| POST | `/public/consent` | Público | Consentimento LGPD |

---

#### `hairdule-subscriptions-service` (porta 3007)

| Método | Rota | Auth | Descrição |
|---|---|---|---|
| GET | `/subscription/check` | JWT | Status da assinatura |
| POST | `/subscription/select-plan` | JWT (owner) | Selecionar plano + Stripe Checkout |
| POST | `/stripe/webhook` | Stripe-Signature | Processar eventos Stripe |

---

#### `hairdule-notifications-service` (porta 3008)

| Método | Rota | Auth | Descrição |
|---|---|---|---|
| GET | `/notifications` | JWT | Listar notificações in-app |
| PUT | `/notifications` | JWT | Marcar como lida |
| GET | `/notification-preferences` | JWT | Obter preferências |
| PUT | `/notification-preferences` | JWT | Atualizar preferências |
| POST | `/push-subscriptions` | JWT | Registrar endpoint WebPush |
| DELETE | `/push-subscriptions` | JWT | Remover endpoint |

---

#### `hairdule-analytics-service` (porta 3009)

| Método | Rota | Auth | Descrição |
|---|---|---|---|
| GET | `/analytics` | JWT | Métricas por período (7d, 30d, 90d, custom) |
| POST | `/ai/insights` | JWT | Insights sobre o estabelecimento |
| POST | `/ai/smart-booking` | JWT | Sugestão inteligente de horário |

---

### 4.5 `hairdule-app-dashboard` — Angular Dashboard

```
hairdule-app-dashboard/
├── angular.json
├── package.json
├── tsconfig.json
├── proxy.conf.json              # Proxy para APIs locais
│
├── src/
│   ├── main.ts
│   ├── index.html
│   ├── styles.scss              # Tema global + Angular Material custom
│   │
│   ├── app/
│   │   ├── app.config.ts
│   │   ├── app.routes.ts        # Rotas com lazy loading
│   │   ├── app.component.ts
│   │   │
│   │   ├── core/                # Singletons (providedIn: 'root')
│   │   │   ├── auth/
│   │   │   │   ├── auth.guard.ts
│   │   │   │   ├── auth.interceptor.ts
│   │   │   │   └── auth.service.ts
│   │   │   ├── http/
│   │   │   │   └── api.service.ts        # HttpClient wrapper com base URL
│   │   │   └── layout/
│   │   │       ├── sidebar/
│   │   │       │   └── sidebar.component.ts
│   │   │       ├── header/
│   │   │       │   └── header.component.ts
│   │   │       └── main-layout/
│   │   │           └── main-layout.component.ts
│   │   │
│   │   ├── features/            # Feature areas (lazy loaded)
│   │   │   ├── auth/
│   │   │   │   ├── login/
│   │   │   │   ├── signup/
│   │   │   │   └── forgot-password/
│   │   │   ├── onboarding/
│   │   │   │   ├── business-type/
│   │   │   │   ├── staff-count/
│   │   │   │   ├── services-setup/
│   │   │   │   └── hours-setup/
│   │   │   ├── dashboard/       # Home com métricas resumidas
│   │   │   ├── agenda/          # Visualização de agendamentos (timeline)
│   │   │   ├── staff/           # Gestão de profissionais
│   │   │   ├── services/        # Gestão de serviços
│   │   │   ├── availability/    # Horários e bloqueios
│   │   │   ├── customers/       # Base de clientes
│   │   │   ├── settings/        # Configurações da barbearia
│   │   │   ├── subscription/    # Plano e pagamento
│   │   │   └── notifications/   # Preferências de notificação
│   │   │
│   │   └── shared/              # Componentes, pipes, directives reutilizáveis
│   │       ├── components/
│   │       │   ├── confirm-dialog/
│   │       │   ├── loading-spinner/
│   │       │   ├── empty-state/
│   │       │   └── status-badge/
│   │       ├── pipes/
│   │       │   ├── currency-brl.pipe.ts
│   │       │   └── phone-br.pipe.ts
│   │       └── directives/
│   │
│   ├── environments/
│   │   ├── environment.ts
│   │   └── environment.development.ts
│   │
│   └── assets/
│       ├── icons/
│       └── images/
│
└── .github/
    └── workflows/
        └── ci.yml
```

**Proxy config para dev local** (`proxy.conf.json`):
```json
{
  "/api/auth": { "target": "http://localhost:3001", "pathRewrite": {"^/api": ""} },
  "/api/barbershop": { "target": "http://localhost:3002", "pathRewrite": {"^/api": ""} },
  "/api/staff": { "target": "http://localhost:3003", "pathRewrite": {"^/api": ""} },
  "/api/services": { "target": "http://localhost:3004", "pathRewrite": {"^/api": ""} },
  "/api/business-hours": { "target": "http://localhost:3005", "pathRewrite": {"^/api": ""} },
  "/api/availability-blocks": { "target": "http://localhost:3005", "pathRewrite": {"^/api": ""} },
  "/api/staff-hours": { "target": "http://localhost:3005", "pathRewrite": {"^/api": ""} },
  "/api/appointments": { "target": "http://localhost:3006", "pathRewrite": {"^/api": ""} },
  "/api/subscription": { "target": "http://localhost:3007", "pathRewrite": {"^/api": ""} },
  "/api/stripe": { "target": "http://localhost:3007", "pathRewrite": {"^/api": ""} },
  "/api/notifications": { "target": "http://localhost:3008", "pathRewrite": {"^/api": ""} },
  "/api/analytics": { "target": "http://localhost:3009", "pathRewrite": {"^/api": ""} }
}
```

---

### 4.6 `hairdule-app` — Angular Portal Público

```
hairdule-app/
├── angular.json
├── package.json
├── tsconfig.json
├── proxy.conf.json              # Proxy para APIs locais (rotas /public/*)
│
├── src/
│   ├── main.ts
│   ├── main.server.ts           # SSR entry point
│   ├── index.html
│   ├── styles.scss              # Tema leve, mobile-first
│   │
│   ├── app/
│   │   ├── app.config.ts
│   │   ├── app.config.server.ts # SSR config
│   │   ├── app.routes.ts
│   │   ├── app.component.ts
│   │   │
│   │   ├── core/
│   │   │   └── http/
│   │   │       └── api.service.ts
│   │   │
│   │   ├── features/
│   │   │   ├── barbershop-page/     # Página pública (dados, endereço, logo)
│   │   │   ├── booking-flow/        # Wizard: serviço → staff → horário → dados
│   │   │   │   ├── select-service/
│   │   │   │   ├── select-staff/
│   │   │   │   ├── select-datetime/
│   │   │   │   └── customer-data/
│   │   │   ├── confirmation/        # Código do agendamento + resumo
│   │   │   ├── cancel/              # Cancelamento via magic link
│   │   │   ├── reschedule/          # Reagendamento via magic link
│   │   │   └── customer-portal/     # "Meus agendamentos" (por magic link)
│   │   │
│   │   └── shared/
│   │       ├── components/
│   │       └── pipes/
│   │
│   ├── environments/
│   └── assets/
│
└── .github/
    └── workflows/
        └── ci.yml
```

---

## Fase 0 — Setup do Ambiente de Desenvolvimento

> **Meta:** Ambiente 100% funcional localmente. Todos os projetos criados, Docker rodando, dev servers respondendo.  
> **Estimativa:** 1-2 dias

### Pré-requisitos

Instalar/atualizar:
- Python **3.12** (runtime das Lambdas)
- **uv** (gerenciador de pacotes Python — `pip install uv`)
- Node.js **22 LTS** (SST v4 requer >= 22)
- Docker Desktop
- Angular CLI: `npm i -g @angular/cli`
- Stripe CLI (para fases futuras)

### Infraestrutura Local

Subir Docker Compose com PostgreSQL 16 + LocalStack (conforme seção 3). Criar `.env.example` e `.env.local` com variáveis de ambiente para desenvolvimento.

### Repositórios Iniciais

Criar e inicializar os seguintes repositórios nesta fase:

1. **`hairdule-shared`** — Pacote Python com models SQLAlchemy, schemas Pydantic, auth middleware, utils, migrações Alembic
2. **`hairdule-infra`** — SST config com definição dos recursos AWS + Lambda Layer
3. **`hairdule-auth-service`** — Primeira Lambda Python (será implementada na Fase 1)
4. **`hairdule-app-dashboard`** — Angular 18 + Angular Material (tema Aqua `#22BEF5`)
5. **`hairdule-app`** — Angular 18 com SSR (tema leve, mobile-first)

Os demais repos de Lambda serão criados conforme cada fase demandar.

### Validação

Cada serviço deve responder localmente:
- PostgreSQL: `docker exec hairdule-postgres pg_isready`
- LocalStack: `curl http://localhost:4566/_localstack/health`
- Auth Service: `http://localhost:3001/docs` → Swagger UI do FastAPI
- Dashboard: `http://localhost:4300`
- Portal: `http://localhost:4200`

### ✅ Checklist — Fase 0

- [ ] Python 3.12 instalado (`python --version`)
- [ ] uv instalado (`uv --version`)
- [ ] Node.js 22 LTS instalado (`node -v`)
- [ ] Docker Desktop instalado e rodando
- [ ] `docker compose up -d` → PostgreSQL e LocalStack healthy
- [ ] `hairdule-shared`: projeto criado, `pip install -e .` ok, models base definidos
- [ ] `hairdule-shared`: `alembic upgrade head` cria schema no PostgreSQL local
- [ ] `hairdule-infra`: projeto SST criado, `sst.config.ts` com recursos definidos
- [ ] `hairdule-auth-service`: projeto criado, `uvicorn src.app:app --port 3001 --reload` → Swagger em `http://localhost:3001/docs`
- [ ] `hairdule-app-dashboard`: `ng serve --port 4300` → rodando em `http://localhost:4300`
- [ ] `hairdule-app`: `ng serve --port 4200` → rodando em `http://localhost:4200`
- [ ] Conexão do backend com PostgreSQL local validada (SQLAlchemy engine conecta)
- [ ] `.env.example` criado com template de variáveis

---

## Fase 1 — Auth Service + Cadastro (Signup)

> **Meta:** Cadastro funcional end-to-end localmente. Usuário se cadastra, recebe JWT, dados salvos no banco.  
> **Estimativa:** 3-5 dias  
> **Depende de:** Fase 0

### Banco de Dados — Migrações

Tabelas criadas nesta fase (via `hairdule-shared`):

| Tabela | Descrição |
|---|---|
| `barbershops` | Estabelecimentos (todos os campos do ANALISE.md) |
| `user_roles` | Vínculo usuário ↔ barbearia (user_id, barbershop_id, role) |
| `staff` | Profissionais (user_id, barbershop_id, name, email, phone, role, active) |

ENUMs: `business_type`, `barbershop_status`, `staff_role`, `agenda_visibility`

### Backend — `hairdule-auth-service`

**Auth Adapter Pattern (virtualização do Cognito):**

```python
from typing import Protocol

class IAuthProvider(Protocol):
    async def sign_up(self, email: str, password: str) -> dict[str, str]:
        """Returns {'user_id': '...'}"""
        ...

    async def sign_in(self, email: str, password: str) -> dict[str, str]:
        """Returns {'access_token': '...', 'refresh_token': '...'}"""
        ...

    async def forgot_password(self, email: str) -> None: ...

    async def reset_password(self, token: str, password: str) -> None: ...

    async def change_password(self, access_token: str, old: str, new: str) -> None: ...

    async def refresh_token(self, refresh_token: str) -> dict[str, str]:
        """Returns {'access_token': '...'}"""
        ...

# Produção: CognitoAuthProvider (boto3 cognito-idp)
# Dev local: LocalAuthProvider (passlib/bcrypt + PyJWT auto-assinado)
```

**Fluxo do Signup (operação atômica):**
1. Validar input (Pydantic v2): email, password (min 6), trade_name (obrigatório)
2. Verificar unicidade de email e CNPJ
3. Criar usuário no auth provider (Cognito ou local)
4. Em transação DB (SQLAlchemy `session.begin()`): criar `barbershop` (ONBOARDING), `user_role` (owner), `staff` (owner)
5. Gerar JWT próprio do Hairdule (PyJWT — claims: user_id, barbershop_id, role, exp)
6. Retornar tokens + user + barbershop

**Erros tratados:** 400 (VALIDATION_ERROR), 409 (EMAIL/CNPJ_ALREADY_EXISTS), 422 (PASSWORD_COMPROMISED), 500 (BARBERSHOP_ERROR)

### Frontend — Telas de Auth (Dashboard)

Páginas: Signup (`/signup`), Login (`/login`), Forgot Password (`/forgot-password`), Reset Password (`/reset-password`).

Componentes de infra: `AuthGuard`, `AuthInterceptor` (injeta JWT), `AuthService` (login, signup, logout, isAuthenticated).

Design: Angular Material, tema Aqua, layout centrado com card glassmorphism, validação em tempo real.

### ✅ Checklist — Fase 1

**Banco de Dados:**
- [ ] Model SQLAlchemy para ENUMs (business_type, barbershop_status, staff_role, agenda_visibility)
- [ ] Model SQLAlchemy para `barbershops` (todos os campos)
- [ ] Model SQLAlchemy para `user_roles` e `staff`
- [ ] Índices criados (idx_barbershops_owner, idx_barbershops_status, idx_staff_barbershop, idx_staff_user)
- [ ] Migração Alembic gerada e aplicada no PostgreSQL local

**Backend — auth-service:**
- [ ] IAuthProvider Protocol implementado
- [ ] LocalAuthProvider (dev) implementado (passlib + PyJWT)
- [ ] CognitoAuthProvider (prod) implementado (boto3)
- [ ] JWT sign/verify com claims (user_id, barbershop_id, role, exp) via PyJWT
- [ ] FastAPI auth dependency funcional (`Depends(get_current_user)`)
- [ ] POST `/auth/signup` — cria usuário + barbearia + role + staff (atômico)
- [ ] POST `/auth/login` — retorna JWT válido
- [ ] POST `/auth/forgot-password` — envia link de reset
- [ ] POST `/auth/reset-password` — reseta com token
- [ ] POST `/auth/change-password` — altera senha (autenticado)
- [ ] POST `/auth/refresh` — renova JWT
- [ ] Validações Pydantic v2 para todos os inputs
- [ ] Erros tipados (400, 409, 422, 500)

**Frontend — Dashboard:**
- [ ] Página de Signup funcional (formulário + validação + loading + erros)
- [ ] Página de Login funcional
- [ ] Página de Forgot Password
- [ ] Página de Reset Password
- [ ] AuthGuard bloqueando rotas protegidas
- [ ] AuthInterceptor injetando JWT
- [ ] AuthService gerenciando estado de autenticação

**Testes (pytest):**
- [ ] Signup válido → 201 + tokens + barbershop
- [ ] Signup email duplicado → 409
- [ ] Signup CNPJ duplicado → 409
- [ ] Signup senha fraca → 422
- [ ] Login válido → 200 + JWT
- [ ] Login inválido → 401
- [ ] JWT contém claims corretos
- [ ] Refresh token funcional
- [ ] Dados verificáveis no banco (SQLAlchemy query)

**Deploy AWS:**
- [ ] Cognito User Pool criado via SST
- [ ] Lambda Layer hairdule-shared deployada
- [ ] Lambda auth-service deployada (Python 3.12)
- [ ] API Gateway route `/auth/*` configurada
- [ ] Teste em staging com Cognito real
- [ ] Pipeline CI/CD funcional (ruff → mypy → pytest → deploy)

---

## Fase 2 — Barbershop Service + Onboarding

> **Meta:** Completar o fluxo de onboarding de 5 etapas. Após completar, barbearia fica ACTIVE.  
> **Estimativa:** 3-4 dias  
> **Depende de:** Fase 1

### Banco de Dados

Tabelas: `services`, `staff_services`, `business_hours`, `consents`

### Backend — `hairdule-barbershop-service`

Novo repositório criado nesta fase. Rotas: GET/PUT `/barbershop`, POST `/barbershop/onboarding-complete`.

**Onboarding Complete (transação atômica via SQLAlchemy):**
1. Atualiza barbershop (perfil, endereço, segmento)
2. Cria staff para cada profissional
3. Cria services para cada serviço
4. Vincula staff_services
5. Cria 7 business_hours (dom a sáb)
6. Registra consents (LGPD)
7. Altera barbershop.status → ACTIVE

### Frontend — Stepper de Onboarding (Dashboard)

5 etapas com `mat-stepper`:
1. Register (já feito)
2. BusinessType — Cards visuais com ícones por segmento
3. StaffCount — Lista dinâmica de profissionais
4. Services — Lista dinâmica de serviços
5. Hours — Dias da semana com horários de abertura/fechamento

Dados intermediários em localStorage, envio único no passo final.

### ✅ Checklist — Fase 2

**Banco de Dados:**
- [ ] Model SQLAlchemy para `services` (todos os campos: duration, price, buffer, pausa, variável)
- [ ] Model SQLAlchemy para `staff_services` (N:N)
- [ ] Model SQLAlchemy para `business_hours` (day_of_week, open/close, breaks JSONB)
- [ ] Model SQLAlchemy para `consents` (LGPD)
- [ ] Migração Alembic gerada e aplicada

**Backend — barbershop-service (novo repo):**
- [ ] Repositório `hairdule-barbershop-service` criado
- [ ] GET `/barbershop` — retorna dados completos
- [ ] PUT `/barbershop` — atualiza dados (owner only)
- [ ] POST `/barbershop/onboarding-complete` — atômico (SQLAlchemy transaction)
- [ ] Validação: barbearia já ACTIVE não pode refazer onboarding (409)

**Frontend — Dashboard:**
- [ ] Stepper de 5 etapas com Angular Material
- [ ] Etapa BusinessType com cards visuais
- [ ] Etapa StaffCount com lista dinâmica
- [ ] Etapa Services com lista dinâmica
- [ ] Etapa Hours com toggles e time pickers
- [ ] Dados em localStorage preservados entre etapas
- [ ] Redirect para dashboard home após sucesso

**Testes (pytest):**
- [ ] Onboarding válido → 200 + status ACTIVE
- [ ] Onboarding sem consentimento → 400
- [ ] Onboarding com barbearia já ACTIVE → 409
- [ ] Fluxo E2E: signup → 5 etapas → dashboard

**Deploy AWS:**
- [ ] Lambda barbershop-service deployada (Python 3.12 + Layer)
- [ ] API Gateway routes configuradas
- [ ] Teste em staging

---

## Fase 3 — Staff & Services Management

> **Meta:** CRUD completo de profissionais e serviços, com permissões owner vs barber.  
> **Estimativa:** 3-4 dias  
> **Depende de:** Fase 2

### Backend — `hairdule-staff-service` + `hairdule-services-service`

Dois novos repositórios criados nesta fase.

**Regras de permissão (staff):**
- Owner: CRUD completo de qualquer profissional
- Barber: edita apenas próprio perfil
- `protect_staff_sensitive_fields()`: barber NÃO pode alterar role, active, agenda_visibility
- `can_add_staff()`: respeita limite do plano

**Serviços com pausa (dual-block):**
- `pause_after_min`: minutos antes da pausa
- `pause_duration_min`: duração da pausa (staff livre)
- `duration_min`: apenas tempo ativo
- Tempo total = duration_min + pause_duration_min

**Serviços com duração variável:**
- `is_duration_variable = true` + `max_duration_min`
- Booking público reserva max_duration_min por padrão

### Frontend — Telas de Gestão (Dashboard)

Staff: listagem, modal criação/edição, atribuição de serviços, exclusão com confirmação.
Services: listagem, modal com campos especiais (pausa, variável), drag-and-drop para reordenar, toggle ativo/inativo.

### ✅ Checklist — Fase 3

**Backend — staff-service (novo repo):**
- [ ] Repositório `hairdule-staff-service` criado
- [ ] GET/POST/PUT/DELETE `/staff`
- [ ] Permissões owner vs barber implementadas (FastAPI Dependencies)
- [ ] `protect_staff_sensitive_fields()` validada
- [ ] `can_add_staff()` verificando limite do plano
- [ ] GET `/public/staff` retornando sem PII

**Backend — services-service (novo repo):**
- [ ] Repositório `hairdule-services-service` criado
- [ ] GET/POST/PUT/DELETE `/services`
- [ ] Serviços com pausa (dual-block) implementados
- [ ] Serviços com duração variável implementados
- [ ] `sort_order` para reordenação
- [ ] GET `/public/services` retornando serviços ativos

**Frontend — Dashboard:**
- [ ] Listagem de profissionais com avatar, cargo, status, serviços
- [ ] Modal de criação/edição de profissional
- [ ] Exclusão com confirmação
- [ ] Listagem de serviços com duração, preço, buffer
- [ ] Modal de criação/edição com campos de pausa e variável
- [ ] Drag-and-drop para reordenar

**Testes (pytest):**
- [ ] CRUD completo de staff e services
- [ ] Owner cria/remove → OK; Barber cria/remove → 403
- [ ] Barber edita próprio perfil → OK; edita outro → 403
- [ ] Barber altera role → campo protegido
- [ ] can_add_staff() bloqueia no limite

**Deploy AWS:**
- [ ] Lambdas staff-service e services-service deployadas (Python 3.12 + Layer)
- [ ] Teste em staging

---

## Fase 4 — Availability & Business Hours

> **Meta:** Gerenciamento de horários e disponibilidade. Cálculo de slots com 6 camadas de verificação.  
> **Estimativa:** 4-5 dias  
> **Depende de:** Fase 3

### Banco de Dados

Tabelas: `staff_hours`, `availability_blocks`, `time_off` (legada)

### Backend — `hairdule-availability-service`

Novo repositório. Lógica crítica: cálculo de slots disponíveis.

**Hierarquia de verificações (6 camadas):**

```
Slot disponível?
├── 1. Dia aberto? (business_hours.is_open)
├── 2. Dentro do horário? (open_time ↔ close_time)
├── 3. Em break? (business_hours.breaks JSONB)
├── 4. Profissional trabalha? (staff_hours)
├── 5. Conflito com agendamento? (appointments — buffer incluso)
│       Status ignorados: CANCELADO_CLIENTE, CANCELADO_BARBEARIA, REMARCADO
└── 6. Bloqueio ativo? (availability_blocks + time_off)
```

Intervalo configurável: `barbershop.slot_interval_min` (padrão 30min).
Bloqueios one_time armazenados em UTC, convertidos para America/Sao_Paulo via `zoneinfo.ZoneInfo`.

### ✅ Checklist — Fase 4

**Banco de Dados:**
- [ ] Model SQLAlchemy para `staff_hours`, `availability_blocks`, `time_off`
- [ ] Migração Alembic gerada e aplicada

**Backend — availability-service (novo repo):**
- [ ] Repositório `hairdule-availability-service` criado
- [ ] GET/POST `/business-hours`
- [ ] GET/POST `/staff-hours`
- [ ] CRUD `/availability-blocks` (one_time, recurring, vacation)
- [ ] GET `/public/availability` — slots públicos
- [ ] Cálculo de slots com 6 camadas implementado
- [ ] slot_interval_min configurável
- [ ] Conversão UTC ↔ America/Sao_Paulo para bloqueios one_time (zoneinfo)

**Frontend — Dashboard:**
- [ ] Tela de horários de funcionamento (7 dias, toggles, time pickers, breaks)
- [ ] Tela de horários por profissional
- [ ] Tela de bloqueios (listar, criar, editar, remover)
- [ ] Modal de criação com campos dinâmicos por tipo de bloqueio

**Testes (pytest):**
- [ ] Slot normal disponível → ✅
- [ ] Slot em dia fechado → ❌
- [ ] Slot fora do horário → ❌
- [ ] Slot em break → ❌
- [ ] Slot com agendamento existente → ❌
- [ ] Slot com agendamento cancelado → ✅ (ignorado)
- [ ] Slot com buffer → ❌
- [ ] Slot com bloqueio (one_time, recurring, vacation) → ❌
- [ ] Slot com folga legada → ❌
- [ ] Pausa de serviço NÃO bloqueia slot → ✅
- [ ] slot_interval_min customizado → correto

**Deploy AWS:**
- [ ] Lambda availability-service deployada (Python 3.12 + Layer)
- [ ] Teste de slots em staging

---

## Fase 5 — Appointments (Agendamentos pelo Staff)

> **Meta:** Criação, edição, cancelamento, transição de status e auditoria de agendamentos via dashboard.  
> **Estimativa:** 5-7 dias  
> **Depende de:** Fase 4

### Banco de Dados

Tabelas: `appointments` (completa), `appointment_audit_log`, `customers`
ENUM: `appointment_status` (AGENDADO, CONFIRMADO, EM_ATENDIMENTO, FINALIZADO, CANCELADO_CLIENTE, CANCELADO_BARBEARIA, NAO_COMPARECEU, REMARCADO)
Trigger: `generate_booking_code()` → BKG-YYYYMMDD-NNNN
View: `appointments_safe` (máscara PII)

### Backend — `hairdule-appointments-service`

Novo repositório. Lambda com mais rotas (agendamentos staff + rotas públicas do portal).

**Máquina de estados:**

```
AGENDADO → CONFIRMADO → EM_ATENDIMENTO → FINALIZADO
  ├→ CANCELADO_CLIENTE / CANCELADO_BARBEARIA / NAO_COMPARECEU
  └→ REMARCADO (quando substituído por reagendamento)
```

**Criação:** valida data futura, horário dentro do funcionamento, sem conflito, profissional disponível, `can_barbershop_write()`.

**Cancelamento:** `cancel_reason` obrigatório, registra canceled_at/by/by_user_id.

**Reagendamento:** novo com `rescheduled_from`, original → REMARCADO com `rescheduled_to`.

**Dual-block (serviços com pausa):** gera `time_blocks` [{start,end},{start,end}], registra pause_start/end, active_duration_min.

**Audit log:** toda mudança → INSERT em appointment_audit_log (field, old, new, changed_by, source).

**Visibilidade PII:**

| Papel | Vê quais agendas | PII visível |
|---|---|---|
| Owner | Todas | Completo |
| Barber OWN_ONLY | Apenas própria | Nos próprios |
| Barber TEAM_READ_ONLY | Todas | Mascarada ("Primeiro ***", phone/email/notes = NULL) |

### Frontend — Agenda no Dashboard

Timeline diária por profissional, modal de criação (profissional → serviço → data → horário → cliente), transições de status (botões contextuais), detalhes com audit log, filtros por profissional e data.

### ✅ Checklist — Fase 5

**Banco de Dados:**
- [ ] Model SQLAlchemy para `appointments`, `appointment_audit_log`, `customers`
- [ ] ENUM `appointment_status`
- [ ] Trigger `generate_booking_code()` (via Alembic migration com raw SQL)
- [ ] View `appointments_safe` (máscara PII)
- [ ] Migração Alembic gerada e aplicada
- [ ] Seed com agendamentos de exemplo

**Backend — appointments-service (novo repo):**
- [ ] Repositório `hairdule-appointments-service` criado
- [ ] GET `/appointments?mode=list` — listar por data
- [ ] GET `/appointments?mode=availability` — slots com status
- [ ] GET `/appointments?mode=audit_log` — log de auditoria
- [ ] POST `/appointments` — criar agendamento (staff)
- [ ] PUT `/appointments` — atualizar status/reagendar
- [ ] Máquina de estados completa (todas as transições)
- [ ] Transição inválida → 422
- [ ] Conflito de horário → 409
- [ ] `can_barbershop_write()` verificada
- [ ] Cancelamento requer cancel_reason
- [ ] Reagendamento: rescheduled_from/to corretos
- [ ] Dual-block: time_blocks gerados corretamente
- [ ] Audit log em toda mudança
- [ ] Upsert customer por (barbershop_id, phone)
- [ ] PII mascarada para barbers sem permissão

**Frontend — Dashboard:**
- [ ] Timeline diária com slots por profissional
- [ ] Modal de criação de agendamento
- [ ] Botões de transição de status (Confirmar, Iniciar, Finalizar, Cancelar, No-show)
- [ ] Detalhes do agendamento com booking_code e audit log
- [ ] Filtros por profissional e data

**Testes (pytest):**
- [ ] Criar agendamento válido → 201 + booking_code
- [ ] Criar no passado → 400
- [ ] Criar fora do horário → 400
- [ ] Criar com conflito → 409
- [ ] Criar com assinatura blocked → 403
- [ ] Todas as transições válidas testadas
- [ ] Transição inválida → 422
- [ ] Cancelamento sem motivo → 400
- [ ] Reagendamento cria novo + marca original REMARCADO
- [ ] Dual-block gera time_blocks corretos
- [ ] Audit log registra mudanças
- [ ] PII mascarada para barber
- [ ] Owner vê PII completo
- [ ] Upsert customer (novo + existente)

**Deploy AWS:**
- [ ] Lambda appointments-service deployada (Python 3.12 + Layer)
- [ ] API Gateway routes configuradas
- [ ] Teste em staging

---

## Fase 6 — Portal Público (Booking Online)

> **Meta:** Cliente final agenda pelo portal público sem login. Cancelamento e reagendamento via magic link.  
> **Estimativa:** 5-7 dias  
> **Depende de:** Fase 5

### Banco de Dados

Tabela: `customer_consents` (barbershop_id, phone, policy_version, accepted_at)
Views: `staff_public` (sem PII), `plans_public`

### Backend — Rotas públicas na `hairdule-appointments-service`

As rotas `/public/*` são adicionadas ao repositório `hairdule-appointments-service` (agendamentos públicos) e a dados públicos nos repos de barbershop, staff e services.

**Validações do booking público:**
- Campos obrigatórios, telefone BR (10-11 dígitos), email obrigatório
- Data futura, horário dentro do funcionamento, slot livre
- Barbearia ACTIVE com booking_mode = 'online'
- LGPD consent na 1ª vez por (barbershop_id, phone)
- `can_barbershop_write()` ativa

**Magic links:** token único para cancelamento/reagendamento, enviado por email, expira em 24h.

### Frontend — Portal Angular

Fluxo de agendamento em 4 passos: Serviço → Profissional → Data/Horário → Dados do Cliente.
Páginas: barbershop-page, booking-flow, confirmation, cancel, reschedule, customer-portal.
Design: mobile-first, SSR para SEO, minimal bundle.

### ✅ Checklist — Fase 6

**Banco de Dados:**
- [ ] Model SQLAlchemy para `customer_consents`
- [ ] View `staff_public` e `plans_public`
- [ ] Migração Alembic aplicada

**Backend — rotas públicas:**
- [ ] POST `/public/booking` — agendamento do cliente
- [ ] GET `/public/barbershop` — dados públicos
- [ ] GET `/public/services` — serviços ativos
- [ ] GET `/public/staff` — staff sem PII
- [ ] GET `/public/availability` — slots disponíveis
- [ ] GET `/public/appointments-by-phone` — agendamentos do cliente
- [ ] POST `/public/cancel-confirm` / `cancel-revert`
- [ ] POST `/public/reschedule-confirm` / `reschedule-revert`
- [ ] POST `/public/consent` — LGPD
- [ ] GET `/public/lookup` — busca por slug/CNPJ
- [ ] Validações Pydantic completas do booking público
- [ ] Magic link: geração (secrets.token_urlsafe), envio (simulado em dev), expiração

**Frontend — Portal:**
- [ ] Página pública da barbearia (dados, endereço, logo)
- [ ] Passo 1: seleção de serviço (cards com preço/duração)
- [ ] Passo 2: escolha do profissional (cards com avatar)
- [ ] Passo 3: calendário + grid de slots
- [ ] Passo 4: dados do cliente + checkbox LGPD
- [ ] Página de confirmação com booking_code
- [ ] Página de cancelamento via magic link
- [ ] Página de reagendamento via magic link
- [ ] Customer portal (meus agendamentos)
- [ ] SSR funcionando para SEO
- [ ] Mobile-first e responsivo

**Testes (pytest):**
- [ ] Booking válido → 201 + booking_code
- [ ] Booking sem LGPD na 1ª vez → 400
- [ ] Booking com slot ocupado → 409
- [ ] Booking com barbearia inactive → 404
- [ ] Booking com modo manual → erro
- [ ] Booking com assinatura blocked → 403
- [ ] E2E: fluxo completo no portal → aparece no dashboard

**Deploy AWS:**
- [ ] Rotas públicas no API Gateway
- [ ] S3 + CloudFront para Portal
- [ ] Teste em staging

---

## Fase 7 — Subscriptions & Stripe

> **Meta:** Planos, checkout Stripe, cobrança recorrente, controle de escrita por assinatura.  
> **Estimativa:** 4-5 dias  
> **Depende de:** Fase 2 (paralelo com 3-6)

### Banco de Dados

Tabelas: `plans`, `subscriptions`
ENUMs: `subscription_status`, `billing_cycle`
Seed: individual (1 staff, R$59,90/mês), pequeno (3, R$99,90), medio (6, R$149,90), grande (10, R$199,90)

### Backend — `hairdule-subscriptions-service`

Novo repositório. Rotas: GET `/subscription/check`, POST `/subscription/select-plan`, POST `/stripe/webhook`.

**Ciclo de vida:** Signup → Trial (14d) → Seleção de plano → Stripe Checkout → active. Falha → attention → grace period → blocked.

**Funções de controle:**
- `can_barbershop_write()` → false se blocked/cancelled
- `can_add_staff()` → false se current_staff >= max_staff

### Teste Local

```bash
stripe listen --forward-to localhost:3007/stripe/webhook
stripe trigger checkout.session.completed
stripe trigger invoice.payment_failed
```

### ✅ Checklist — Fase 7

**Banco de Dados:**
- [ ] Model SQLAlchemy para `plans` e `subscriptions`
- [ ] ENUMs subscription_status e billing_cycle
- [ ] Seed com 4 planos padrão
- [ ] Migração Alembic aplicada

**Backend — subscriptions-service (novo repo):**
- [ ] Repositório `hairdule-subscriptions-service` criado
- [ ] GET `/subscription/check` com todos os campos
- [ ] POST `/subscription/select-plan` → sessão Stripe Checkout (stripe-python SDK)
- [ ] POST `/stripe/webhook` (Stripe-Signature — stripe.Webhook.construct_event)
- [ ] Webhook checkout.session.completed → active
- [ ] Webhook invoice.payment_failed → attention
- [ ] Webhook customer.subscription.deleted → cancelled
- [ ] Trial criado automaticamente no signup
- [ ] `can_barbershop_write()` implementada
- [ ] `can_add_staff()` implementada
- [ ] Override manual por admin

**Frontend — Dashboard:**
- [ ] Página de assinatura (plano atual, cards de planos, toggle mensal/anual)
- [ ] Botão "Assinar" → redirect Stripe Checkout
- [ ] Banner de alerta (trial expirando, attention, blocked)

**Testes (pytest):**
- [ ] Trial criado no signup
- [ ] check retorna status correto
- [ ] Webhook checkout.session.completed funcional
- [ ] Webhook invoice.payment_failed funcional
- [ ] can_barbershop_write() bloqueia quando blocked
- [ ] can_add_staff() respeita limite
- [ ] Stripe CLI forwarding funcionando

**Deploy AWS:**
- [ ] Lambda subscriptions-service deployada (Python 3.12 + Layer)
- [ ] Webhook Stripe configurado para URL de produção
- [ ] Chaves Stripe live em produção

---

## Fase 8 — Notifications & Push

> **Meta:** Notificações in-app e push WebPush VAPID para staff quando cliente agenda/cancela.  
> **Estimativa:** 3-4 dias  
> **Depende de:** Fase 5

### Banco de Dados

Tabelas: `notifications`, `notification_preferences`, `push_subscriptions`

### Backend — `hairdule-notifications-service`

Novo repositório. Tipos: NEW_APPOINTMENT, CANCELLATION, REMINDER.
Ações do staff NÃO geram push, apenas in-app.
WebPush VAPID: push para staff responsável + owner do estabelecimento (via `pywebpush`).

### ✅ Checklist — Fase 8

**Banco de Dados:**
- [ ] Model SQLAlchemy para `notifications`, `notification_preferences`, `push_subscriptions`
- [ ] Migração Alembic aplicada

**Backend — notifications-service (novo repo):**
- [ ] Repositório `hairdule-notifications-service` criado
- [ ] GET/PUT `/notifications`
- [ ] GET/PUT `/notification-preferences`
- [ ] POST/DELETE `/push-subscriptions`
- [ ] Notificação criada ao receber booking público
- [ ] Push enviado para staff + owner (pywebpush)
- [ ] Preferências respeitadas

**Frontend — Dashboard:**
- [ ] Ícone sino no header com badge
- [ ] Dropdown de notificações (lidas/não lidas)
- [ ] Marcar como lida (individual + todas)
- [ ] Página de preferências com toggles
- [ ] Service Worker para receber push

**Testes (pytest):**
- [ ] Notificação criada ao booking público
- [ ] Push enviado e recebido no browser
- [ ] Preferência desabilitada → não envia
- [ ] Badge atualiza

**Deploy AWS:**
- [ ] Lambda notifications-service deployada (Python 3.12 + Layer)
- [ ] VAPID keys no Secrets Manager

---

## Fase 9 — Analytics & AI

> **Meta:** Dashboard de métricas e sugestões inteligentes de agendamento.  
> **Estimativa:** 4-5 dias  
> **Depende de:** Fase 5

### Banco de Dados

Tabelas: `suggestion_tracking`, `admin_activity_log`

### Backend — `hairdule-analytics-service`

Novo repositório. Métricas: total agendamentos, taxa comparecimento, taxa cancelamento, receita estimada, profissional mais ativo, horário de pico, dia mais movimentado, clientes recorrentes, tempo médio.

Smart Booking Suggestion: histórico do cliente → disponibilidade → score → sugestões rankeadas.

### ✅ Checklist — Fase 9

**Banco de Dados:**
- [ ] Model SQLAlchemy para `suggestion_tracking` e `admin_activity_log`
- [ ] Migração Alembic aplicada

**Backend — analytics-service (novo repo):**
- [ ] Repositório `hairdule-analytics-service` criado
- [ ] GET `/analytics` com 9 métricas
- [ ] Filtros de período (7d, 30d, 90d, custom)
- [ ] POST `/ai/insights` — insights do estabelecimento
- [ ] POST `/ai/smart-booking` — sugestão de horário
- [ ] Suggestion tracking registrando outcomes

**Frontend — Dashboard:**
- [ ] Cards resumo (total, receita, cancelamento, comparecimento)
- [ ] Gráfico de linha (agendamentos/dia)
- [ ] Gráfico de barras (agendamentos/profissional)
- [ ] Gráfico de pizza (distribuição/serviço)
- [ ] Heatmap (horários de pico)
- [ ] Filtros de período funcionando
- [ ] Smart booking no modal de criação

**Testes (pytest):**
- [ ] Métricas calculadas com dados de seed
- [ ] Filtros por período corretos
- [ ] Smart booking retorna sugestões coerentes
- [ ] Gráficos renderizando

**Deploy AWS:**
- [ ] Lambda analytics-service deployada (Python 3.12 + Layer)

---

## Fase 10 — Segurança, WAF & Hardening

> **Meta:** Proteção completa para produção. Anti-DDoS, anti-bot, anti-fatura-explosiva.  
> **Estimativa:** 3-5 dias  
> **Depende de:** Todas as fases anteriores

### Escopo

**WAF:** Rate limit (100 req/5min/IP), geo-blocking (Brasil), anti-bot, SQL injection, XSS.

**Anti-contas-fantasmas:** Captcha (Turnstile/reCAPTCHA v3) no signup e booking, validação de email obrigatória.

**Headers de segurança:** CSP, HSTS, X-Content-Type-Options, X-Frame-Options, Referrer-Policy, Permissions-Policy, CORS estrito.

**Proteção financeira:** AWS Budgets (50%/80%/100% de R$300), Reserved Concurrency (20/Lambda), Aurora MaxACU 4.0, Lambda timeout 30s, memory 256-512MB.

**Secrets:** Tudo no Secrets Manager, zero SK_ nos bundles Angular, rotação automática.

**Upload de fotos:** S3 bucket, validação de tipo/tamanho (python-magic), CloudFront URL.

**Tarefas agendadas:** auto-status-transition, revert-pending-cancellations, send-appointment-reminders, rate-limit-cleanup, appointments-retrospective (via EventBridge).

### ✅ Checklist — Fase 10

**WAF:**
- [ ] AWS WAF ativado no API Gateway
- [ ] Rate limiting configurado (100 req/5min/IP)
- [ ] Geo-blocking (Brasil)
- [ ] Anti-bot rules
- [ ] SQL Injection managed rules
- [ ] XSS managed rules

**Anti-contas-fantasmas:**
- [ ] Captcha no signup do Dashboard
- [ ] Captcha no booking público do Portal
- [ ] Validação de email (OTP) obrigatória
- [ ] Rate limiting específico para `/auth/signup`

**Headers de segurança:**
- [ ] CSP configurado
- [ ] HSTS configurado
- [ ] X-Content-Type-Options: nosniff
- [ ] X-Frame-Options: DENY
- [ ] Referrer-Policy configurado
- [ ] Permissions-Policy configurado
- [ ] CORS estrito (apenas domínios oficiais)
- [ ] Score A+ no securityheaders.com

**Proteção financeira:**
- [ ] AWS Budgets alertas em 50%, 80%, 100% (R$300/mês)
- [ ] Reserved Concurrency (20/Lambda)
- [ ] Aurora MaxACU = 4.0 confirmado
- [ ] Lambda timeout = 30s
- [ ] Lambda memory = 256-512MB

**Secrets:**
- [ ] Todas as chaves no Secrets Manager
- [ ] Zero secrets nos bundles Angular (`grep -r "sk_" dist/`)
- [ ] Rotação automática configurada

**Upload de fotos:**
- [ ] POST `/photo-upload` (multipart/form-data — python-multipart)
- [ ] S3 bucket configurado via SST
- [ ] Validação de tipo (imagens — python-magic) e tamanho (5MB)
- [ ] CloudFront URL para servir fotos

**Tarefas agendadas:**
- [ ] auto-status-transition implementada
- [ ] revert-pending-cancellations implementada
- [ ] send-appointment-reminders implementada
- [ ] rate-limit-cleanup implementada
- [ ] appointments-retrospective implementada
- [ ] EventBridge rules configuradas

**Testes de carga e segurança:**
- [ ] Teste de carga com Locust (100 usuários simultâneos — Python nativo)
- [ ] WAF bloqueia requests excessivos
- [ ] Aurora não excede MaxACU
- [ ] Lambdas não excedem Reserved Concurrency
- [ ] OWASP Top 10 verificado

---

## Mapa de Dependências entre Fases

```
Fase 0: Setup Ambiente
    │
    └─→ Fase 1: Auth + Signup
            │
            └─→ Fase 2: Barbershop + Onboarding
                    │
                    ├─→ Fase 3: Staff & Services
                    │       │
                    │       └─→ Fase 4: Availability
                    │               │
                    │               └─→ Fase 5: Appointments (Staff)
                    │                       │
                    │                       ├─→ Fase 6: Portal Público
                    │                       ├─→ Fase 8: Notifications
                    │                       └─→ Fase 9: Analytics & AI
                    │
                    └─→ Fase 7: Subscriptions & Stripe ← (paralelo a 3-6)

Fase 10: Segurança & Hardening ← (após todas as fases)
```

> **Execução paralela possível:** Fases 7, 8 e 9 podem ser desenvolvidas em paralelo após suas dependências.

---

## Mitigação de Riscos & Proteção Financeira

### Riscos Técnicos

| Risco | Mitigação |
|---|---|
| Cold start das Lambdas Python | Provisioned Concurrency para funções críticas (auth, booking); uso de `mangum` otimizado |
| Tamanho do pacote Lambda Python | Lambda Layer para shared; dependências enxutas no `requirements.txt` |
| Conexões excessivas ao Aurora | Connection pooling via RDS Proxy + SQLAlchemy pool config |
| Fatura AWS explosiva | Budgets + Reserved Concurrency + MaxACU teto |
| Lock-in no Cognito | Auth adapter pattern (troca com 1 mudança de Provider) |
| Lock-in no SST | SST expõe CDK por baixo; migração para CDK/Terraform possível |
| Perda de dados | Aurora backups automáticos + Point-in-time recovery |
| Código duplicado entre Lambdas | `hairdule-shared` Lambda Layer compartilhada |

### Riscos de Negócio

| Risco | Mitigação |
|---|---|
| Contas fantasmas inflando custos | Captcha + validação de email + rate limiting |
| Abuso de booking público | Rate limit por IP + Turnstile + validação de telefone BR |
| DDoS | WAF + CloudFront (absorve tráfego na borda) |
| Vazamento de PII (LGPD) | Views mascaradas + autorização na aplicação + audit logs |

---

## Progresso Geral

| Fase | Descrição | Status |
|---|---|---|
| 0 | Setup Ambiente | ⬜ Pendente |
| 1 | Auth + Signup | ⬜ Pendente |
| 2 | Barbershop + Onboarding | ⬜ Pendente |
| 3 | Staff & Services | ⬜ Pendente |
| 4 | Availability | ⬜ Pendente |
| 5 | Appointments | ⬜ Pendente |
| 6 | Portal Público | ⬜ Pendente |
| 7 | Subscriptions & Stripe | ⬜ Pendente |
| 8 | Notifications & Push | ⬜ Pendente |
| 9 | Analytics & AI | ⬜ Pendente |
| 10 | Segurança & Hardening | ⬜ Pendente |

> **Próximo passo:** Executar Fase 0 — Setup do Ambiente de Desenvolvimento.
