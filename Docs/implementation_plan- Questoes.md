# Hairdule 2.0 — Plano de Atualização Arquitetural

> **Objetivo:** Incorporar as 5 mudanças arquiteturais aprovadas ao [implementation_plan.md](file:///d:/Documentos/Projetos/Hairdule/Hairdule%202.0/implementation_plan.md) existente.

---

## Resumo das Mudanças

As 5 alterações impactam principalmente as **Seções 4 (Estrutura de Repositórios)** e **Fase 0 (Setup)** do plano atual. A tabela abaixo mapeia cada mudança ao impacto no plano:

| # | Mudança | Seções Impactadas | Tipo de Alteração |
|---|---------|-------------------|-------------------|
| 1 | Regra de execução pausada + diretório `Projeto novo` | Cabeçalho (L1-8) | ✅ Já presente no cabeçalho |
| 2 | Isolamento `hairdule-db` | Seção 4.1 (`hairdule-shared`), Fase 0, Fase 1-9 (checklists) | 🔴 **Grande** — Reestruturação completa |
| 3 | Domain tables em vez de ENUMs | Seção 4.1 (models), Fase 0, Fase 1 | 🔴 **Grande** — Nova abordagem de dados |
| 4 | Infra modularizada (`hairdule-infra-*`) | Seção 4.2 (`hairdule-infra`) | 🟡 **Médio** — Divisão em 4 repos |
| 5 | Runner 3 etapas no `hairdule-db` | Seção 4.1 (novo), Fase 0 | 🟡 **Médio** — Novo componente |

---

## Detalhamento das Mudanças

### 📌 Mudança 1 — Regra de Execução (✅ Já Implementada)

O cabeçalho do plano já contém:
```
> **Regra de Execução:** Nenhuma caixa de seleção (`- [ ]`) deve ser marcada (`- [x]`) sem a aprovação prévia e explícita do usuário.
> **Diretório de Destino:** `Projeto novo`
```

Os arquivos [.env.example](file:///d:/Documentos/Projetos/Hairdule/Hairdule%202.0/Projeto%20novo/.env.example), [.env.local](file:///d:/Documentos/Projetos/Hairdule/Hairdule%202.0/Projeto%20novo/.env.local) e [docker-compose.yml](file:///d:/Documentos/Projetos/Hairdule/Hairdule%202.0/Projeto%20novo/docker-compose.yml) já estão em `Projeto novo`.

**Ação necessária:** Nenhuma.

---

### 📌 Mudança 2 — Isolamento do `hairdule-db`

> [!IMPORTANT]
> Esta é a mudança mais impactante. Ela altera fundamentalmente a separação de responsabilidades entre o banco de dados e o código de aplicação.

#### Estado Atual no Plano
- O `hairdule-shared` (Seção 4.1, linhas 224-330) contém **tudo**: models SQLAlchemy, schemas Pydantic, migrações Alembic, auth, middleware, utils.
- Cada checklist de Fase menciona "Migração Alembic gerada e aplicada" dentro do contexto do `hairdule-shared`.

#### Estado Desejado
```
hairdule-db/          ← NOVO REPOSITÓRIO (DDL only)
├── alembic/
│   ├── alembic.ini
│   ├── env.py
│   └── versions/
│       └── 0001_init_domain_tables_and_core.py
├── scripts/
│   ├── runner.py     ← Orquestrador 3 etapas (Mudança 5)
│   └── seed.py       ← Seeds das domain tables
├── pyproject.toml
└── README.md

hairdule-shared/      ← REFATORADO (DML only)
├── src/hairdule_shared/
│   ├── database/
│   │   ├── models/   ← ORM mappings (SQLAlchemy) — SOMENTE LEITURA/ESCRITA
│   │   ├── client.py
│   │   ├── session.py
│   │   └── base.py
│   ├── schemas/      ← Pydantic v2
│   ├── auth/
│   ├── errors/
│   ├── middleware/
│   ├── types/
│   └── utils/
├── pyproject.toml
└── README.md
```

#### Edições Necessárias no Plano

**Seção 4 — Mapa de Repositórios (L206-221):**
- Adicionar linha para `hairdule-db` (novo repo #2, entre `hairdule-shared` e `hairdule-infra-auth`)
- Renumerar repositórios

**Seção 4.1 — `hairdule-shared` (L224-330):**
- Remover toda a pasta `alembic/` da árvore de diretórios
- Remover `scripts/seed.py` e `scripts/migrate.py`
- Manter: `database/`, `schemas/`, `auth/`, `errors/`, `middleware/`, `types/`, `utils/`
- Adicionar nota: "O `hairdule-shared` NÃO pode alterar estrutura do banco. Somente operações CRUD."

**Nova Seção 4.1b — `hairdule-db`:**
- Criar seção completa com árvore de diretórios
- Documentar o `runner.py` (Mudança 5)
- Documentar as seeds das domain tables (Mudança 3)

**Fases 0-9 — Checklists:**
- Mudar "Migração Alembic gerada e aplicada" → "Migração DDL criada no `hairdule-db` e aplicada via `runner.py`"
- Mover referências de Alembic do `hairdule-shared` para `hairdule-db`

---

### 📌 Mudança 3 — Domain Tables em vez de ENUMs

#### Estado Atual no Plano
- Fase 1 (L846): `ENUMs: business_type, barbershop_status, staff_role, agenda_visibility`
- Fase 5 (L1172): `ENUM: appointment_status`
- Fase 7 (L1357): `ENUMs: subscription_status, billing_cycle`
- Seção 4.1 (L244): `models/enums.py`

#### Estado Desejado — 9 Domain Tables

| Tabela | Registros (Seed) |
|--------|------------------|
| `domain_business_types` | Barbearia, Salão, Spa, Esmalteria, Outro |
| `domain_barbershop_statuses` | Em Cadastro, Ativo, Inativo, Suspenso |
| `domain_staff_roles` | Dono, Gerente, Barbeiro, Recepcionista |
| `domain_agenda_visibilities` | Própria, Leitura Time, Acesso Total |
| `domain_appointment_statuses` | Agendado, Confirmado, Em Atendimento, Finalizado, Cancelado Cliente, Cancelado Barbearia, No-Show, Remarcado |
| `domain_subscription_statuses` | Trial, Ativo, Atenção, Carência, Bloqueado, Cancelado |
| `domain_billing_cycles` | Mensal, Anual |
| `domain_block_types` | Pontual, Recorrente, Férias |
| `domain_notification_types` | Novo Agendamento, Cancelamento, Lembrete, Sistema |

**Estrutura padrão de cada tabela:**
```sql
CREATE TABLE domain_<name> (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,    -- Chave programática (ex: 'BARBERSHOP')
    name VARCHAR(100) NOT NULL,          -- Nome amigável (ex: 'Barbearia')
    description TEXT,                    -- Descrição opcional
    display_order INTEGER DEFAULT 0,     -- Ordem de exibição no frontend
    is_active BOOLEAN DEFAULT true       -- Soft-delete
);
```

#### Edições Necessárias no Plano

**Seção 4.1 — `hairdule-shared`:**
- `models/enums.py` → Renomear para `models/domain.py` (ORM mappings para as domain tables)
- As FKs nas tabelas de negócio (`barbershops.business_type_id` → `domain_business_types.id`) substituem os ENUMs nativos

**Fase 0 — Checklist:**
- Adicionar: "Domain tables criadas via migração inicial no `hairdule-db`"
- Adicionar: "Seeds populadas automaticamente via `runner.py`"

**Fase 1 — Checklist (L898-903):**
- Mudar: "Model SQLAlchemy para ENUMs" → "Models SQLAlchemy para domain tables (ORM read-only no `hairdule-shared`)"
- Remover referências a ENUMs nativos do PostgreSQL

**Fases 5, 7:**
- Mesma substituição de ENUMs por domain tables

---

### 📌 Mudança 4 — Infraestrutura Modularizada

#### Estado Atual no Plano
- Seção 4.2 (L349-375): Um único `hairdule-infra/` com todos os recursos AWS

#### Estado Desejado — 4 Repositórios

| Repositório | Responsabilidade |
|-------------|------------------|
| `hairdule-infra-auth` | Cognito User Pools, Clients, Triggers |
| `hairdule-infra-api` | API Gateway v2, AWS WAF, CORS, Custom Domains |
| `hairdule-infra-storage` | Buckets S3, CloudFront CDN, OAC |
| `hairdule-infra-events` | EventBridge, Scheduler, Cron Jobs |

#### Edições Necessárias no Plano

**Seção 4 — Mapa de Repositórios:**
- Substituir `hairdule-infra` por 4 linhas separadas
- Renumerar repositórios

**Seção 4.2:**
- Reescrever completamente com 4 árvores de diretórios separadas

**Fases — Deploy AWS:**
- Atualizar referências de "SST deploy" para o repo de infra correto

---

### 📌 Mudança 5 — Runner 3 Etapas no `hairdule-db`

#### Componente Novo: `runner.py`

```python
# hairdule-db/scripts/runner.py
# Orquestrador declarativo de 3 etapas:
#
# Etapa 1: CHECK/CREATE
#   - Verifica se o banco existe (pg_isready / SELECT 1)
#   - Se não existe → cria banco + schema
#   - Se existe → pula para Etapa 2
#
# Etapa 2: VALIDATE DESTROY
#   - Se destroy=true E banco existe → DROP ALL (com confirmação)
#   - Se destroy=false → pula para Etapa 3
#
# Etapa 3: EXECUTE SCRIPTS
#   - Executa 1..N scripts SQL/Alembic configurados por parâmetro
#   - Equivale a: alembic upgrade head + seed scripts
```

#### Edições Necessárias no Plano

**Nova Seção 4.1b — `hairdule-db`:**
- Documentar o `runner.py` com os 3 estágios
- Exemplo de invocação: `python scripts/runner.py --destroy=false --scripts="alembic:head,seed:all"`

**Fase 0 — Checklist:**
- Adicionar: "`runner.py` funcional com as 3 etapas"

---

## Proposta de Execução

> [!IMPORTANT]
> Todas as edições serão feitas **diretamente no [implementation_plan.md](file:///d:/Documentos/Projetos/Hairdule/Hairdule%202.0/implementation_plan.md)** existente.

### Ordem de Edição

1. **Seção 4 — Mapa de Repositórios** → Adicionar `hairdule-db`, dividir `hairdule-infra` em 4
2. **Seção 4.1 — `hairdule-shared`** → Remover Alembic, adicionar nota de restrição DML
3. **Nova Seção 4.1b — `hairdule-db`** → Criar do zero (árvore, runner, seeds)
4. **Seção 4.2 — `hairdule-infra`** → Dividir em 4 subsections
5. **Seção 4.1 models** → `enums.py` → `domain.py`, domain tables em vez de ENUMs
6. **Fase 0 — Checklist** → Adicionar itens de `hairdule-db`, runner, domain tables
7. **Fases 1-9 — Checklists** → Atualizar referências de Alembic e ENUMs

### Estimativa

~15-20 edições pontuais no arquivo. Nenhuma alteração de lógica de negócio, apenas reestruturação arquitetural.

## Open Questions

> [!WARNING]
> Preciso da sua confirmação antes de editar o plano.

1. **Sobre o `hairdule-infra-*`:** O plano atual usa **SST v4** como IaC. Os 4 repos de infra continuam usando SST, ou algum deles usa **Terraform/CDK puro**?

2. **Sobre o `hairdule-db`:** O `runner.py` será invocado manualmente (`python scripts/runner.py`) ou será parte de um pipeline CI/CD (GitHub Actions)?

3. **Sobre as domain tables:** As FKs nas tabelas de negócio (ex: `barbershops.business_type_id`) devem ter `ON DELETE RESTRICT` (impedir exclusão de domínio em uso) ou `ON DELETE SET NULL`?

4. **Sobre o `hairdule-shared`:** O arquivo `models/enums.py` atual deve ser renomeado para `models/domain.py` ou você prefere outro nome?
