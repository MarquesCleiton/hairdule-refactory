# 📋 Hairdule 2.0 — Índice Mestre de Planos de Implementação

> **Projeto:** Hairdule — SaaS de agendamentos para estabelecimentos de beleza  
> **Arquitetura:** AWS Serverless (Lambda + Aurora + CloudFront + Cognito + API Gateway)  
> **Total de Fases:** 27 | **Última atualização:** 2026-08-25 (Marco 4 Concluído — Marco 5 em Progresso)  

---

## 🧱 BLOCO 1 — Fundação de Infraestrutura e Layer (Fases 01-05)

> Infraestrutura base e pacote de código compartilhado (DML, Schemas Pydantic v2, Auth Adapters).

| Fase | Arquivo | Tecnologia | Repositório | Status |
|---|---|---|---|---|
| **01** | [CHECKLIST_FASE_01.md](./CHECKLIST_FASE_01.md) | SST v4 + VPC | `fase_01_hairdule_infra_network` | ✅ 100% (Homologado na AWS Staging) |
| **02** | [CHECKLIST_FASE_02.md](./CHECKLIST_FASE_02.md) | SST v4 + SG + KMS | `fase_02_hairdule_infra_security` | ✅ 100% (Homologado na AWS Staging) |
| **03** | [CHECKLIST_FASE_03.md](./CHECKLIST_FASE_03.md) | SST v4 + Cognito + Secrets | `fase_03_hairdule_infra_auth` | ✅ 100% (Homologado na AWS Staging) |
| **04** | [CHECKLIST_FASE_04.md](./CHECKLIST_FASE_04.md) | Python + Aurora (PG 18.4) + Secrets | `fase_04_hairdule_db` | ✅ 100% (Homologado na AWS Staging) |
| **04.1** | [CHECKLIST_FASE_04_1.md](./CHECKLIST_FASE_04_1.md) | Python + SST v4 + Lambda VPC | `fase_04_1_hairdule_db_runner` | ✅ 100% (Homologado na AWS Staging) |
| **04.2** | [CHECKLIST_FASE_04_2.md](./CHECKLIST_FASE_04_2.md) | SST v4 + EC2 SSM + Auto-Stop | `fase_04_2_hairdule_bastion` | ✅ 100% (Homologado na AWS Staging) |
| **05** | [CHECKLIST_FASE_05.md](./CHECKLIST_FASE_05.md) | Python Package (Lambda Layer) | `fase_05_hairdule_shared` | ✅ 100% (Homologado na AWS Staging) |

---

## ⚡ BLOCO 2 — Fatias Verticais Testáveis (Fases 06-27)

> Fatias verticais organizadas em Marcos de Entrega E2E (Backend + API GW + Frontend).

### 🌟 MARCO 1 — Autenticação & Identidade E2E (Fases 06-08, 20)
| Fase | Arquivo | Tecnologia | Repositório | Status |
|---|---|---|---|---|
| **06** | [CHECKLIST_FASE_06.md](./CHECKLIST_FASE_06.md) | Lambda Python 3.12 — Auth Service (porta 3001) | `fase_06_hairdule_auth_service` | ✅ 100% (Homologado na AWS — IAM Auth) |
| **07** | [CHECKLIST_FASE_07.md](./CHECKLIST_FASE_07.md) | SST v4 + API Gateway v2 + WAF | `fase_07_hairdule_infra_api` | ✅ 100% (Homologado na AWS — HTTP API) |
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

### 🌟 MARCO 5 — Notificações, Analytics, Monetização & Automações (Fases 21-27)
| Fase | Arquivo | Tecnologia | Repositório | Ordem de Execução | Status |
|---|---|---|---|---|---|
| **20** | [CHECKLIST_FASE_20.md](./CHECKLIST_FASE_20.md) | SST v4 + S3 + CloudFront CDN | `fase_20_hairdule_infra_cdn` | — | ✅ 100% (Homologado na AWS — CloudFront OAC) |
| **24** | [CHECKLIST_FASE_24.md](./CHECKLIST_FASE_24.md) | Lambda Python — Notificações + Web Push VAPID (3008) | `fase_24_hairdule_notification_service` | **1º do Marco 5** | ✅ 100% (27/27 testes pytest verdes, 97% cobertura, VAPID RFC 8292) |
| **25** | [CHECKLIST_FASE_25.md](./CHECKLIST_FASE_25.md) | Angular 19 — Central de Notificações | `fase_08_hairdule_ui_web` (`features/notifications`) | **2º do Marco 5** | ✅ 100% (Badge Navbar, Signals, Polling 30s, Web Push VAPID, 46/46 testes verdes) |
| **26** | [CHECKLIST_FASE_26.md](./CHECKLIST_FASE_26.md) | Lambda Python — Analytics + IA (3009) | `fase_26_hairdule_analytics_service` | **3º do Marco 5** | ✅ 100% (20/20 testes pytest verdes, 98% cobertura, IA Heurística, API Gateway) |
| **27** | [CHECKLIST_FASE_27.md](./CHECKLIST_FASE_27.md) | Angular — Dashboard Analytics + Heatmap | `fase_08_hairdule_ui_web` (`features/analytics`) | **4º do Marco 5** | ✅ 100% (67/67 testes verdes, Gráfico SVG, Heatmap 7x24, Rankings, IA Suggestions) |
| **21** | [CHECKLIST_FASE_21.md](./CHECKLIST_FASE_21.md) | SST v4 + EventBridge Scheduler & Automações | `fase_21_hairdule_infra_scheduler` | **5º do Marco 5** | ✅ 100% (Lembretes 5min + Analytics Diário 01:00 BRT na AWS Staging) |
| **22** | [CHECKLIST_FASE_22.md](./CHECKLIST_FASE_22.md) | Lambda Python — Subscriptions + Stripe (3007) | `fase_22_hairdule_subscription_service` | **6º do Marco 5** | ⬜ 0% |
| **23** | [CHECKLIST_FASE_23.md](./CHECKLIST_FASE_23.md) | Angular 19 — Planos e Faturamento | `fase_08_hairdule_ui_web` (`features/billing`) | **7º do Marco 5** | ⬜ 0% |

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
| **TOTAL GERAL** | **~860** | **~835** | **~97%** |

---

## 🚀 Próximos Passos Imediatos (Ordem de Execução)

1. **[x] Marco 1 (Auth E2E & CDN)** — Fases 06, 07, 08 e 20 concluídas e homologadas na AWS Staging
2. **[x] Marco 2 (Onboarding E2E)** — Fases 09 e 10 concluídas e homologadas na AWS Staging
3. **[x] Fase 11 Staff Service pronto** — Microsserviço Staff CRUD, Permissões e Horários (porta 3003) com 32/32 testes e 90% de cobertura
4. **[x] Fase 12 UI Staff pronto** — Gestão de Profissionais no Web Dashboard Angular (`src/app/features/staff`) com 0 erros de build
5. **[x] Fase 13 Services Service pronto** — Microsserviço Catálogo de Serviços e Preços (porta 3004) com 31/31 testes e 92% de cobertura
6. **[x] Fase 14 UI Services pronto** — Catálogo de Serviços Drag-and-Drop Angular (`src/app/features/services`) com 0 erros de build
7. **[x] Fase 15 Availability Engine pronto** — Motor de Disponibilidade 6 Camadas (porta 3005) com 25/25 testes e 90% de cobertura
8. **[x] Fase 16 UI Availability pronto** — UI de Configuração de Horários, Intervalos e Bloqueios Angular (`src/app/features/availability`) com 0 erros de build
9. **[x] Fase 17 Appointment Service pronto** — Microsserviço de Agendamentos (porta 3006) com 32/32 testes E2E homologado na AWS Staging
10. **[x] Fase 18 UI Calendar pronto** — UI de Calendário Interativo Angular com 3 visões (Semana/Dia/Lista), filtros, modais e ações rápidas
11. **[x] Fase 19 UI Portal Público pronto** — Portal Público de Agendamento do Cliente (Self-Service) com Wizard 4 Passos, Voucher Digital e Consulta `/check`
12. **[x] Fase 24 Notification Service pronto** — Microsserviço de Notificações In-App e Web Push VAPID (porta 3008) com 27/27 testes e 97% de cobertura
13. **[x] Fase 25 UI Notifications pronto** — Central de Notificações Angular 19, Badge na Navbar, preferências e suporte a Web Push
14. **[x] Fase 26 Analytics Service pronto** — Microsserviço de Analytics e Sugestões Inteligentes (porta 3009) com 20/20 testes e deploy na AWS Staging
15. **[x] Fase 27 UI Analytics pronto** — Dashboard Analítico & BI Angular 19 com KPI cards, gráfico de faturamento, heatmap 7x24, rankings e sugestões de IA
16. **[x] Fase 21 EventBridge Scheduler pronto** — Agendador automático SST v4 com Lembretes (5min) e Consolidação de Analytics (01:00 BRT) implantado na AWS Staging
17. **[ ] Marco 5 — Etapa 6: Fase 22 (`fase_22_hairdule_subscription_service`)** — Microsserviço de Subscriptions, Planos Multi-tenant, Stripe Checkout e Webhooks (porta 3007)
18. **[ ] Marco 5 — Etapa 7: Fase 23 (`fase_08_hairdule_ui_web/features/billing`)** — UI de Planos, Gestão de Assinatura e Faturamento Angular 19

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
