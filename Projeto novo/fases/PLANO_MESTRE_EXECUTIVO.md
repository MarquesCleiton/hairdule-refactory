# Hairdule 2.0 — Plano Mestre Executivo (Diretório `fases`)

> **Projeto:** Hairdule — SaaS de agendamentos online para estabelecimentos de beleza  
> **Arquitetura:** AWS Serverless (Lambda + Aurora PostgreSQL + CloudFront + Cognito + API Gateway)  
> **Região AWS Padrão:** `us-east-1` (N. Virginia — Otimização Financeira & Menor Custo)  
> **Gerenciador de Infraestrutura:** SST v4 (TypeScript) + Runner de 6 Passos Python para o Banco  
> **Estratégia de Deploy GitOps:** Multi-Conta AWS com Branching Versionado (`feature/*` ➔ `release-vX.Y.Z` ➔ `main`)  
> **Diretório Raiz Único:** `./fases`  
> **Estratégia de Desenvolvimento:** Fatiamento Vertical (Microsserviços Backend pareados com Interfaces Web Frontend).  
> **Regra de Seleção:** Nenhuma caixa de seleção (`- [ ]`) é marcada (`- [x]`) sem a autorização prévia e explícita do usuário.

---

## 1. Estratégia de Branching GitOps & Promoção de Ambientes Versionados (`release-vX.Y.Z`)

O projeto utiliza o modelo **GitFlow Versionado (SemVer)** automatizado por Pull Requests entre duas contas AWS isoladas:

```
                                  [ DESENVOLVIMENTO ]
                                 Branch: feature/*
                                        │
                         (1. Validações TypeScript & SST)
                                        │
           (Action gera versão e cria branch release-v1.0.YYYYMMDD-HHMM)
                                        │
                                        ▼
                                 [ HOMOLOGAÇÃO ]
                             Branch: release-vX.Y.Z
                                        │
                   (2. Deploy Automático na Conta AWS Homologação)
                                        │
                         (Criação de Tag Git Oficial vX.Y.Z)
                                        │
         (PR Automático da release-vX.Y.Z para main)
                                        │
                                        ▼
                                  [ PRODUÇÃO ]
                                  Branch: main
                                        │
                     (3. Trava de Aprovação + Deploy na AWS Prod)
```

### 🔒 Estrutura de Travas e Proteções de Esteira (Quality Gates)

1. **Trava 1 (PR Automático Feature ➔ `release-vX.Y.Z`):**
   - Push em qualquer branch `feature/*` executa compilação e linters (`npx tsc`).
   - Se aprovado, a Action `feature-validation.yml` calcula o número de versão semântica, **cria a branch versionada `release-vX.Y.Z`** e abre um **Pull Request para a nova branch de release**.

2. **Trava 2 (Deploy Homologação, Tag Git & Promotion PR):**
   - Push/Merge na branch `release-vX.Y.Z` aciona a Action `deploy-staging.yml`.
   - Utiliza as credenciais da **Conta AWS de Homologação** (`AWS_ACCESS_KEY_ID_STAGING` / `AWS_SECRET_ACCESS_KEY_STAGING`).
   - Executa o deploy na AWS Homologação, **gera uma Tag Git oficial (`vX.Y.Z`)** e abre um **Pull Request da branch `release-vX.Y.Z` para a branch `main` (Produção)**.

3. **Trava 3 (Approval Gate de Produção):**
   - Push/Merge na branch `main` aciona a Action `deploy-production.yml`.
   - Protegida pelo **GitHub Environment `production`**, exigindo **aprovação manual (Reviewer)** antes de liberar as credenciais da **Conta AWS de Produção** (`AWS_ACCESS_KEY_ID_PROD` / `AWS_SECRET_ACCESS_KEY_PROD`).

4. **Trava 4 (Destroy Seguro por Frase de Confirmação):**
   - A remoção de infraestrutura (`destroy.yml`) exige indicar o estágio (`staging` ou `production`) e digitar a frase exata de segurança (ex: `CONFIRM_DESTROY_NETWORK`).

---

## 2. Padrão Único dos Documentos MD em `./fases/`

1. **Localização Única:**
   - Cada fase fica concentrada em `./fases/fase_XX_<nome>/`.
   - O documento `.md` de acompanhamento fica dentro da própria pasta da fase com o mesmo nome (`fase_XX_<nome>.md`).

2. **Analogias do Mundo Real Obrigatórias:**
   - Todo documento `.md` inicia com uma analogia simples do mundo real.

3. **Checklist Claro com Trava de Seleção:**
   - Checkboxes (`- [ ]`) atualizados para (`- [x]`) **exclusivamente mediante autorização do usuário**.

4. **Guia de Alterações & Testes Locais:**
   - Instruções de edição e comandos de teste local (`npm run dev` / `sst dev`).

5. **Guia de Teardown / Destruição & Ordem Inversa:**
   - Alertas visuais (`> [!CAUTION]` e `> [!WARNING]`) destacando a ordem de destruição inversa (Fases 27 ➔ 01).

---

## 3. Matriz das 27 Fases em `./fases/`

| Fase | Diretório / Documento | Descrição & Analogia da Fase | Status |
|---|---|---|---|
| **Fase 01** | [`fase_01_hairdule_infra_network/`](./fase_01_hairdule_infra_network/fase_01_hairdule_infra_network.md) | **Rede VPC:** O terreno e estradas do condomínio fechado. | ⏳ Em Progresso |
| **Fase 02** | `fase_02_hairdule_infra_security/` | **Segurança & SGs:** Os portões eletrônicos e cercas elétricas. | ⬜ Pendente |
| **Fase 03** | `fase_03_hairdule_infra_auth/` | **Auth Cognito:** A recepção central e emissão de crachás. | ⬜ Pendente |
| **Fase 04** | `fase_04_hairdule_db/` | **Banco Aurora:** O cofre central de arquivos e cadastros. | ⬜ Pendente |
| **Fase 05** | `fase_05_hairdule_shared/` | **SDK Layer:** O dicionário padronizado de termos da equipe. | ⬜ Pendente |
| **Fase 06** | `fase_06_hairdule_infra_api/` | **API Gateway & WAF:** Os guichês de atendimento com raio-X. | ⬜ Pendente |
| **Fase 07** | `fase_07_hairdule_infra_storage/` | **Storage S3/CDN:** O arquivo morto e vitrine de fotos. | ⬜ Pendente |
| **Fase 08** | `fase_08_hairdule_infra_events/` | **Events Scheduler:** O relógio com alarme para tarefas. | ⬜ Pendente |
| **Fase 09** | `fase_09_hairdule_auth_service/` | **Backend Auth:** Guichê de criação de conta e login. | ⬜ Pendente |
| **Fase 10** | `fase_10_hairdule_app_dashboard_auth/` | **Frontend Auth:** Telas de Login, Cadastro e Reset. | ⬜ Pendente |
| **Fase 11** | `fase_11_hairdule_barbershop_service/` | **Backend Barbershop:** Cadastro dos dados do estabelecimento. | ⬜ Pendente |
| **Fase 12** | `fase_12_hairdule_app_dashboard_onboarding/` | **Frontend Onboarding:** Wizard de 5 etapas do estabelecimento. | ⬜ Pendente |
| **Fase 13** | `fase_13_hairdule_staff_service/` | **Backend Staff:** Cadastro e cargos dos barbeiros/equipe. | ⬜ Pendente |
| **Fase 14** | `fase_14_hairdule_app_dashboard_staff/` | **Frontend Staff:** Tela de Gestão da Equipe e Permissões. | ⬜ Pendente |
| **Fase 15** | `fase_15_hairdule_services_service/` | **Backend Services:** Menu de cortes, barba, preços e pausas. | ⬜ Pendente |
| **Fase 16** | `fase_16_hairdule_app_dashboard_services/` | **Frontend Services:** Catálogo visual de serviços e preços. | ⬜ Pendente |
| **Fase 17** | `fase_17_hairdule_availability_service/` | **Backend Availability:** Grade de horários e bloqueios de folga. | ⬜ Pendente |
| **Fase 18** | `fase_18_hairdule_app_dashboard_availability/` | **Frontend Availability:** Calendário de gestão de turnos e folgas. | ⬜ Pendente |
| **Fase 19** | `fase_19_hairdule_appointments_service/` | **Backend Appointments:** O livro principal de agendamentos. | ⬜ Pendente |
| **Fase 20** | `fase_20_hairdule_app_dashboard_appointments/` | **Frontend Appointments:** Agenda interativa do estabelecimento. | ⬜ Pendente |
| **Fase 21** | `fase_21_hairdule_app_public_booking/` | **Frontend Public Booking:** Portal público de agendamento do cliente. | ⬜ Pendente |
| **Fase 22** | `fase_22_hairdule_subscriptions_service/` | **Backend Subscriptions:** Maquininha Stripe e assinaturas. | ⬜ Pendente |
| **Fase 23** | `fase_23_hairdule_app_dashboard_subscriptions/` | **Frontend Subscriptions:** Tela de gestão do plano e faturamento. | ⬜ Pendente |
| **Fase 24** | `fase_24_hairdule_notifications_service/` | **Backend Notifications:** Notificações in-app e WebPush. | ⬜ Pendente |
| **Fase 25** | `fase_25_hairdule_app_dashboard_notifications/` | **Frontend Notifications:** Central de notificações e Push Web. | ⬜ Pendente |
| **Fase 26** | `fase_26_hairdule_analytics_service/` | **Backend Analytics:** Relatórios de faturamento e AI. | ⬜ Pendente |
| **Fase 27** | `fase_27_hairdule_app_dashboard_analytics/` | **Frontend Analytics:** Painel de métricas e sugestões AI. | ⬜ Pendente |
