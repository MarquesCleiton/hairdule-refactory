# 📋 Hairdule 2.0 — Índice Mestre de Planos de Implementação

> **Projeto:** Hairdule — SaaS de agendamentos para estabelecimentos de beleza  
> **Arquitetura:** AWS Serverless (Lambda + Aurora PostgreSQL 18.4 + CloudFront + Cognito + API Gateway v2)  
> **Total de Fases:** 32 | **Última atualização:** 2026-09-16 (Otimização FinOps AWS & Mapeamento de Faturamento/NAT)  

---

## 🧱 BLOCO 1 — Fundação de Infraestrutura e Layer (Fases 01-05)

> Infraestrutura base e pacote de código compartilhado (DML, Schemas Pydantic v2, Auth Adapters).

| Fase | Arquivo | Tecnologia | Repositório | Status |
|---|---|---|---|---|
| **01** | [CHECKLIST_FASE_01.md](./CHECKLIST_FASE_01.md) | SST v4 + VPC | `fase_01_hairdule_infra_network` | ✅ 100% (Homologado — VPC Endpoints redundantes removidos; NAT otimizado) |
| **02** | [CHECKLIST_FASE_02.md](./CHECKLIST_FASE_02.md) | SST v4 + SG + KMS | `fase_02_hairdule_infra_security` | ✅ 100% (Homologado na AWS Staging) |
| **03** | [CHECKLIST_FASE_03.md](./CHECKLIST_FASE_03.md) | SST v4 + Cognito + Secrets | `fase_03_hairdule_infra_auth` | ✅ 100% (Homologado na AWS Staging) |
| **04** | [CHECKLIST_FASE_04.md](./CHECKLIST_FASE_04.md) | Python + Aurora (PG 18.4) + Secrets | `fase_04_hairdule_db` | ✅ 100% (Homologado — 100% sob demanda via scripts start/stop) |
| **04.1** | [CHECKLIST_FASE_04_1.md](./CHECKLIST_FASE_04_1.md) | Python + SST v4 + Lambda VPC | `fase_04_1_hairdule_db_runner` | ✅ 100% (Homologado na AWS Staging) |
| **04.2** | [CHECKLIST_FASE_04_2.md](./CHECKLIST_FASE_04_2.md) | SST v4 + EC2 SSM + Auto-Stop | `fase_04_2_hairdule_bastion` | ✅ 100% (Homologado — Bug Pulumi corrigido, desligado por padrão) |
| **05** | [CHECKLIST_FASE_05.md](./CHECKLIST_FASE_05.md) | Python Package (Lambda Layer) | `fase_05_hairdule_shared` | ✅ 100% (Homologado na AWS Staging) |

---

## ⚡ BLOCO 2 — Fatias Verticais Testáveis (Fases 06-30)

> Fatias verticais organizadas em Marcos de Entrega E2E (Backend + API GW + Frontend).

### 🌟 MARCO 1 — Autenticação & Identidade E2E (Fases 06-08, 20)
| Fase | Arquivo | Tecnologia | Repositório | Status |
|---|---|---|---|---|
| **06** | [CHECKLIST_FASE_06.md](./CHECKLIST_FASE_06.md) | Lambda Python 3.12 — Auth Service (porta 3001) | `fase_06_hairdule_auth_service` | ✅ 100% (Homologado na AWS — IAM Auth) |
| **07** | [CHECKLIST_FASE_07.md](./CHECKLIST_FASE_07.md) | SST v4 + API Gateway v2 + WAF | `fase_07_hairdule_infra_api` | ✅ 100% (Homologado — WAF condicionado a Produção; Rate Limit nativo) |
| **08** | [CHECKLIST_FASE_08.md](./CHECKLIST_FASE_08.md) | Angular 19 — Web Dashboard SPA (Auth UI) | `fase_08_hairdule_ui_web` | ✅ 100% (Implantado na AWS — CloudFront CDN) |
| **20** | [CHECKLIST_FASE_20.md](./CHECKLIST_FASE_20.md) | SST v4 + S3 + CloudFront CDN | `fase_20_hairdule_infra_cdn` | ✅ 100% (Homologado na AWS — CloudFront OAC) |

### 🌟 MARCO 2 — Onboarding & Barbearia (Fases 09-10)
| Fase | Arquivo | Tecnologia | Repositório | Status |
|---|---|---|---|---|
| **09** | [CHECKLIST_FASE_09.md](./CHECKLIST_FASE_09.md) | Lambda Python 3.12 — Barbershop + Onboarding (3002) | `fase_09_hairdule_barbershop_service` | ✅ 100% (19/19 testes pytest verdes, 92% cobertura) |
| **10** | [CHECKLIST_FASE_10.md](./CHECKLIST_FASE_10.md) | Angular 19 — Wizard Onboarding 5 Etapas | `fase_08_hairdule_ui_web` (`features/onboarding`) | ✅ 100% (Homologado na AWS Staging) |

### 🌟 MARCO 3 — Equipe & Catálogo de Serviços (Fases 11-14)
| Fase | Arquivo | Tecnologia | Repositório | Status |
|---|---|---|---|---|
| **11** | [CHECKLIST_FASE_11.md](./CHECKLIST_FASE_11.md) | Lambda Python — Staff CRUD + Permissões (3003) | `fase_11_hairdule_staff_service` | ✅ 100% (32/32 testes pytest verdes, 90% cobertura) |
| **12** | [CHECKLIST_FASE_12.md](./CHECKLIST_FASE_12.md) | Angular 19 — Gestão de Profissionais | `fase_08_hairdule_ui_web` (`features/staff`) | ✅ 100% (Cards, Modais, Horários e Signals) |
| **13** | [CHECKLIST_FASE_13.md](./CHECKLIST_FASE_13.md) | Lambda Python — Services CRUD + Preços (3004) | `fase_13_hairdule_service_service` | ✅ 100% (31/31 testes pytest verdes, 92% cobertura) |
| **14** | [CHECKLIST_FASE_14.md](./CHECKLIST_FASE_14.md) | Angular 19 — Catálogo Drag-and-Drop | `fase_08_hairdule_ui_web` (`features/services`) | ✅ 100% (Drag & Drop CDK, Modais, Máscara R$, Pausas/Buffers) |

### 🌟 MARCO 4 — Motor de Disponibilidade & Agendamentos (Fases 15-19)
| Fase | Arquivo | Tecnologia | Repositório | Status |
|---|---|---|---|---|
| **15** | [CHECKLIST_FASE_15.md](./CHECKLIST_FASE_15.md) | Lambda Python — Motor de Disponibilidade 6 Camadas (3005) | `fase_15_hairdule_availability_engine` | ✅ 100% (25/25 testes pytest verdes, homologado na AWS) |
| **16** | [CHECKLIST_FASE_16.md](./CHECKLIST_FASE_16.md) | Angular 19 — Configuração de Horários e Bloqueios | `fase_08_hairdule_ui_web` (`features/availability`) | ✅ 100% (Componentes standalone, signals, build verde) |
| **17** | [CHECKLIST_FASE_17.md](./CHECKLIST_FASE_17.md) | Lambda Python — Agendamentos + Audit (3006) | `fase_17_hairdule_appointment_service` | ✅ 100% (20/20 testes pytest verdes, 88% cobertura, homologado na AWS) |
| **18** | [CHECKLIST_FASE_18.md](./CHECKLIST_FASE_18.md) | Angular 19 — Calendário Interativo | `fase_08_hairdule_ui_web` (`features/calendar`) | ✅ 100% (3 Visões, 11 componentes, Modais, Ações Rápidas) |
| **19** | [CHECKLIST_FASE_19.md](./CHECKLIST_FASE_19.md) | Angular 19 — Portal Público de Agendamento (porta 4200) | `fase_08_hairdule_ui_web` (`features/client-portal`) | ✅ 100% (Wizard 4 Passos, Voucher Digital, Consulta /check) |

### 🌟 MARCO 5 — Notificações, Analytics, Monetização & Automações (Fases 20-27)
| Fase | Arquivo | Tecnologia | Repositório | Ordem de Execução | Status |
|---|---|---|---|---|---|
| **20** | [CHECKLIST_FASE_20.md](./CHECKLIST_FASE_20.md) | SST v4 + S3 + CloudFront CDN | `fase_20_hairdule_infra_cdn` | — | ✅ 100% (Homologado na AWS — CloudFront OAC) |
| **S3 Mídias** | [CHECKLIST_STORAGE_S3_FOTOS.md](./CHECKLIST_STORAGE_S3_FOTOS.md) | AWS S3 Presigned URLs (Upload & Leitura) | `fase_05_hairdule_shared` / `fase_09` / `fase_11` / `fase_08` | — | ⏳ Em Execução |
| **24** | [CHECKLIST_FASE_24.md](./CHECKLIST_FASE_24.md) | Lambda Python — Notificações + Web Push VAPID (3008) | `fase_24_hairdule_notification_service` | **1º do Marco 5** | ✅ 100% (27/27 testes pytest verdes, 97% cobertura, VAPID RFC 8292) |
| **25** | [CHECKLIST_FASE_25.md](./CHECKLIST_FASE_25.md) | Angular 19 — Central de Notificações | `fase_08_hairdule_ui_web` (`features/notifications`) | **2º do Marco 5** | ✅ 100% (Badge Navbar, Signals, Polling 30s, Web Push VAPID, 46/46 testes verdes) |
| **26** | [CHECKLIST_FASE_26.md](./CHECKLIST_FASE_26.md) | Lambda Python — Analytics + IA (3009) | `fase_26_hairdule_analytics_service` | **3º do Marco 5** | ✅ 100% (20/20 testes pytest verdes, 98% cobertura, IA Heurística, API Gateway) |
| **27** | [CHECKLIST_FASE_27.md](./CHECKLIST_FASE_27.md) | Angular — Dashboard Analytics + Heatmap | `fase_08_hairdule_ui_web` (`features/analytics`) | **4º do Marco 5** | ✅ 100% (67/67 testes verdes, Gráfico SVG, Heatmap 7x24, Rankings, IA Suggestions) |
| **21** | [CHECKLIST_FASE_21.md](./CHECKLIST_FASE_21.md) | SST v4 + EventBridge Scheduler & Automações | `fase_21_hairdule_infra_scheduler` | **5º do Marco 5** | ✅ 100% (Lembretes 5min + Guarda DB Offline em Staging) |
| **22** | [CHECKLIST_FASE_22.md](./CHECKLIST_FASE_22.md) | Lambda Python — Subscriptions + Stripe (3007) | `fase_22_hairdule_subscription_service` | **6º do Marco 5** | ⏳ **Próximo a Executar** (Stripe SDK + NAT/Workers fora da VPC) |
| **23** | [CHECKLIST_FASE_23.md](./CHECKLIST_FASE_23.md) | Angular 19 — Planos e Faturamento | `fase_08_hairdule_ui_web` (`features/billing`) | **7º do Marco 5** | ⬜ 0% (Após Fase 22) |

### 🌟 MARCO 6 — E-mails Transacionais AWS SES & Ciclo de Vida de Identidade (Fases 28-30)
| Fase | Arquivo | Tecnologia | Repositório | Ordem de Execução | Status |
|---|---|---|---|---|---|
| **28** | [CHECKLIST_FASE_28.md](./CHECKLIST_FASE_28.md) | SST v4 + Python — Infra & Motor SES + Jinja2 HTML | `fase_03_hairdule_infra_auth` / `fase_05_hairdule_shared` | **1º do Marco 6** | ✅ 100% (Templates Jinja2, SES Adapter, 18/18 testes verdes) |
| **29** | [CHECKLIST_FASE_29.md](./CHECKLIST_FASE_29.md) | Lambda Python — Fluxos de E-mail de Auth & Staff | `fase_06_hairdule_auth_service` / `fase_11_hairdule_staff_service` | **2º do Marco 6** | ✅ 100% (Homologado — Rotas de reset, primeiro acesso e envio SES) |
| **30** | [CHECKLIST_FASE_30.md](./CHECKLIST_FASE_30.md) | Angular 19 — Telas de Redefinição & Primeiro Acesso | `fase_08_hairdule_ui_web` (`features/auth`) | **3º do Marco 6** | ✅ 100% (Homologado — Telas de reset-password e first-access com LGPD) |

### 🌟 MARCO 7 — Observabilidade de Negócio & Portal SuperAdmin (Fases 31-32)
| Fase | Arquivo | Tecnologia | Repositório | Ordem de Execução | Status |
|---|---|---|---|---|---|
| **32** | [PLANO_OBSERVABILIDADE_NEGOCIO_PORTAL_ADMIN.md](./PLANO_OBSERVABILIDADE_NEGOCIO_PORTAL_ADMIN.md) | SST v4 + Cognito App Client & RBAC Groups | `fase_32_hairdule_infra_auth_admin` | **1º do Marco 7** | ✅ 100% (Deploy SST v4 na AWS Staging via CI/CD) |
| **31** | [PLANO_OBSERVABILIDADE_NEGOCIO_PORTAL_ADMIN.md](./PLANO_OBSERVABILIDADE_NEGOCIO_PORTAL_ADMIN.md) | Angular 19 Standalone — Portal SuperAdmin SPA | `fase_31_hairdule_ui_admin` | **2º do Marco 7** | ✅ 100% (Deploy S3 + CloudFront HTTPS) |
| **31.1** | [PLANO_DETALHE_BARBEARIA_E_GOVERNANCA_ADMIN.md](./PLANO_DETALHE_BARBEARIA_E_GOVERNANCA_ADMIN.md) | Angular 19 — Detalhe 360° da Barbearia (UUID) & Gestão Admin | `fase_31_hairdule_ui_admin` | **3º do Marco 7** | ⏳ Pronto para Execução |

---

## 🗺️ Diagrama de Fluxo das Fatias Verticais

```
Fase 01 (VPC) ──► Fase 02 (Security) ──► Fase 03 (Cognito) ──► Fase 04 (Aurora DB) ──► Fase 05 (Shared Layer)
                                                                                            │
 ┌──────────────────────────────────────────────────────────────────────────────────────────┘
 ▼
MARCO 1: Fase 06 (Auth Service) ──► Fase 07 (API Gateway v2) ──► Fase 08 (Auth UI Angular) ──► Fase 20 (CloudFront CDN) ✅
                                                                     │
 ┌───────────────────────────────────────────────────────────────────┘
 ▼
MARCO 2: Fase 09 (Barbershop Service) ──► Fase 10 (Onboarding UI) ✅
                                               │
 ┌─────────────────────────────────────────────┘
 ▼
MARCO 3: Fases 11 & 12 (Staff Service + UI) ──► Fases 13 & 14 (Services Service + UI) ✅
                                                    │
 ┌──────────────────────────────────────────────────┘
 ▼
MARCO 4: Fase 15 (Availability Engine) ✅ ──► Fase 16 (Availability UI) ✅ ──► Fase 17 (Appointment Service) ✅ ──► Fase 18 (Calendar UI) ✅ ──► Fase 19 (Portal Público) ✅  ← CONCLUÍDO
                                                                                                         │
 ┌───────────────────────────────────────────────────────────────────────────────────────────────────────┘
 ▼
MARCO 5: Fase 24 (Notifications Service) ✅ ──► Fase 25 (UI Notificações) ✅ ──► Fase 26 (Analytics Service) ✅ ──► Fase 27 (UI Analytics) ✅ ──► Fase 21 (EventBridge Scheduler) ✅ ──► Fases 22 & 23 (Subscriptions E2E)
                                                                                                                                                                                          │
 ┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 ▼
MARCO 6: Fase 28 (Infra & Templates SES) ✅ ──► Fase 29 (Backend Auth & Staff Email Flows) ✅ ──► Fase 30 (UI Redefinição & Primeiro Acesso) ✅
```

---

## 📊 Progresso Geral do Projeto

| Bloco | Total de Itens Estimados | Concluídos | % |
|---|---|---|---|
| Fundação (Fases 01-05) | ~200 | ~200 | **100%** ✅ |
| Marco 1 — Autenticação E2E (Fases 06-08, 20) | ~120 | ~120 | **100%** ✅ |
| Marco 2 — Onboarding & Barbearia (Fases 09-10) | ~80 | ~80 | **100%** ✅ |
| Marco 3 — Staff & Catálogo (Fases 11-14) | ~120 | ~120 | **100%** ✅ |
| Marco 4 — Disponibilidade & Agendamentos (Fases 15-19) | ~180 | ~180 | **100%** ✅ |
| Marco 5 — Notificações, Analytics, Subscriptions & Automações (Fases 20-27) | ~160 | ~135 | **~84%** |
| Marco 6 — E-mails Transacionais AWS SES & Ciclo de Vida (Fases 28-30) | ~40 | ~40 | **100%** ✅ |
| **TOTAL GERAL** | **~900** | **~875** | **~97%** |

---

## 🚀 Próximos Passos Imediatos (Ordem de Execução)

1. **[x] Marco 1 (Auth E2E & CDN)** — Fases 06, 07, 08 e 20 concluídas e homologadas na AWS Staging
2. **[x] Marco 2 (Onboarding E2E)** — Fases 09 e 10 concluídas e homologadas na AWS Staging
3. **[x] Marco 3 (Staff & Catálogo)** — Fases 11, 12, 13 e 14 concluídas
4. **[x] Marco 4 (Disponibilidade & Agendamentos)** — Fases 15, 16, 17, 18 e 19 concluídas
5. **[x] Marco 5 (Notificações, Analytics & Automações)** — Fases 24, 25, 26, 27 e 21 concluídas
6. **[x] Marco 6 (E-mails Transacionais SES & Ciclo de Vida)** — Fases 28, 29 e 30 concluídas
7. **[x] Marco 7 (Observabilidade & Portal Admin)** — Fases 32 e 31 concluídas
8. **[ ] 🎯 ALVO ATUAL: Marco 5 — Etapa 6: Fase 22 (`fase_22_hairdule_subscription_service`)** — Microsserviço de Subscriptions, Planos Multi-tenant, Stripe Checkout e Webhooks (porta 3007)
9. **[ ] Marco 5 — Etapa 7: Fase 23 (`fase_08_hairdule_ui_web/features/billing`)** — UI de Planos, Gestão de Assinatura e Faturamento Angular 19
10. **[ ] Marco 7 — Etapa 3: Fase 31.1 (`PLANO_DETALHE_BARBEARIA_E_GOVERNANCA_ADMIN.md`)** — Detalhe 360° da Barbearia & Governança Admin

---

## 📐 Convenções do Projeto

| Convenção | Valor |
|---|---|
| **Organização e Visibilidade Git** | Todos os repositórios DEVEM ser **PRIVADOS** e criados na organização **`MarquesCleitonOrg`** |
| **Código Compartilhado (GH_PAT)** | Todo microsserviço backend consome `fase_05_hairdule_shared` usando a secret `GH_PAT` para clone via token seguro no CI/CD + `astral-sh/setup-uv@v5` no SST v4 |
| **Suíte de Testes Manuais AWS (Regra)** | Todo microsserviço backend DEVE obrigatoriamente incluir a pasta `docs/testes_manuais/` com os arquivos `TESTES_SUCESSO.md` e `TESTES_ERROS.md` contendo a massa JSON completa (API Gateway v2 2.0) e resultados esperados |
| **Portas Locais das Lambdas** | auth: 3001 \| barbershop: 3002 \| staff: 3003 \| services: 3004 \| availability: 3005 \| appointments: 3006 \| subscriptions: 3007 \| notifications: 3008 \| analytics: 3009 |
| **Portas Locais dos Frontends** | Dashboard: 4300 \| Portal: 4200 |
| **Preços** | Sempre em centavos (int) — nunca float |
| **Timezone** | `America/Sao_Paulo` (via `zoneinfo.ZoneInfo`) |
| **Banco** | Zero triggers, Zero views, Zero stored procedures |
| **IaC** | SST v4 + TypeScript — `destroy: false` como padrão |
| **GitFlow** | `feature/*` → `release-vN` → `producao` → `main` |
| **CI/CD** | 4 workflows por repo: feature, staging, production, hotfix |
| **Actions** | SHA pinado (40 chars) — proteção supply chain |
| **Políticas IAM** | [POLITICAS_IAM_LEAST_PRIVILEGE.md](./POLITICAS_IAM_LEAST_PRIVILEGE.md) — 6 políticas modulares de Menor Privilégio |
| **Autenticação & Segurança Web** | **Cookies `HttpOnly; Secure; SameSite=Lax`** como padrão de segurança para o Web SPA. Dual-Mode com suporte a `Authorization: Bearer <token>` para mobile/CLI/testes. Zero tokens no `localStorage`. |
| **Roteamento de Borda Unificado** | **AWS CloudFront** como Reverse Proxy unificado (`/*` -> S3 Web SPA; `/auth/*`, `/barbershop/*`, `/staff/*`, `/services/*`, `/public/*` -> API Gateway) garantindo Same-Origin e eliminando problemas de CORS. |
| **Arquitetura Frontend** | [PLANO_MESTRE_DUMB_UI_BACKEND_ABSTRACTION.md](./PLANO_MESTRE_DUMB_UI_BACKEND_ABSTRACTION.md) — **Frontend 'Dumb UI / Pure View'**: Zero joins relacionais em memória JS, Zero regras de negócio no navegador, Endpoints Consolidados por visão no backend (BFF Pattern). |
| **Observabilidade Técnica & SRE** | [PLANO_OBSERVABILIDADE_TECNICA_SRE.md](./PLANO_OBSERVABILIDADE_TECNICA_SRE.md) — Modelo Híbrido (AWS CloudWatch Dashboards + Aba Saúde dos Serviços no Portal Admin), 4 Golden Signals, Telemetria Serverless e Aurora PG 18.4 |
| **Observabilidade de Negócio & SuperAdmin** | [PLANO_OBSERVABILIDADE_NEGOCIO_PORTAL_ADMIN.md](./PLANO_OBSERVABILIDADE_NEGOCIO_PORTAL_ADMIN.md) — Inteligência SaaS, Métricas Financeiras (MRR/ARR/GMV), Health Score de Barbearias, Backoffice Master e Tela de Saúde dos Serviços |
| **Governança FinOps & Custos AWS (Staging)** | Aurora Serverless v2 desligado por padrão (acionado via `scripts/start-aurora.ps1`). Schedulers com trava de conectividade socket (`_is_database_available`) para execução limpa em <1.5s com banco offline. Frequência de Schedulers em múltiplos de 5min (`cron(0/5 * * * ? *)`). Retenção CloudWatch Logs em 7 dias. WAF apenas em Produção. |
| **Estratégia de Conectividade (NAT, Push & Pagamentos)** | Em Staging: 1 NAT Instance (`t4g.nano`) para saída externa com controle de custo (~$7/mês). Arquitetura de Longo Prazo / Produção: Desacoplamento via SQS/EventBridge, mantendo workers de Push (FCM) e Gateways de Pagamento (Stripe) **fora da VPC** para tráfego de internet gratuito ($0,00 de NAT). |
