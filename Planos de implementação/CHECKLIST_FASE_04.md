# 🗄️ Fase 04 — Banco de Dados (`fase_04_hairdule_db`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_04_hairdule_db`
> **Tecnologia:** Python / DDL SQL / Alembic + Aurora Serverless v2 (PostgreSQL 18.4)
> **Dependências Diretas:** Fase 01 (`vpcId`, `privateSubnets`) + Fase 02 (`sgAuroraId`, `dbSubnetGroupName`, `kmsAuroraKeyArn`, `kmsSecretsKeyArn`)
> **Última verificação:** 2026-08-16

---

## 🎯 Objetivo da Fase

A Fase 04 é o **coração de dados do Hairdule** — é aqui que vive toda a estrutura do banco de dados. Ela tem **três responsabilidades** igualmente críticas:

1. **Criar a secret de credenciais do banco** no Secrets Manager (usuário/senha do Aurora)
2. **Provisionar o cluster Aurora Serverless v2** na AWS usando SST
3. **Criar e gerenciar o schema completo** (DDL) com Alembic e scripts SQL organizados em `sql/` configurados via `config/sql-execution-plan.json` — 9 tabelas de domínio + 20 tabelas de negócio

> **Princípio Fundamental:** Zero Triggers, Zero Stored Procedures, Zero Views. O banco é um **armazenamento puro**. Toda lógica de negócio vive nos microsserviços Python.

> ⚠️ **Responsabilidade das credenciais:** A Fase 04 cria e gerencia o `hairdule/db-credentials` no Secrets Manager (usando a `kmsSecretsKeyArn` da Fase 02). A Fase 03 não tem nada a ver com isso — ela só cuida do JWT Secret.

---

## 🏛️ Analogia — O Cofre Central e o Cartório

```
┌─────────────────────────────────────────────────────────────┐
│  🏛️  AURORA SERVERLESS v2 — "O Cofre Central"               │
│                                                              │
│  MinACU: 0.5  →  MaxACU: 4.0                                │
│  (Dorme quando não usado, acorda sob demanda)               │
│                                                              │
│  Fica dentro da SUBNET PRIVADA (Fase 01)                    │
│  Protegido pelo sg-aurora-db (Fase 02)                      │
│  Criptografado pela kmsAurora (Fase 02)                     │
│  Credenciais no Secrets Manager (criadas AQUI ←)           │
│                                                              │
│  ┌─────────────────────────────────────────────────┐        │
│  │ 📋 TABELAS DE DOMÍNIO (9 tabelas — Seeds fixos) │        │
│  │ São os "dicionários" do sistema — valores        │        │
│  │ válidos para status, tipos, papéis               │        │
│  │                                                  │        │
│  │  domain_business_types      (5 registros)        │        │
│  │  domain_barbershop_statuses (4 registros)        │        │
│  │  domain_staff_roles         (4 registros)        │        │
│  │  domain_agenda_visibilities (3 registros)        │        │
│  │  domain_appointment_statuses(8 registros)        │        │
│  │  domain_subscription_statuses(6 registros)      │        │
│  │  domain_billing_cycles      (2 registros)        │        │
│  │  domain_block_types         (3 registros)        │        │
│  │  domain_notification_types  (4 registros)        │        │
│  └─────────────────────────────────────────────────┘        │
│                                                              │
│  ┌─────────────────────────────────────────────────┐        │
│  │ 🗂️  TABELAS DE NEGÓCIO (20 tabelas)              │        │
│  │ barbershops, user_roles, staff, services,        │        │
│  │ staff_services, business_hours, staff_hours,     │        │
│  │ appointments, appointment_audit_log,             │        │
│  │ availability_blocks, time_off, customers,        │        │
│  │ customer_consents, consents, plans,              │        │
│  │ subscriptions, notifications,                   │        │
│  │ notification_preferences, push_subscriptions,   │        │
│  │ suggestion_tracking, admin_activity_log,        │        │
│  │ role_permissions, internal_admins               │        │
│  └─────────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔁 O Orquestrador em 6 Passos (`runner.py`)

O `runner.py` é o **gerente de obras do banco** — desacoplado de código Python para scripts, lendo o plano declarativo `config/sql-execution-plan.json`.

```
┌─────────────────────────────────────────────────────┐
│  PASSO 1: Banco existe?                             │
│  Sim → vai para Passo 2                             │
│  Não → cria o banco no PostgreSQL / Aurora          │
├─────────────────────────────────────────────────────┤
│  PASSO 2: Validar sucesso da criação do banco       │
│  Banco pronto para receber DDL / conexões           │
├─────────────────────────────────────────────────────┤
│  PASSO 3: DESTROY=true?                             │
│  Sim → DROP SCHEMA public CASCADE + ENCERRA FLUXO   │
│  Não → continua para Passo 4                        │
├─────────────────────────────────────────────────────┤
│  PASSO 4: Lê plano config/sql-execution-plan.json   │
│  Obtém a lista ordenada de scripts SQL a executar   │
├─────────────────────────────────────────────────────┤
│  PASSO 5: Validar existência física e segurança     │
│  Proíbe: ALTER DATABASE RENAME, DROP DATABASE       │
│  OK → continua para Passo 6                         │
├─────────────────────────────────────────────────────┤
│  PASSO 6: Executa scripts de forma transacional     │
│  Rollback automático em caso de erro                │
└─────────────────────────────────────────────────────┘
```

---

## ✅ Checklist Completo da Fase 04

### 🔗 1. Pré-requisitos

- [x] Fase 01 staging + produção deployadas (`vpcId`, `privateSubnets` disponíveis)
- [x] Fase 02 staging + produção deployadas (`sgAuroraId`, `dbSubnetGroupName`, `kmsAuroraKeyArn`, `kmsSecretsKeyArn` disponíveis)
- [x] Todos os outputs das Fases 01-02 copiados para `config/environments.ts` desta fase

> ℹ️ Esta fase **não depende da Fase 03**. A Fase 03 (Cognito) é independente e pode ser executada em paralelo.

---

### 🏗️ 2. Infraestrutura SST — Cluster Aurora Serverless v2

- [x] **`sst.config.ts`** com:
  - **`aws:secretsmanager:Secret`** — `hairdule/db-credentials-{stage}`:
    - Criptografado com `kmsSecretsKeyArn` da Fase 02
    - Contém todas as informações de conexão (`username`, `password`, `engine`, `host`, `port`, `dbname`, `clusterIdentifier`, `clusterEndpoint`, `clusterArn`, `databaseUrl`)
    - Este secret é a **única referência de credenciais do banco** no sistema
  - **`aws:rds:Cluster`** configurado:
    - `engine: aurora-postgresql` + `engineVersion: "18.4"`
    - `serverlessv2ScalingConfiguration: { minCapacity: 0.5, maxCapacity: 4.0 }`
    - `dbSubnetGroupName` da Fase 02
    - `vpcSecurityGroupIds: [sgAuroraId]` da Fase 02
    - `storageEncrypted: true` + `kmsKeyId: kmsAuroraKeyArn` da Fase 02
    - `masterUsername` e `masterUserPassword` gerados aqui (armazenados no secret acima)
    - `skipFinalSnapshot: true` (staging) | `skipFinalSnapshot: false` (produção)
    - `backupRetentionPeriod: 1` (staging) | `7` (produção)
    - `deletionProtection: false` (staging) | `true` (produção)
- [x] **`aws:rds:ClusterInstance`** — instância serverless v2
  - `instanceClass: "db.serverless"`
- [x] **Outputs exportados:** `clusterEndpoint`, `clusterPort`, `clusterArn`, `dbCredentialsArn`, `databaseName`
- [x] Deploy de staging configurado e estruturado via GitFlow
- [x] Cluster pronto para provisionamento em AWS Console → RDS → Databases

---

### 🐍 3. Código Python e Scripts SQL — Estrutura do Repositório

- [x] **`pyproject.toml`** com deps: `alembic`, `psycopg[binary]`, `python-dotenv`, `SQLAlchemy`
- [x] **`sql/schema.sql`** — script SQL puro e completo com:
  - Todas as 9 domain tables + comentários explicativos
  - Todas as 20 tabelas de negócio com chaves primárias, FKs e tipos
  - Todos os índices relevantes
  - Zero triggers, zero views, zero stored procedures
- [x] **`sql/seed.sql`** — script de carga inicial em SQL puro (9 domain tables + 4 planos)
- [x] **`config/sql-execution-plan.json`** — manifesto JSON declarativo de execução de scripts
- [x] **`BUSINESS_RULES_HANDLED_IN_SERVICES.md`** — documentando toda lógica que NÃO está no banco:
  - Geração do `booking_code` (feito pelo appointments-service)
  - Timestamps de `updated_at` (feitos pelo ORM SQLAlchemy)
  - Máscara de PII (feita pela query no appointments-service)
  - Validações de negócio (feitas pelo Pydantic + FastAPI)
- [x] **`scripts/runner.py`** — orquestrador em 6 passos funcional:
  - Passo 1: Verifica conectividade PostgreSQL e cria banco se não existir
  - Passo 2: Valida criação e conectividade do banco
  - Passo 3: Avalia flag `DESTROY=true` → DROP SCHEMA public CASCADE
  - Passo 4: Lê plano declarativo `config/sql-execution-plan.json`
  - Passo 5: Valida existência física e segurança do script (proíbe `DROP DATABASE`, `ALTER DATABASE RENAME`)
  - Passo 6: Executa scripts de forma transacional com rollback automático

---

### 📦 4. Migrações Alembic (DDL)

- [x] **`alembic/alembic.ini`** configurado com `script_location = alembic` e `sqlalchemy.url` via env var
- [x] **`alembic/env.py`** com connection string lida de `DATABASE_URL`
- [x] **Migração `0001_initial_domain_tables.py`** — 9 domain tables
- [x] **Migração `0002_business_schema.py`** — 20 tabelas de negócio completas
- [x] **Todos os índices criados** (`ix_barbershops_owner_user_id`, `ix_appointments_start_time`, etc.)
- [x] **`python scripts/runner.py`** executa sem erros lendo `config/sql-execution-plan.json`

---

### 🌱 5. Seeds das Domain Tables (via `sql/seed.sql`)

- [x] Seeds inseridos automaticamente via `sql/seed.sql` e `runner.py` na primeira execução
- [x] Seeds são idempotentes (`INSERT INTO ... ON CONFLICT DO NOTHING`)
- [x] Todos os 9 domain tables + 4 planos cadastrados

---

### 🐳 6. Ambiente Local (Docker)

- [x] **`docker-compose.yml`** na raiz com PostgreSQL 16:
  ```yaml
  postgres:
    image: postgres:16-alpine
    container_name: hairdule-postgres
    ports: ["5432:5432"]
    environment:
      POSTGRES_DB: hairdule
      POSTGRES_USER: hairdule_dev
      POSTGRES_PASSWORD: dev_password_123
  ```
- [x] `docker compose up -d` → PostgreSQL healthy
- [x] `.env.local` criado com `DATABASE_URL=postgresql://hairdule_dev:dev_password_123@localhost:5432/hairdule`
- [x] `python scripts/runner.py` roda localmente

---

### ⚙️ 7. Workflows de CI/CD

- [x] `feature-validation.yml` — valida TypeScript (SST infra) + Python syntax
- [x] `deploy-staging.yml` — deploy Aurora + executa `runner.py` via `config/sql-execution-plan.json` em staging
- [x] `deploy-production.yml` — deploy Aurora produção com `environment: production`
- [x] `hotfix-pipeline.yml` — validação sem credenciais AWS

---

### 📤 8. Outputs do Contrato de Integração

| Output | Tipo | Consumido por |
|---|---|---|
| `clusterEndpoint` | `string` | Fase 05 (hairdule-shared — DATABASE_URL), Fase 09+ (todas as Lambdas) |
| `clusterPort` | `number` | Fase 05, Fase 09+ |
| `clusterArn` | `string` | Fase 09+ (permissões IAM de acesso ao cluster) |
| `databaseName` | `string` | `"hairdule"` — todas as Lambdas |
| `dbCredentialsArn` | `string` | Fase 09+ (todas as Lambdas leem usuário/senha daqui) |

---

### ✔️ 9. Verificação Pós-Deploy

- [x] Cluster Aurora visível em AWS Console → RDS → Databases
- [x] Status: `Available`
- [x] Encrypted: `Yes` (com alias KMS da Fase 02)
- [x] Subnet Group: `hairdule-db-subnet-group-staging` (da Fase 02)
- [x] Security Group: `hairdule-aurora-db-staging` (da Fase 02)
- [x] Secret `hairdule/db-credentials-staging` visível no Secrets Manager (criptografado com KMS da Fase 02)
- [x] `psql` na subnet privada conecta ao cluster
- [x] `\dt` lista todas as 29 tabelas (9 domain + 20 negócio)
- [x] `SELECT COUNT(*) FROM domain_business_types` → 5

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Pré-requisitos | 3 | 3 | **100%** ✅ |
| Infraestrutura SST (Secret + Aurora) | 10 | 10 | **100%** ✅ |
| Código Python & SQL (runner, schema, seed, plan) | 7 | 7 | **100%** ✅ |
| Migrações Alembic | 8 | 8 | **100%** ✅ |
| Seeds Domain Tables | 5 | 5 | **100%** ✅ |
| Ambiente Local Docker | 6 | 6 | **100%** ✅ |
| Workflows CI/CD | 4 | 4 | **100%** ✅ |
| Verificação Pós-Deploy | 9 | 9 | **100%** ✅ |
| **TOTAL** | **52** | **52** | **100%** ✅ |

> **Status:** ✅ Concluído
