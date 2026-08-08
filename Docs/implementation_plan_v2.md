# Hairdule 2.0 — Plano de Implementação Completo (v2 Reestruturado)

> **Projeto:** Hairdule — SaaS de agendamentos online para estabelecimentos de beleza  
> **Arquitetura:** AWS Serverless (Lambda + Aurora PostgreSQL + CloudFront + Cognito + API Gateway)  
> **Stack:** Angular 18 · FastAPI · SQLAlchemy 2.0 · SST v4 · PostgreSQL 16  
> **Última atualização:** 2026-08-08  
> **Diretório de Destino:** `d:\Documentos\Projetos\Hairdule\Hairdule 2.0\Projeto novo`  
> **Regra de Execução:** Nenhuma caixa de seleção (`- [ ]`) deve ser marcada (`- [x]`) sem a aprovação prévia e explícita do usuário para cada ponto concluído.

---

## Índice

1. [Visão Geral da Arquitetura Reestruturada](#1-visão-geral-da-arquitetura-reestruturada)
2. [Stack Tecnológica Definitiva](#2-stack-tecnológica-definitiva)
3. [Estratégia de Desenvolvimento Local-First](#3-estratégia-de-desenvolvimento-local-first)
4. [Estrutura de Repositórios (17 Repositórios)](#4-estrutura-de-repositórios-17-repositórios)
5. [Arquitetura e Pipeline do Repositório do Banco (`hairdule-db`)](#5-arquitetura-e-pipeline-do-repositório-do-banco-hairdule-db)
6. [Tabelas de Domínio (Lookup Tables)](#6-tabelas-de-domínio-lookup-tables)
7. [Fase 0 — Setup do Ambiente de Desenvolvimento](#fase-0--setup-do-ambiente-de-desenvolvimento)
8. [Fase 1 — Auth Service + Cadastro (Signup)](#fase-1--auth-service--cadastro-signup)
9. [Fase 2 — Barbershop Service + Onboarding](#fase-2--barbershop-service--onboarding)
10. [Fase 3 — Staff & Services Management](#fase-3--staff--services-management)
11. [Fase 4 — Availability & Business Hours](#fase-4--availability--business-hours)
12. [Fase 5 — Appointments (Staff)](#fase-5--appointments-agendamentos-pelo-staff)
13. [Fase 6 — Portal Público (Booking Online)](#fase-6--portal-público-booking-online)
14. [Fase 7 — Subscriptions & Stripe](#fase-7--subscriptions--stripe)
15. [Fase 8 — Notifications & Push](#fase-8--notifications--push)
16. [Fase 9 — Analytics & AI](#fase-9--analytics--ai)
17. [Fase 10 — Segurança, WAF & Hardening](#fase-10--segurança-waf--hardening)
18. [Mapa de Dependências entre Fases](#mapa-de-dependências-entre-fases)
19. [Mitigação de Riscos & Proteção Financeira](#mitigação-de-riscos--proteção-financeira)
20. [Progresso Geral](#progresso-geral)

---

## 1. Visão Geral da Arquitetura Reestruturada

```
              +-------------------------------------------------------+
              |                    CLIENT BROWSER                      |
              +---------------------------+---------------------------+
                                          |
                               [ CloudFront CDN ] (hairdule-infra-storage)
                                          |
              +---------------------------+---------------------------+
              |        Angular Portal     |      Angular Dashboard    |
              |    (hairdule.com.br)       |    (app.hairdule.com.br)  |
              +---------------------------+---------------------------+
                                          |
                       [ AWS WAF + API Gateway v2 ] (hairdule-infra-api)
                                          |
         +--------------------------------+--------------------------------+
         |                                |                                |
  [ hairdule-auth ]            [ hairdule-barbershop ]         [ hairdule-appointments ]
  [ hairdule-staff ]           [ hairdule-services ]           [ hairdule-availability ]
  [ hairdule-subscriptions ]   [ hairdule-notifications ]      [ hairdule-analytics ]
   (Python 3.12 Lambdas)        (Python 3.12 Lambdas)           (Python 3.12 Lambdas)
         |                                |                                |
         +--------------------------------+--------------------------------+
                                          |
                              [ hairdule-shared ] (SDK Python DML)
                                          |
                      [ Aurora Serverless v2 / PostgreSQL 16 ]
                              (Gerenciado por hairdule-db)
```

Cada Lambda é um **microsserviço independente** com seu próprio repositório. As infraestruturas são separadas por **domínios de responsabilidade** (`hairdule-infra-*`), o esquema e migrações do banco de dados são isolados no repositório **`hairdule-db`**, e o código de aplicação reutilizável é mantido no **`hairdule-shared`** (Lambda Layer DML).

---

## 2. Stack Tecnológica Definitiva

| Camada | Tecnologia | Justificativa |
|---|---|---|
| **Frontend Framework** | Angular 18+ | Tipagem forte, standalone components, SSR |
| **UI Library** | Angular Material | Oficial, design system Google, bem integrado |
| **Backend Runtime** | AWS Lambda (Python 3.12) | Serverless, pay-per-use, auto-scaling |
| **HTTP Framework** | FastAPI + Mangum | Async nativo, OpenAPI Swagger automático, Pydantic v2 |
| **ORM & Database Driver** | SQLAlchemy 2.0 + psycopg3 | Type-safe, async/sync, alta performance para PostgreSQL |
| **Validação de Dados** | Pydantic v2 | Integrado ao FastAPI, alta performance (core em Rust) |
| **Banco de Dados** | Aurora Serverless v2 (PostgreSQL 16) | Escala automática, teto financeiro controlável (Min 0.5 ACU) |
| **Migrações DDL** | Alembic (Isolado no `hairdule-db`) | Gerenciamento centralizado de schema DDL e seeds de domínio |
| **Autenticação** | AWS Cognito (via adapter pattern) | User pools, 50k MAU grátis, integração WAF |
| **IaC (Infraestrutura)** | SST v4 (Serverless Stack) | TypeScript nativo, repositórios infra por domínio |
| **CDN & Storage** | CloudFront + S3 | Cache global, OAC, fotos de estabelecimentos e avatares |
| **CI/CD** | GitHub Actions | Workflows isolados por repositório |
| **Gerenciador de Pacotes Python** | `uv` | Otimizado, substitui pip/venv com alta velocidade |

---

## 3. Estratégia de Desenvolvimento Local-First

> **Filosofia:** Cada funcionalidade é construída e validada localmente **antes** de qualquer deploy na AWS. Serviços AWS que não podem rodar local são **virtualizados** com stubs/mocks em Docker.

| Serviço AWS | Emulação Local | Detalhes |
|---|---|---|
| **Aurora Serverless** | PostgreSQL 16 (Docker) | Executado via `hairdule-db` no contêiner local `hairdule-postgres` |
| **Cognito** | LocalStack + Auth Adapter | `IAuthProvider` com `CognitoAdapter` (prod) e `LocalAdapter` (dev) |
| **API Gateway** | Uvicorn local | Cada Lambda roda em sua porta dedicada com hot-reload |
| **S3** | LocalStack | Bucket local para upload e fotos |
| **Secrets Manager** | LocalStack + `.env.local` | Variáveis locais em dev, Secrets Manager em prod |
| **Stripe** | Stripe CLI | `stripe listen --forward-to localhost:3007/stripe/webhook` |
| **Lambda Layer** | `pip install -e ../hairdule-shared` | Editable install local — sem necessidade de build continuo |

---

## 4. Estrutura de Repositórios (17 Repositórios)

Cada componente do sistema possui seu **próprio repositório independente** no GitHub:

### 🔴 Repositórios de Infraestrutura & Banco de Dados (5 Repos)
1. **`hairdule-db`**: Schema do PostgreSQL, Runner de 6 Passos (`schema.sql` / Alembic DDL), Roles de Acesso (`hairdule_admin` vs `hairdule_app`), e Seeds de Domínio. Zero triggers/views.
2. **`hairdule-infra-auth`**: Configurações IaC do AWS Cognito User Pools, App Clients, Grupos de permissão e Auth Triggers.
3. **`hairdule-infra-api`**: Configurações IaC do AWS API Gateway v2 (HTTP API), AWS WAF (Rate Limiting, Anti-Bot, Geo-IP, SQLi/XSS), Domínios Customizados e CORS.
4. **`hairdule-infra-storage`**: Configurações IaC de Buckets AWS S3 (logos, banners, fotos), distribuições AWS CloudFront CDN e políticas Origin Access Control (OAC).
5. **`hairdule-infra-events`**: Configurações IaC do AWS EventBridge / Scheduler para cron jobs de fundo (auto-cancelamento, lembretes, rétrospectivas).

### 🟢 Repositório SDK Compartilhado (1 Repo)
6. **`hairdule-shared`**: Pacote Python (Lambda Layer) com Mapeamentos ORM SQLAlchemy (DML/CRUD), Schemas Pydantic v2, Auth Handler/Middleware, DTOs e Utilitários de Erros/Logs. *(Sem Alembic, sem permissão DDL)*.

### 🔵 Repositórios de Microsserviços Backend (9 Lambdas Python)
7. **`hairdule-auth-service`** (Porta 3001): Signup, Login, Password Reset, Refresh Tokens.
8. **`hairdule-barbershop-service`** (Porta 3002): Perfil da barbearia, Onboarding de 5 etapas.
9. **`hairdule-staff-service`** (Porta 3003): CRUD de profissionais, permissões e visabilidades.
10. **`hairdule-services-service`** (Porta 3004): CRUD de serviços, buffers, pausas e variabilidade.
11. **`hairdule-availability-service`** (Porta 3005): Horários de funcionamento, folgas e bloqueios.
12. **`hairdule-appointments-service`** (Porta 3006): Agendamentos, máquina de estados e audit log.
13. **`hairdule-subscriptions-service`** (Porta 3007): Assinaturas, Stripe Checkout, Webhooks.
14. **`hairdule-notifications-service`** (Porta 3008): Notificações in-app e WebPush VAPID.
15. **`hairdule-analytics-service`** (Porta 3009): Métricas financeiras e sugestões inteligentes AI.

### 🟡 Repositórios Frontend Angular (2 Repos)
16. **`hairdule-app-dashboard`** (Porta 4300): Angular 18 — Painel administrativo do estabelecimento.
17. **`hairdule-app`** (Porta 4200): Angular 18 (SSR) — Portal público de agendamentos para clientes.

---

## 5. Arquitetura e Pipeline do Repositório do Banco (`hairdule-db`)

O repositório **`hairdule-db`** funciona como um orquestrador declarativo e automatizado para o ciclo de vida do banco de dados em **6 Passos**:

### Fluxo de Execução em 6 Passos (`runner.py`)

1. **Validar se o banco existe**: Consulta conectividade via driver PostgreSQL.
2. **Caso não exista, criar!**: Se não existir, executa o provisionamento de infraestrutura (Docker Compose local ou AWS Aurora Serverless v2).
3. **Validar se destroy está ativo (`DESTROY=true`)**: Se ativo, executa exclusão total do banco, **encerra o fluxo imediatamente** e pula as etapas seguintes.
4. **Caso destroy desativado, validar se há script para executar**: Verifica se o parâmetro de script SQL (`schema.sql`) ou Alembic foi passado.
5. **Validar Script**:
   - Verifica existência física do arquivo SQL.
   - Sintaxe e regras de segurança: **Proíbe estritamente instruções que tentem renomear ou alterar o nome do banco** (`ALTER DATABASE ... RENAME TO ...` ou `DROP DATABASE`), já que a criação e nome do banco são gerenciados unicamente pela pipeline.
6. **Executar Script**: Executa o script SQL ou comando Alembic validado de forma transacional.

> **⚠️ Princípio de Arquitetura Limpa:**
> - O banco de dados é um **armazenamento puro persistente** (Tabelas, Chaves Primárias/Estrangeiras e Índices).
> - **Zero Triggers, Zero Stored Procedures, Zero Views** no banco de dados.
> - Todas as regras de negócio, geradores de código (`booking_code`), timestamps de atualização (`updated_at`), mascaramentos PII e visibilidades de agenda vivem **exclusivamente na camada de aplicação (microsserviços FastAPI / Pydantic / ORM)**.
> - As regras de aplicação estão documentadas em [BUSINESS_RULES_HANDLED_IN_SERVICES.md](file:///d:/Documentos/Projetos/Hairdule/Hairdule%202.0/Projeto%20novo/hairdule-db/BUSINESS_RULES_HANDLED_IN_SERVICES.md).

---

## 6. Tabelas de Domínio (Lookup Tables)

Para evitar a rigidez dos ENUMs nativos do PostgreSQL (que exigem comandos DDL `ALTER TYPE` para adicionar opções), o sistema utiliza **9 Tabelas de Domínio (`domain_*`)**.

### Estrutura Padrão da Tabela de Domínio
```sql
CREATE TABLE domain_<nome> (
    code VARCHAR(50) PRIMARY KEY,        -- Chave legível (ex: 'AGENDADO', 'BARBERSHOP')
    name VARCHAR(100) NOT NULL,          -- Nome amigável para exibição ("Agendado")
    description VARCHAR(255),            -- Descrição do estado/função
    display_order INT DEFAULT 0,         -- Ordem de exibição em menus/selects
    is_active BOOLEAN DEFAULT TRUE,      -- Permite desativar sem excluir histórico
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);
```

### Relação de Tabelas de Domínio

1. `domain_business_types`: Segamentos (`BARBERSHOP`, `SALON`, `SPA`, `NAIL_DESIGN`, `OTHER`).
2. `domain_barbershop_statuses`: Status da barbearia (`ONBOARDING`, `ACTIVE`, `INACTIVE`, `SUSPENDED`).
3. `domain_staff_roles`: Cargos (`OWNER`, `MANAGER`, `BARBER`, `RECEPTIONIST`).
4. `domain_agenda_visibilities`: Visibilidade (`OWN_ONLY`, `TEAM_READ_ONLY`, `ALL_FULL`).
5. `domain_appointment_statuses`: Estados (`AGENDADO`, `CONFIRMADO`, `EM_ATENDIMENTO`, `FINALIZADO`, `CANCELADO_CLIENTE`, `CANCELADO_BARBEARIA`, `NAO_COMPARECEU`, `REMARCADO`).
6. `domain_subscription_statuses`: Status do plano (`TRIAL`, `ACTIVE`, `ATTENTION`, `GRACE_PERIOD`, `BLOCKED`, `CANCELLED`).
7. `domain_billing_cycles`: Ciclos (`MONTHLY`, `YEARLY`).
8. `domain_block_types`: Tipos de bloqueio (`ONE_TIME`, `RECURRING`, `VACATION`).
9. `domain_notification_types`: Notificações (`NEW_APPOINTMENT`, `CANCELLATION`, `REMINDER`, `SYSTEM`).

---

## Fase 0 — Setup do Ambiente de Desenvolvimento

> **Meta:** Infraestrutura local 100% ativa. Banco de dados inicializado via `hairdule-db` (com o `schema.sql` puro), SDK `hairdule-shared` instalado, contêineres e dev servers operacionais.  
> **Estimativa:** 1-2 dias

### Checklist — Fase 0

- [x] Python 3.12 instalado (`python --version`)
- [x] uv instalado (`uv --version`)
- [x] Node.js 22 LTS instalado (`node -v`)
- [x] Docker Desktop instalado e rodando
- [x] `docker compose up -d` → PostgreSQL e LocalStack healthy
- [ ] `hairdule-db`: repositório criado com pipeline de 6 passos, script SQL completo `schema.sql` (sem triggers/views), 9 Tabelas de Domínio + Tabelas de Negócio e Seeds executados no PostgreSQL local
- [ ] `hairdule-shared`: repositório criado (sem Alembic), `pip install -e .` ok, models ORM (DML) e Schemas Pydantic mapeados
- [ ] Repositórios de Infraestrutura modularizados criados (`hairdule-infra-auth`, `hairdule-infra-api`, `hairdule-infra-storage`, `hairdule-infra-events`)
- [ ] `hairdule-auth-service`: projeto criado, `uvicorn src.app:app --port 3001 --reload` → Swagger em `http://localhost:3001/docs`
- [ ] `hairdule-app-dashboard`: `ng serve --port 4300` → rodando em `http://localhost:4300`
- [ ] `hairdule-app`: `ng serve --port 4200` → rodando em `http://localhost:4200`
- [ ] Conexão do backend com PostgreSQL local validada (SQLAlchemy engine conecta via role hairdule_app)
- [x] `.env.example` criado com template de variáveis

---

## Fase 1 — Auth Service + Cadastro (Signup)

> **Meta:** Cadastro funcional end-to-end localmente. Usuário se cadastra, recebe JWT, dados salvos no banco.  
> **Estimativa:** 3-5 dias  
> **Depende de:** Fase 0

---

## Fase 2 — Barbershop Service + Onboarding

> **Meta:** Fluxo de onboarding de 5 etapas concluído. Status da barbearia altera para `ACTIVE`.  
> **Estimativa:** 3-4 dias  
> **Depende de:** Fase 1

---

## Fase 3 — Staff & Services Management

> **Meta:** CRUD completo de profissionais e serviços, respeitando permissões por `role_code`.  
> **Estimativa:** 3-4 dias  
> **Depende de:** Fase 2

---

## Fase 4 — Availability & Business Hours

> **Meta:** Gerenciamento de horários e disponibilidade com verificação em 6 camadas.  
> **Estimativa:** 4-5 dias  
> **Depende de:** Fase 3

---

## Fase 5 — Appointments (Staff)

> **Meta:** Agendamentos, máquina de estados, bloqueio duplo e auditoria via dashboard (código BKG gerado no serviço).  
> **Estimativa:** 5-7 dias  
> **Depende de:** Fase 4

---

## Fase 6 — Portal Público (Booking Online)

> **Meta:** Agendamento público pelo cliente sem login. Links mágicos de cancelamento e reagendamento.  
> **Estimativa:** 5-7 dias  
> **Depende de:** Fase 5

---

## Fase 7 — Subscriptions & Stripe

> **Meta:** Planos, checkout Stripe, webhooks e controle de escrita por assinatura.  
> **Estimativa:** 4-5 dias  
> **Depende de:** Fase 2

---

## Fase 8 — Notifications & Push

> **Meta:** Notificações in-app e WebPush VAPID para a equipe.  
> **Estimativa:** 3-4 dias  
> **Depende de:** Fase 5

---

## Fase 9 — Analytics & AI

> **Meta:** Métricas de desempenho e sugestões inteligentes de horários.  
> **Estimativa:** 4-5 dias  
> **Depende de:** Fase 5

---

## Fase 10 — Segurança, WAF & Hardening

> **Meta:** Proteção para produção: WAF, Captcha, Headers de segurança e Budgets AWS.  
> **Estimativa:** 3-5 dias  
> **Depende de:** Todas as fases anteriores

---

## Mapa de Dependências entre Fases

```
Fase 0: Setup Ambiente (hairdule-db, hairdule-shared, infra-repos)
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

---

## Progresso Geral

| Fase | Descrição | Status |
|---|---|---|
| 0 | Setup Ambiente | ⏳ Em Andamento |
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

> **Regra de Execução:** Nenhuma caixa de seleção (`- [ ]`) deste plano deve ser marcada (`- [x]`) sem a aprovação prévia e explícita do usuário para o item concluído.
