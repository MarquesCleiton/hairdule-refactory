# Hairdule 2.0 — Plano Mestre Executivo (Modelo Híbrido SST + Verticais E2E)

> **Projeto:** Hairdule — SaaS de agendamentos online para estabelecimentos de beleza  
> **Arquitetura:** AWS Serverless (Lambda + Aurora PostgreSQL + CloudFront + Cognito + API Gateway)  
> **Gerenciador de Infraestrutura:** SST v4 (TypeScript) + Runner de 6 Passos Python para o Banco  
> **Diretório Raiz de Implementação:** `d:\Documentos\Projetos\Hairdule\Hairdule 2.0\Projeto novo`  
> **Diretório Raiz de Documentação:** `d:\Documentos\Projetos\Hairdule\Hairdule 2.0\Docs\fases`  
> **Estratégia de Desenvolvimento:** Fatiamento Vertical (Cada Microsserviço Backend é pareado e testado imediatamente com sua interface Web Frontend).

---

## 1. Diretrizes Fundamentais da Arquitetura

1. **Regra de Isolamento por Fase (1 Fase = 1 Repositório = 1 Documento MD):**
   - Cada fase criará um repositório autônomo na pasta `Projeto novo/fase_XX_<nome>`.
   - Cada fase possuirá um arquivo de documentação técnica extremamente detalhado em `Docs/fases/fase_XX_<nome>.md`.

2. **Infraestrutura Declarativa com SST v4 (TypeScript):**
   - Toda a infraestrutura AWS (VPC, Security Groups, Cognito, API Gateway, S3, EventBridge) é escrita em TypeScript utilizando **SST v4**.
   - Permite desenvolvimento local instantâneo via `sst dev`.

3. **Banco de Dados Puro e Idempotente (`hairdule-db`):**
   - O banco de dados Aurora PostgreSQL é 100% puro DDL (**Zero Triggers, Zero Stored Procedures, Zero Views**).
   - O script [schema.sql](file:///d:/Documentos/Projetos/Hairdule/Hairdule%202.0/Projeto%20novo/hairdule-db/schema.sql) contém 9 Tabelas de Domínio com Seeds + 20 Tabelas de Negócio e Índices.
   - O gerenciamento é feito pelo orquestrador em Python `runner.py` em 6 Passos. Todas as regras de negócio vivem nos microsserviços.

4. **Ciclo de Vida Completo no CI/CD (GitHub Actions):**
   - Todo repositório possui uma pipeline CI/CD pronta em `.github/workflows/deploy.yml` capaz de:
     - **Deploy / Update**: Implantar e atualizar a infraestrutura/código na AWS automaticamente.
     - **Teardown / Destroy**: Excluir por completo todos os recursos criados na AWS através do comando `sst remove` ou flag de destroy.

5. **Desenvolvimento Pareado Backend ↔ Frontend (End-to-End Testability):**
   - Não deixamos as telas para o final do projeto.
   - Logo após implementar a Lambda Backend de um domínio, implementamos imediatamente a **interface web pareada**:
     - *Passo A:* Uma página simples de teste que exercita 100% das rotas e contratos da API.
     - *Passo B:* As telas finais polidas em Angular 18 (Material UI / Tailwind).

---

## 2. Topologia de Rede e Isolamento Zero-Trust

```
                        [ INTERNET PÚBLICA ]
                                 │
           ┌─────────────────────┴─────────────────────┐
           ▼                                           ▼
 [ CloudFront CDN ]                             [ AWS WAF ]
  (Frontends/Midia)                                    │
           │                                           ▼
    (Trancado via OAC)                      [ AWS API Gateway v2 ]
           │                                 (UNICA ENTRADA BACKEND)
           ▼                                           │
      [ Bucket S3 ]                                    │
                                                       ▼
 ╔═════════════════════════════════════════════════════════════════════════╗
 ║                     VPC PRIVADA ISOLADA (SEM IP PÚBLICO)                ║
 ║                                                                         ║
 ║     [ Microsserviços Lambdas ]  ───────►  [ Aurora PostgreSQL 16 ]    ║
 ║    (SG: sg-lambda-services)              (SG: sg-aurora-db / 5432)   ║
 ║                                                                         ║
 ╚═════════════════════════════════════════════════════════════════════════╝
```

---

## 3. Sequenciamento Mestre de Fases (27 Fases Pareadas)

### 🧱 BLOCO 1: INFRAESTRUTURA DE FUNDAÇÃO (PRÉ-REQUISITOS ESTREITOS)

#### Fase 01 — `fase_01_hairdule_infra_network`
* **Tipo:** SST v4 (TypeScript)
* **Dependência:** Nenhuma
* **Entregável:** VPC (CIDR `10.0.0.0/16`), 2 Subnets Privadas, 2 Subnets Públicas (Zonas `sa-east-1a` e `sa-east-1b`), Internet Gateway, NAT Gateway e Route Tables. Pipeline GitHub Actions de Deploy/Remove.

#### Fase 02 — `fase_02_hairdule_infra_security`
* **Tipo:** SST v4 (TypeScript)
* **Dependência:** Fase 01
* **Entregável:** Security Groups (`sg-aurora-db`, `sg-lambda-services`), DB Subnet Group para o Aurora e KMS Keys de criptografia. Pipeline GitHub Actions.

#### Fase 03 — `fase_03_hairdule_infra_auth`
* **Tipo:** SST v4 (TypeScript)
* **Dependência:** Fase 02
* **Entregável:** AWS Cognito User Pool, App Clients, Triggers e AWS Secrets Manager. Pipeline GitHub Actions.

#### Fase 04 — `fase_04_hairdule_db`
* **Tipo:** Python / DDL SQL
* **Dependência:** Fase 01, 02
* **Entregável:** Cluster Aurora Serverless v2 (PostgreSQL 16), Orquestrador em 6 Passos (`runner.py`), `schema.sql` puro, Seeds das 9 tabelas de domínio. Pipeline GitHub Actions.

#### Fase 05 — `fase_05_hairdule_shared`
* **Tipo:** Python Package (Lambda Layer)
* **Dependência:** Fase 04
* **Entregável:** Mapeamentos ORM SQLAlchemy (DML), Schemas Pydantic v2, Auth Middleware e Loggers. Pipeline GitHub Actions.

#### Fase 06 — `fase_06_hairdule_infra_api`
* **Tipo:** SST v4 (TypeScript)
* **Dependência:** Fase 01..03
* **Entregável:** AWS API Gateway v2 (HTTP API), AWS WAF, Custom Domain e CORS. Pipeline GitHub Actions.

#### Fase 07 — `fase_07_hairdule_infra_storage`
* **Tipo:** SST v4 (TypeScript)
* **Dependência:** Fase 01
* **Entregável:** Buckets S3 (fotos/logos), CloudFront CDN e Origin Access Control (OAC). Pipeline GitHub Actions.

#### Fase 08 — `fase_08_hairdule_infra_events`
* **Tipo:** SST v4 (TypeScript)
* **Dependência:** Fase 06
* **Entregável:** EventBridge Scheduler e Cron Jobs de automação de fundo. Pipeline GitHub Actions.

---

### ⚡ BLOCO 2: BACKEND LAMBDAS & TELAS WEB PAREADAS (TESTES END-TO-END)

#### Fase 09 — `fase_09_hairdule_auth_service`
* **Tipo:** Lambda Python (FastAPI)
* **Dependência:** Fase 03, 05
* **Entregável:** Endpoints de Signup, Login, Forgot Password, Reset Password e Refresh Token. Pipeline CI/CD.

#### Fase 10 — `fase_10_hairdule_app_dashboard_auth`
* **Tipo:** Angular 18
* **Dependência:** Fase 09
* **Entregável:** Página de Teste Simples de Autenticação ➔ Telas polidas de Login, Cadastro e Recuperação de Senha.

---

#### Fase 11 — `fase_11_hairdule_barbershop_service`
* **Tipo:** Lambda Python (FastAPI)
* **Dependência:** Fase 05, 06
* **Entregável:** Endpoints de Perfil da Barbearia e Conclusão de Onboarding. Pipeline CI/CD.

#### Fase 12 — `fase_12_hairdule_app_dashboard_onboarding`
* **Tipo:** Angular 18
* **Dependência:** Fase 11
* **Entregável:** Página de Teste Simples de Onboarding ➔ Wizard de Onboarding de 5 Etapas do Estabelecimento.

---

#### Fase 13 — `fase_13_hairdule_staff_service`
* **Tipo:** Lambda Python (FastAPI)
* **Dependência:** Fase 05, 06
* **Entregável:** Endpoints de CRUD de Profissionais, Roles e Visibilidades de Agenda. Pipeline CI/CD.

#### Fase 14 — `fase_14_hairdule_app_dashboard_staff`
* **Tipo:** Angular 18
* **Dependência:** Fase 13
* **Entregável:** Página de Teste Simples de Staff ➔ Gestão Completa de Profissionais, Permissões e Fotos.

---

#### Fase 15 — `fase_15_hairdule_services_service`
* **Tipo:** Lambda Python (FastAPI)
* **Dependência:** Fase 05, 06
* **Entregável:** Endpoints de CRUD de Serviços, Preços em Centavos, Duração, Buffers e Pausas. Pipeline CI/CD.

#### Fase 16 — `fase_16_hairdule_app_dashboard_services`
* **Tipo:** Angular 18
* **Dependência:** Fase 15
* **Entregável:** Página de Teste Simples de Serviços ➔ Catálogo de Serviços, Categorias e Reordenação.

---

#### Fase 17 — `fase_17_hairdule_availability_service`
* **Tipo:** Lambda Python (FastAPI)
* **Dependência:** Fase 05, 06
* **Entregável:** Endpoints de Horários de Funcionamento, Horários por Profissional e Bloqueios/Ausências. Pipeline CI/CD.

#### Fase 18 — `fase_18_hairdule_app_dashboard_availability`
* **Tipo:** Angular 18
* **Dependência:** Fase 17
* **Entregável:** Página de Teste Simples de Disponibilidade ➔ Configuração Visual de Horários e Ausências.

---

#### Fase 19 — `fase_19_hairdule_appointments_service`
* **Tipo:** Lambda Python (FastAPI)
* **Dependência:** Fase 05, 06
* **Entregável:** Endpoints de Criar Agendamento, Mudar Status, Audit Log e Código BKG. Pipeline CI/CD.

#### Fase 20 — `fase_20_hairdule_app_dashboard_appointments`
* **Tipo:** Angular 18
* **Dependência:** Fase 19
* **Entregável:** Página de Teste Simples de Agendamentos ➔ Calendário / Agenda Interativa do Dashboard.

#### Fase 21 — `fase_21_hairdule_app_public_booking`
* **Tipo:** Angular 18 (SSR / Portal Público `hairdule-app`)
* **Dependência:** Fase 19
* **Entregável:** Portal Público de Agendamento Online pelo Cliente (Seleção de Serviço, Barbeiro, Horário e Confirmação).

---

#### Fase 22 — `fase_22_hairdule_subscriptions_service`
* **Tipo:** Lambda Python (FastAPI)
* **Dependência:** Fase 05, 06
* **Entregável:** Endpoints de Seleção de Plano, Stripe Checkout e Webhooks. Pipeline CI/CD.

#### Fase 23 — `fase_23_hairdule_app_dashboard_subscriptions`
* **Tipo:** Angular 18
* **Dependência:** Fase 22
* **Entregável:** Página de Teste Simples de Checkout ➔ Gestão de Assinatura, Planos e Faturamento.

---

#### Fase 24 — `fase_24_hairdule_notifications_service`
* **Tipo:** Lambda Python (FastAPI)
* **Dependência:** Fase 05, 06
* **Entregável:** Endpoints de Notificações In-App, Preferências e WebPush VAPID. Pipeline CI/CD.

#### Fase 25 — `fase_25_hairdule_app_dashboard_notifications`
* **Tipo:** Angular 18
* **Dependência:** Fase 24
* **Entregável:** Central de Notificações In-App e Inscrição de Push Notificações no Navegador.

---

#### Fase 26 — `fase_26_hairdule_analytics_service`
* **Tipo:** Lambda Python (FastAPI)
* **Dependência:** Fase 05, 06
* **Entregável:** Endpoints de Métricas Financeiras, Faturamento e Sugestões Inteligentes de Horários (AI). Pipeline CI/CD.

#### Fase 27 — `fase_27_hairdule_app_dashboard_analytics`
* **Tipo:** Angular 18
* **Dependência:** Fase 26
* **Entregável:** Dashboard de Métricas, Gráficos de Faturamento e Card de Recomendações da AI.

---

## 4. Estrutura Padrão de Cada Repositório/Fase

Cada pasta `Projeto novo/fase_XX_<nome>` será um repositório limpo contendo:

```
Projeto novo/fase_XX_<nome>/
├── .github/
│   └── workflows/
│       └── deploy.yml           # Pipeline CI/CD (Deploy automático no Push, Destroy via Workflow Dispatch)
├── sst.config.ts                # (Se infra/Lambda SST) Configuração SST v4 em TypeScript
├── pyproject.toml / package.json# Dependências
├── src/                         # Código fonte
└── README.md                    # Manual de uso e comandos
```

---

## 5. Matriz de Aprovação Executiva

| Bloco | Fases | Descrição | Status |
|---|---|---|---|
| **Bloco 1** | Fases 01 a 08 | Infraestrutura de Fundação (Rede, Segurança, Auth, Banco, Layer, APIs) | ⏳ Pronto para iniciar Fase 01 |
| **Bloco 2** | Fases 09 a 27 | Microsserviços Backend pareados com Interfaces Frontend Web | ⬜ Aguardando Bloco 1 |
