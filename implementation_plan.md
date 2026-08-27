# 📋 Plano de Revisão Geral e Saneamento Documental das Fases do Hairdule 2.0

## 🎯 Contexto e Esclarecimento da Dúvida do Usuário

> **Pergunta do Usuário:** *"Acredito que a fase 11 já esteja completa na fase 8, correto? Reveja todas as fases e atualize as documentações do que foi feito e o que faltam. Se a fase não fizer sentido, remova, se já foi feito em outro, corrija."*

### 💡 Diagnóstico do que Aconteceu:
1. **O usuário tem total razão sobre o conteúdo duplicado:**
   - O arquivo `CHECKLIST_FASE_11.md` antigo continha o título `# 🏪 Fase 11 — Barbershop Service Lambda` com rotas `GET /barbershop`, `PUT /barbershop`, `POST /barbershop/onboarding-complete`, etc.
   - Esse escopo **já foi 100% implementado, testado e homologado na AWS Staging** nas seguintes fases concluídas:
     - **Fase 09 (`fase_09_hairdule_barbershop_service`)**: Microsserviço Lambda Python com `GET /barbershop`, `PUT /barbershop`, `POST /barbershop/onboarding-complete`, `POST /barbershop/photo-upload`, `GET /public/barbershop`, `GET /public/lookup` (19/19 testes pytest, 92% cobertura).
     - **Fase 10 (`fase_08_hairdule_ui_web` -> `src/app/features/onboarding`)**: Wizard de Onboarding Angular 19 em 5 etapas conectado ao backend e PostgreSQL em Homologação.
     - **Fase 20 (`fase_20_hairdule_infra_cdn`)**: CloudFront CDN com OAC e roteamento unificado em produção/staging (`https://d19dlqxhe17bcr.cloudfront.net`).
2. **Por que isso aconteceu nos arquivos?**
   - No início do projeto, havia um planejamento antigo de 27 repositórios isolados com numeração diferente.
   - Em 16/08/2026, o projeto foi reorganizado no **[INDICE_MESTRE.md](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/Hairdule%202.0/Planos%20de%20implementa%C3%A7%C3%A3o/INDICE_MESTRE.md)** em **Fatias Verticais Testáveis (Marcos de Entrega E2E)** e **Frontend SPA Centralizado (`fase_08_hairdule_ui_web`)**.
   - Alguns arquivos individuais de checklist (`CHECKLIST_FASE_11.md` até `CHECKLIST_FASE_18.md`) ainda mantinham os títulos e escopos da numeração legada e ficaram defasados em relação ao `INDICE_MESTRE.md`.

---

## 🗺️ Mapeamento e Status Oficial Consolidado das Fases

### 🧱 BLOCO 1 — Fundação de Infraestrutura e Layer (Fases 01 a 05)
| Fase | Repositório / Diretório | Tecnologia | Status Atual | Detalhes |
|---|---|---|---|---|
| **01** | `fase_01_hairdule_infra_network` | SST v4 + VPC + Subnets Privadas | ✅ **100% Homologado** | VPC `vpc-010df10405f0570fc`, Subnets privadas em us-east-1 |
| **02** | `fase_02_hairdule_infra_security` | SST v4 + Security Groups + KMS | ✅ **100% Homologado** | SG `sg-0a129a6becf446af9`, Chaves KMS para Secrets e DB |
| **03** | `fase_03_hairdule_infra_auth` | SST v4 + Cognito + Secrets | ✅ **100% Homologado** | User Pool `us-east-1_tPfrA7wPP`, Client ID `4vqg1sg...` |
| **04** | `fase_04_hairdule_db` | Aurora PostgreSQL 18.4 Serverless | ✅ **100% Homologado** | Schema PostgreSQL completo, zero stored procedures/triggers |
| **04.1**| `fase_04_1_hairdule_db_runner` | SST v4 + Lambda VPC DB Runner | ✅ **100% Homologado** | Ledger de migrações e seeds automatizados na VPC |
| **04.2**| `fase_04_2_hairdule_bastion` | SST v4 + EC2 SSM Bastion Host | ✅ **100% Homologado** | Acesso seguro via SSM sem portas abertas na internet |
| **05** | `fase_05_hairdule_shared` | Python SDK Layer + IAM Auth | ✅ **100% Homologado** | ORM SQLAlchemy, Pydantic v2, AWS IAM DB Auth tokens |

---

### 🌟 BLOCO 2 — Fatias Verticais Testáveis (Marcos de Entrega E2E)

#### 🌟 MARCO 1 — Autenticação & Identidade E2E (Concluído ✅)
| Fase | Repositório / Diretório | Tecnologia | Status | Detalhes |
|---|---|---|---|---|
| **06** | `fase_06_hairdule_auth_service` | Lambda Python 3.12 (porta 3001) | ✅ **100%** | Endpoints de auth, emissão de Cookies HttpOnly, IAM Db Auth |
| **07** | `fase_07_hairdule_infra_api` | API Gateway v2 + WAF Regional | ✅ **100%** | HTTP API `nlrx258a8i`, WAF Rate Limiting, CORS no Edge |
| **08** | `fase_08_hairdule_ui_web` (`features/auth`) | Angular 19 SPA (porta 4300) | ✅ **100%** | Login, Cadastro, Recuperação de Senha, Signals, HttpOnly |
| **20** | `fase_20_hairdule_infra_cdn` | S3 + CloudFront CDN + OAC | ✅ **100%** | Antecipado no Marco 1 — Distribuição `d19dlqxhe17bcr.cloudfront.net` |

#### 🌟 MARCO 2 — Onboarding & Barbearia (Concluído ✅)
| Fase | Repositório / Diretório | Tecnologia | Status | Detalhes |
|---|---|---|---|---|
| **09** | `fase_09_hairdule_barbershop_service` | Lambda Python 3.12 (porta 3002) | ✅ **100%** | Gestão de Barbearia + Onboarding Atômico (19 testes pytest) |
| **10** | `fase_08_hairdule_ui_web` (`features/onboarding`) | Angular 19 Wizard 5 Etapas | ✅ **100%** | Segmento, Endereço ViaCEP, Equipe, Serviços, Horários, LGPD |

#### 🌟 MARCO 3 — Equipe & Catálogo de Serviços (Próximo Marco ⏳)
| Fase | Repositório / Diretório | Tecnologia | Status | Detalhes |
|---|---|---|---|---|
| **11** | `fase_11_hairdule_staff_service` | Lambda Python 3.12 (porta 3003) | ⬜ **0% (Próxima)** | CRUD Staff + Permissões OWNER vs BARBER + Horários de Staff + Avatar |
| **12** | `fase_08_hairdule_ui_web` (`features/staff`) | Angular 19 Gestão de Profissionais | ⬜ **0%** | UI de Equipe, modal de membros, permissões e horários individuais |
| **13** | `fase_13_hairdule_service_service` | Lambda Python 3.12 (porta 3004) | ⬜ **0%** | CRUD Catálogo de Serviços + Preços em centavos + Categorias |
| **14** | `fase_08_hairdule_ui_web` (`features/services`) | Angular 19 Catálogo Drag-and-Drop | ⬜ **0%** | UI de Serviços, reordenação Drag-and-Drop, máscara monetária |

#### 🌟 MARCO 4 — Motor de Disponibilidade & Agendamentos (Pendente ⏳)
| Fase | Repositório / Diretório | Tecnologia | Status | Detalhes |
|---|---|---|---|---|
| **15** | `fase_15_hairdule_availability_engine` | Lambda Python 3.12 (porta 3005) | ⬜ **0%** | Motor de Disponibilidade 6 Camadas (horários, pausas, bloqueios, férias) |
| **16** | `fase_08_hairdule_ui_web` (`features/availability`) | Angular 19 Grade de Horários | ⬜ **0%** | UI de Horários de Funcionamento, Pausas e Bloqueios |
| **17** | `fase_17_hairdule_appointment_service` | Lambda Python 3.12 (porta 3006) | ⬜ **0%** | Agendamentos, alteração de status, audit log |
| **18** | `fase_08_hairdule_ui_web` (`features/calendar`) | Angular 19 Calendário Interativo | ⬜ **0%** | Agenda visual diária/semanal por profissional |
| **19** | `fase_19_hairdule_portal_public` | Angular 19 SSR (porta 4200) | ⬜ **0%** | Portal público para clientes agendarem online |

#### 🌟 MARCO 5 — CDN, Automações & Serviços Complementares (Pendente ⏳)
| Fase | Repositório / Diretório | Tecnologia | Status | Detalhes |
|---|---|---|---|---|
| **20** | `fase_20_hairdule_infra_cdn` | CloudFront CDN + S3 | ✅ **100%** | Já concluído e homologado no Marco 1 |
| **21** | `fase_21_hairdule_infra_scheduler` | SST v4 + EventBridge Cron | ⬜ **0%** | Agendador de tarefas recorrentes e lembretes |
| **22** | `fase_22_hairdule_subscription_service` | Lambda Python 3.12 (porta 3007) | ⬜ **0%** | Gestão de Planos, Assinaturas e integração Stripe |
| **23** | `fase_08_hairdule_ui_web` (`features/billing`) | Angular 19 Planos & Cobrança | ⬜ **0%** | Telas de upgrade, pagamento e faturas |
| **24** | `fase_24_hairdule_notification_service` | Lambda Python 3.12 (porta 3008) | ⬜ **0%** | Disparos Web Push (VAPID), e-mail e in-app |
| **25** | `fase_08_hairdule_ui_web` (`features/notifications`) | Angular 19 Notificações | ⬜ **0%** | Central de notificações no dashboard |
| **26** | `fase_26_hairdule_analytics_service` | Lambda Python 3.12 (porta 3009) | ⬜ **0%** | Métricas de faturamento, ocupação e sugestões IA |
| **27** | `fase_27_hairdule_ui_analytics` | Angular 19 Painel Analytics | ⬜ **0%** | Dashboard com gráficos, heatmaps e insights IA |

---

## 🛠️ Alterações Propostas na Documentação

### 1. Atualizar e Corrigir os Checklists em `Hairdule 2.0/Planos de implementação/`
1. **[MODIFY] `CHECKLIST_FASE_11.md`**:
   - Atualizar título para `# 👥 Fase 11 — Staff Service Lambda (fase_11_hairdule_staff_service)`.
   - Definir escopo real: Microsserviço Python de Gestão de Profissionais (porta 3003), rotas `GET /staff`, `GET /staff/{id}`, `POST /staff`, `PUT /staff/{id}`, `DELETE /staff/{id}`, `GET /staff/{id}/hours`, `PUT /staff/{id}/hours`, `GET /public/staff`, proteções de campos sensíveis (`role_code`, `is_active`, `agenda_visibility_code`), validação de limite do plano (`can_add_staff`) e upload de foto.
2. **[MODIFY] `CHECKLIST_FASE_12.md`**:
   - Atualizar título e escopo para `# 👥 Fase 12 — UI Gestão de Profissionais / Staff (Angular 19) (fase_08_hairdule_ui_web)`.
   - Focar nas telas de `src/app/features/staff/` (lista de barbeiros, modal de cadastro/edição com bloqueio de campos sensíveis para barbeiros, horários de trabalho e vínculo de serviços).
3. **[MODIFY] `CHECKLIST_FASE_13.md`**:
   - Atualizar para `# ✂️ Fase 13 — Service Service Lambda (fase_13_hairdule_service_service)` (porta 3004).
   - CRUD de serviços, categorias, duração, pausas, preço em centavos.
4. **[MODIFY] `CHECKLIST_FASE_14.md`**:
   - Atualizar para `# ✂️ Fase 14 — UI Catálogo de Serviços & Preços (Angular 19) (fase_08_hairdule_ui_web)`.
   - Telas de `src/app/features/services/` com lista drag-and-drop, máscara de preço em centavos, modal de novo serviço.
5. **[MODIFY] `CHECKLIST_FASE_15.md`**:
   - Atualizar para `# ⏰ Fase 15 — Availability Engine Lambda (fase_15_hairdule_availability_engine)` (porta 3005).
   - Motor de cálculo de 6 camadas.
6. **[MODIFY] `CHECKLIST_FASE_16.md`**:
   - Atualizar para `# ⏰ Fase 16 — UI Configuração de Horários e Bloqueios (Angular 19) (fase_08_hairdule_ui_web)`.
   - Telas de `src/app/features/availability/`.
7. **[MODIFY] `CHECKLIST_FASE_17.md` & `CHECKLIST_FASE_18.md`**:
   - Alinhar Fase 17 (`fase_17_hairdule_appointment_service` - porta 3006) e Fase 18 (`fase_08_hairdule_ui_web` - `features/calendar`).
8. **[MODIFY] `INDICE_MESTRE.md`**:
   - Atualizar a tabela com o progresso exato e sincronizado de todas as fases.

---

## 🚀 Próximo Passo Após Aprovação
Assim que este plano de saneamento documental for aprovado:
1. Atualizaremos todos os arquivos de checklist e o índice mestre com a documentação corrigida e alinhada.
2. Iniciaremos a implementação da **Fase 11 real (`fase_11_hairdule_staff_service`)**:
   - Criação da pasta/repo `fase_11_hairdule_staff_service`
   - Configuração de `pyproject.toml`, `sst.config.ts`, `environments.ts`, CI/CD com `GH_PAT`
   - Implementação das rotas FastAPI de Staff, permissões e horários
   - Criação da suíte completa de testes pytest (100% de cobertura) e massas em `docs/testes_manuais/`
   - Deploy e validação em Staging na AWS.
