# 🗄️ Fase 04.1 — Esteira Genérica de Execução de Scripts SQL no RDS (`fase_04_1_hairdule_db_runner`)
## Checklist de Execução — Status Completo

> **Repositório:** `https://github.com/MarquesCleitonOrg/fase_04_1_hairdule_db_runner`
> **Tecnologia:** Python 3.11 (`psycopg3`, `SQLAlchemy`, `boto3`) + SST v4 (`sst@4.17.1`) + AWS Lambda VPC (PostgreSQL 18.4)
> **Dependências Diretas:** Fase 01 (`vpcId`, `privateSubnets`) + Fase 02 (`sgAuroraId`, `kmsSecretsKeyArn`) + Fase 04 (`clusterEndpoint`, `dbCredentialsArn`, `databaseName`)
> **Última verificação:** 2026-08-16

---

## 🎯 Objetivo da Fase

A **Fase 04.1** é o **motor de execução contínua de banco de dados do Hairdule 2.0**. Enquanto a Fase 04 provisiona a infraestrutura do cluster Aurora Serverless v2 e os segredos mestres, a Fase 04.1 desacopla completamente o ciclo de vida do código SQL da infraestrutura IaC.

Suas responsabilidades são:

1. **Execução Sequencial Estrita:** Executar scripts SQL rigorosamente na ordem definida no arquivo declarativo `config/sql-execution-plan.json`.
2. **Auto-Provisionamento do Ledger (`_hairdule_migration_ledger`):** Criar e gerenciar de forma transparente a tabela interna de auditoria e rastreabilidade para registrar checksum SHA-256, tempo de execução, autor e status de cada script.
3. **Idempotência Inteligente:**
   - **`type: "ONCE"` (Padrão):** Se o script já foi executado com sucesso e o hash é o mesmo, pula a execução. Se o hash foi alterado indevidamente no repositório, emite alerta de Drift.
   - **`type: "REPEATABLE"`:** Executa toda vez que o hash mudar ou a cada execução (ideal para seeds de domínio com `ON CONFLICT DO UPDATE`).
4. **Segurança Transacional:** Bloco atômico (`BEGIN ... COMMIT`) com **rollback automático** em caso de qualquer falha.
5. **Acesso Seguro a Subnets Privadas:** Conexão nativa através de uma função **AWS Lambda VPC DB Executor** que roda dentro da VPC da Fase 01, recupera credenciais do Secrets Manager (criptografadas via KMS da Fase 02) e executa no Aurora PostgreSQL sem expor credenciais ou portas à internet pública.

---

## 🏛️ Analogia — O Notário e o Gerente de Obras

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      🏢 O GERENTE DE OBRAS E O NOTÁRIO                  │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────┐        │
│  │ 📋 O PLANO DE EXECUÇÃO (`config/sql-execution-plan.json`)    │        │
│  │ A planta da obra contendo a ordem cronológica exata dos     │        │
│  │ passos a serem realizados.                                  │        │
│  └──────────────────────────────┬──────────────────────────────┘        │
│                                 │                                       │
│                                 ▼                                       │
│  ┌─────────────────────────────────────────────────────────────┐        │
│  │ 📜 O CARTÓRIO OFICIAL (`_hairdule_migration_ledger`)        │        │
│  │ Livro-razão no PostgreSQL onde cada script aplicado tem seu  │        │
│  │ hash SHA-256 e carimbo de data/hora registrados para sempre.│        │
│  └──────────────────────────────┬──────────────────────────────┘        │
│                                 │                                       │
│                                 ▼                                       │
│  ┌─────────────────────────────────────────────────────────────┐        │
│  │ ⚡ O EXECUTOR BLINDADO (Lambda VPC na Subnet Privada)        │        │
│  │ Busca a chave no cofre (Secrets Manager), entra na alameda  │        │
│  │ reservada (VPC) e aplica as alterações em transação única.  │        │
│  └─────────────────────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔁 Fluxo de Decisão do Runner

```
             Lê `config/sql-execution-plan.json` (Ordem Estrita 1..N)
                                    │
                                    ▼
       ┌─────────────────────────────────────────────────────────────┐
       │ Passo 0: Garante `_hairdule_migration_ledger` (IF NOT EXISTS)│
       └────────────────────────────┬────────────────────────────────┘
                                    │
                  Para cada script na ordem do JSON:
                                    │
                                    ▼
          ┌──────────────────────────────────────────────────┐
          │  Script já possui registro 'SUCCESS' no Ledger?  │
          └─────────────────────────┬────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │ SIM                           │ NÃO
                    ▼                               ▼
        ┌───────────────────────┐       ┌────────────────────────┐
        │ Tipo = 'REPEATABLE'   │       │ Valida segurança       │
        │ OU Hash alterado?     │       │ (Sem DROP DATABASE)    │
        └───────────┬───────────┘       └───────────┬────────────┘
                    │                               │
          ┌─────────┴─────────┐                     │
          │ SIM               │ NÃO (ONCE idêntico) │
          ▼                   ▼                     │
 ┌─────────────────┐ ┌──────────────────┐           │
 │ Executa e grava │ │ Pula com log     │           │
 │ novo histórico  │ │ de idempotência  │           │
 └────────┬────────┘ └──────────────────┘           │
          │                                         │
          └──────────────────┬──────────────────────┘
                             │
                             ▼
             ┌───────────────────────────────┐
             │ Transação: COMMIT se OK       │
             │            ROLLBACK se Erro   │
             └───────────────────────────────┘
```

---

## ✅ Checklist Completo da Fase 04.1

### 🔗 1. Pré-requisitos e Contratos

- [x] Fase 01 staging + produção (`vpcId`, `privateSubnets`)
- [x] Fase 02 staging + produção (`sgAuroraId`, `kmsSecretsKeyArn`)
- [x] Fase 04 staging + produção (`clusterEndpoint`, `dbCredentialsArn`, `databaseName`)
- [x] Configuração agnóstica centralizada em `config/environments.ts` com JSDoc completo

---

### 🏗️ 2. Infraestrutura SST — VPC Lambda DB Executor

- [x] **`sst.config.ts`** configurado:
  - Criação da Lambda `HairduleDbExecutorLambda` em Python 3.11 / NodeJS.
  - VPC Attachment: `vpcId`, `privateSubnets` (Fase 01) e `securityGroupIds: [sgAuroraId]` (Fase 02).
  - IAM Role de Menor Privilégio:
    - `secretsmanager:GetSecretValue` no `dbCredentialsArn` (Fase 04).
    - `kms:Decrypt` no `kmsSecretsKeyArn` (Fase 02).
  - Timeout estendido (15 minutos) e memória adequada para migrações pesadas.
- [x] Outputs exportados: `executorLambdaArn`, `executorLambdaName`.

---

### 🐍 3. Motor de Execução Python (`src/` e `scripts/`)

- [x] **`pyproject.toml`** configurado com `psycopg[binary]`, `SQLAlchemy`, `boto3`, `pydantic`.
- [x] **`src/ledger.py`**:
  - `bootstrap_ledger()`: Criação transparente de `_hairdule_migration_ledger` e seus índices.
  - `calculate_checksum()`: Hash SHA-256 do arquivo SQL.
  - `get_last_execution()`: Consulta status e checksum anterior.
  - `record_execution()`: Gravação de log com duração, autor, status e stage.
- [x] **`src/runner_core.py`**:
  - Leitura do `sql-execution-plan.json` mantendo a ordem estrita do array.
  - Assumir `type: "ONCE"` por padrão quando omitido.
  - Suporte a `type: "REPEATABLE"`.
  - Validação de segurança (proibição de `DROP DATABASE`, `ALTER DATABASE RENAME`).
  - Execução atômica em transação única com rollback automático.
- [x] **`src/lambda_handler.py`**:
  - Handler AWS Lambda para execução acionada via GitHub Actions ou AWS CLI.
- [x] **`scripts/local_runner.py`**:
  - CLI local para execução e testes via `DATABASE_URL` (Docker).

---

### 📜 4. Organização dos Scripts SQL (`sql/`)

- [x] `sql/01_schemas/` — DDLs estruturais iniciais.
- [x] `sql/02_seeds/` — Seeds idempotentes de tabelas de domínio (`ON CONFLICT DO UPDATE / DO NOTHING`).
- [x] `sql/03_migrations/` — Migrações incrementais versionadas.
- [x] `sql/04_patches/` — Patches e manutenções operacionais.
- [x] `config/sql-execution-plan.json` — Manifesto declarativo padrão.

---

### 🐳 5. Ambiente Local (Docker)

- [x] **`docker-compose.yml`** com PostgreSQL 16:
  ```yaml
  postgres:
    image: postgres:16-alpine
    container_name: hairdule-db-runner-postgres
    ports: ["5432:5432"]
    environment:
      POSTGRES_DB: hairdule
      POSTGRES_USER: hairdule_dev
      POSTGRES_PASSWORD: dev_password_123
  ```
- [x] `.env.local` configurado com `DATABASE_URL`.
- [x] Execução local bem-sucedida via `python scripts/local_runner.py`.

---

### ⚙️ 6. Workflows de CI/CD (GitHub Actions)

- [x] `feature-validation.yml` — Validação estática, lint Python/TypeScript, validação do JSON e arquivos SQL.
- [x] `deploy-staging.yml` — Deploy/update da Lambda VPC + execução do plano no RDS Staging + Tag + PR Produção.
- [x] `deploy-production.yml` — Execução no RDS Produção com gate de aprovação do environment.
- [x] `manual-sql-dispatch.yml` — Disparo manual com parâmetros de stage e caminho do plano.

---

### 📤 7. Outputs do Contrato de Integração

| Output | Tipo | Consumido por |
|---|---|---|
| `executorLambdaArn` | `string` | Fases seguintes e automações operacionais |
| `executorLambdaName` | `string` | GitHub Actions (`aws lambda invoke`) |
| `ledgerTableName` | `string` | `"_hairdule_migration_ledger"` (auditoria global) |

---

## 📈 Resumo de Progresso

| Categoria | Total de Itens | Concluídos | % |
|---|---|---|---|
| Pré-requisitos & Contratos | 4 | 4 | **100%** ✅ |
| Infraestrutura SST (VPC Lambda) | 6 | 6 | **100%** ✅ |
| Motor Python & Ledger | 5 | 5 | **100%** ✅ |
| Scripts SQL & Plano | 5 | 5 | **100%** ✅ |
| Ambiente Local Docker | 3 | 3 | **100%** ✅ |
| Workflows CI/CD | 4 | 4 | **100%** ✅ |
| **TOTAL** | **27** | **27** | **100%** ✅ |

> **Status:** ✅ Concluído (Código pronto, aguarda deploy na organização `MarquesCleitonOrg`)
