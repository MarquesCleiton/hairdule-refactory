# 📋 Hairdule 2.0 — Índice Mestre de Planos de Implementação

> **Projeto:** Hairdule — SaaS de agendamentos para estabelecimentos de beleza
> **Arquitetura:** AWS Serverless (Lambda + Aurora + CloudFront + Cognito + API Gateway)
> **Total de Fases:** 27 | **Última atualização:** 2026-08-16 (Reordenado por Fatias Verticais Testáveis E2E)

---

## 🧱 BLOCO 1 — Fundação de Infraestrutura e Layer (Fases 01-05)

> Infraestrutura base e pacote de código compartilhado (DML, Schemas Pydantic v2, Auth Adapters).

| Fase | Arquivo | Tecnologia | Repositório | Status |
|---|---|---|---|---|
| **01** | [CHECKLIST_FASE_01.md](./CHECKLIST_FASE_01.md) | SST v4 + VPC | `fase_01_hairdule_infra_network` | ✅ ~90% (Staging Operacional) |
| **02** | [CHECKLIST_FASE_02.md](./CHECKLIST_FASE_02.md) | SST v4 + SG + KMS | `fase_02_hairdule_infra_security` | ✅ ~95% (Staging Operacional) |
| **03** | [CHECKLIST_FASE_03.md](./CHECKLIST_FASE_03.md) | SST v4 + Cognito + Secrets | `fase_03_hairdule_infra_auth` | 🔶 ~85% (Código pronto) |
| **04** | [CHECKLIST_FASE_04.md](./CHECKLIST_FASE_04.md) | Python + Aurora (PG 18.4) + Secrets | `fase_04_hairdule_db` | ✅ ~95% (Código pronto, CI verde) |
| **04.1** | [CHECKLIST_FASE_04_1.md](./CHECKLIST_FASE_04_1.md) | Python + SST v4 + Lambda VPC | `fase_04_1_hairdule_db_runner` | ✅ ~95% (Código pronto) |
| **04.2** | [CHECKLIST_FASE_04_2.md](./CHECKLIST_FASE_04_2.md) | SST v4 + EC2 SSM + Auto-Stop | `fase_04_2_hairdule_bastion` | ✅ 100% (Código pronto) |
| **05** | [CHECKLIST_FASE_05.md](./CHECKLIST_FASE_05.md) | Python Package (Lambda Layer) | `fase_05_hairdule_shared` | ✅ 100% (Código pronto, Layer e CI/CD verdes) |

---

## ⚡ BLOCO 2 — Fatias Verticais Testáveis (Fases 06-27)

> Fatias verticais organizadas em Marcos de Entrega E2E (Backend + API GW + Frontend).

### 🌟 MARCO 1 — Autenticação & Identidade E2E (Fases 06-08)
| Fase | Arquivo | Tecnologia | Repositório | Status |
|---|---|---|---|---|
| **06** | [CHECKLIST_FASE_06.md](./CHECKLIST_FASE_06.md) | Lambda Python 3.12 — Auth Service (porta 3001) | `fase_06_hairdule_auth_service` | ✅ 100% (Homologado na AWS — IAM Auth) |
| **07** | [CHECKLIST_FASE_07.md](./CHECKLIST_FASE_07.md) | SST v4 + API Gateway v2 + WAF | `fase_07_hairdule_infra_api` | ✅ 100% (Homologado na AWS — HTTP API) |
| **08** | [CHECKLIST_FASE_08.md](./CHECKLIST_FASE_08.md) | Angular 19 — Web Dashboard SPA (Auth UI) | `fase_08_hairdule_ui_web` | ✅ 100% (Implantado na AWS — CloudFront CDN) |

### 🌟 MARCO 2 — Onboarding & Barbearia (Fases 09-10)
| Fase | Arquivo | Tecnologia | Repositório | Status |
|---|---|---|---|---|
| **09** | [CHECKLIST_FASE_09.md](./CHECKLIST_FASE_09.md) | Lambda Python 3.12 — Barbershop + Onboarding (3002) | `fase_09_hairdule_barbershop_service` | ✅ 100% (19/19 testes pytest verdes, 92% cobertura) |
| **10** | [CHECKLIST_FASE_10.md](./CHECKLIST_FASE_10.md) | Angular 19 — Wizard Onboarding 5 Etapas | `fase_08_hairdule_ui_web` (`features/onboarding`) | ⬜ 0% |

### 🌟 MARCO 3 — Equipe & Catálogo de Serviços (Fases 11-14)
| Fase | Arquivo | Tecnologia | Repositório | Status |
|---|---|---|---|---|
| **11** | [CHECKLIST_FASE_11.md](./CHECKLIST_FASE_11.md) | Lambda Python — Staff CRUD + Permissões (3003) | `fase_11_hairdule_staff_service` | ⬜ 0% |
| **12** | [CHECKLIST_FASE_12.md](./CHECKLIST_FASE_12.md) | Angular 19 — Gestão de Profissionais | `fase_08_hairdule_ui_web` (`features/staff`) | ⬜ 0% |
| **13** | [CHECKLIST_FASE_13.md](./CHECKLIST_FASE_13.md) | Lambda Python — Services CRUD + Preços (3004) | `fase_13_hairdule_service_service` | ⬜ 0% |
| **14** | [CHECKLIST_FASE_14.md](./CHECKLIST_FASE_14.md) | Angular 19 — Catálogo Drag-and-Drop | `fase_08_hairdule_ui_web` (`features/services`) | ⬜ 0% |

### 🌟 MARCO 4 — Motor de Disponibilidade & Agendamentos (Fases 15-19)
| Fase | Arquivo | Tecnologia | Repositório | Status |
|---|---|---|---|---|
| **15** | [CHECKLIST_FASE_15.md](./CHECKLIST_FASE_15.md) | Lambda Python — Motor de Disponibilidade 6 Camadas (3005) | `fase_15_hairdule_availability_engine` | ⬜ 0% |
| **16** | [CHECKLIST_FASE_16.md](./CHECKLIST_FASE_16.md) | Angular 19 — Configuração de Horários e Bloqueios | `fase_08_hairdule_ui_web` (`features/availability`) | ⬜ 0% |
| **17** | [CHECKLIST_FASE_17.md](./CHECKLIST_FASE_17.md) | Lambda Python — Agendamentos + Audit (3006) | `fase_17_hairdule_appointment_service` | ⬜ 0% |
| **18** | [CHECKLIST_FASE_18.md](./CHECKLIST_FASE_18.md) | Angular 19 — Calendário Interativo | `fase_08_hairdule_ui_web` (`features/calendar`) | ⬜ 0% |
| **19** | [CHECKLIST_FASE_19.md](./CHECKLIST_FASE_19.md) | Angular SSR — Portal Público de Agendamento (porta 4200) | `fase_19_hairdule_portal_public` | ⬜ 0% |

### 🌟 MARCO 5 — CDN, Automações & Serviços Complementares (Fases 20-27)
| Fase | Arquivo | Tecnologia | Repositório | Status |
|---|---|---|---|---|
| **20** | [CHECKLIST_FASE_20.md](./CHECKLIST_FASE_20.md) | SST v4 + S3 + CloudFront CDN | `fase_20_hairdule_infra_cdn` | ✅ 100% (Homologado na AWS — CloudFront OAC) |
| **21** | [CHECKLIST_FASE_21.md](./CHECKLIST_FASE_21.md) | SST v4 + EventBridge Scheduler | `fase_21_hairdule_infra_scheduler` | ⬜ 0% |
| **22** | [CHECKLIST_FASE_22.md](./CHECKLIST_FASE_22.md) | Lambda Python — Subscriptions + Stripe (3007) | `fase_22_hairdule_subscription_service` | ⬜ 0% |
| **23** | [CHECKLIST_FASE_23.md](./CHECKLIST_FASE_23.md) | Angular 19 — Planos e Faturamento | `fase_08_hairdule_ui_web` (`features/billing`) | ⬜ 0% |
| **24** | [CHECKLIST_FASE_24.md](./CHECKLIST_FASE_24.md) | Lambda Python — Notificações + Web Push VAPID (3008) | `fase_24_hairdule_notification_service` | ⬜ 0% |
| **25** | [CHECKLIST_FASE_25.md](./CHECKLIST_FASE_25.md) | Angular 19 — Central de Notificações | `fase_08_hairdule_ui_web` (`features/notifications`) | ⬜ 0% |
| **26** | [CHECKLIST_FASE_26.md](./CHECKLIST_FASE_26.md) | Lambda Python — Analytics + IA (3009) | `fase_26_hairdule_analytics_service` | ⬜ 0% |
| **27** | [CHECKLIST_FASE_27.md](./CHECKLIST_FASE_27.md) | Angular — Dashboard Analytics + Heatmap | `fase_27_hairdule_ui_analytics` | ⬜ 0% |

---

## 🗺️ Diagrama de Fluxo das Fatias Verticais

```
Fase 01 (VPC) ──► Fase 02 (Security) ──► Fase 03 (Cognito) ──► Fase 04 (Aurora DB) ──► Fase 05 (Shared Layer)
                                                                                            │
 ┌──────────────────────────────────────────────────────────────────────────────────────────┘
 ▼
MARCO 1: Fase 06 (Auth Service) ──► Fase 07 (API Gateway v2) ──► Fase 08 (Auth UI Angular)
                                                                     │
 ┌───────────────────────────────────────────────────────────────────┘
 ▼
MARCO 2: Fase 09 (Barbershop Service) ──► Fase 10 (Onboarding UI)
                                               │
 ┌─────────────────────────────────────────────┘
 ▼
MARCO 3: Fases 11 & 12 (Staff Service + UI) ──► Fases 13 & 14 (Services Service + UI)
                                                    │
 ┌──────────────────────────────────────────────────┘
 ▼
MARCO 4: Fases 15 & 16 (Availability Engine + UI) ──► Fases 17 & 18 (Appointment Service + UI) ──► Fase 19 (Portal Público SSR)
                                                                                                        │
 ┌──────────────────────────────────────────────────────────────────────────────────────────────────────┘
 ▼
MARCO 5: Fase 20 (CloudFront CDN) ──► Fase 21 (EventBridge Cron) ──► Fases 22-27 (Subscriptions, Notificações, Analytics IA)
```

---

## 📊 Progresso Geral do Projeto

| Bloco | Total de Itens Estimados | Concluídos | % |
|---|---|---|---|
| Fundação (Fases 01-05) | ~200 | ~190 | **~95%** |
| Marco 1 — Autenticação E2E (Fases 06-08) | ~120 | ~120 | **100%** ✅ |
| Marco 2 — Onboarding (Fases 09-10) | ~80 | 0 | **0%** |
| Marco 3 — Staff & Catálogo (Fases 11-14) | ~120 | 0 | **0%** |
| Marco 4 — Disponibilidade & Agendamentos (Fases 15-19) | ~180 | 0 | **0%** |
| Marco 5 — CDN, Scheduler & Serviços (Fases 20-27) | ~160 | 0 | **0%** |
| **TOTAL GERAL** | **~860** | **~310** | **~36%** |

---

## 🚀 Próximos Passos Imediatos (Ordem de Execução)

1. **[x] Fase 01 Staging Operacional** — VPC e Subnets operacionais
2. **[x] Fase 02 Staging Operacional** — Security Groups, KMS Keys e DB Subnet Group
3. **[x] Fase 04 Aurora DB pronto** — Schema PostgreSQL 18.4 e Secrets Manager
4. **[x] Fase 04.1 DB Runner pronto** — DB Runner Lambda VPC com auto-provisionamento de ledger e seeds
5. **[x] Fase 05 Shared Layer pronto** — Pacote `hairdule-shared` 100% testado e Lambda Layer validada no CI/CD
6. **[x] Fase 06 Auth Service pronto** — Microsserviço Python de Autenticação deployado na AWS Staging com 100% de cobertura
7. **[x] Fase 07 API Gateway pronto** — Provisionamento do API Gateway v2 HTTP API + WAF
8. **[x] Fase 08 Auth UI pronta** — Frontend Angular 19 de Autenticação (Login/Signup/Reset/Change) com 100% de separação HTML/TS/SCSS
9. **[x] Fase 09 Barbershop Service pronto** — Microsserviço Barbershop & Onboarding (porta 3002) com 19/19 testes e 92% de cobertura
10. **[ ] Iniciar Fase 10 (`fase_10_hairdule_ui_onboarding`)** — Wizard de Onboarding Angular (5 etapas)

---

## 📐 Convenções do Projeto

| Convenção | Valor |
|---|---|
| **Organização e Visibilidade Git** | Todos os repositórios DEVEM ser **PRIVADOS** e criados na organização **`MarquesCleitonOrg`** |
| **Código Compartilhado (GH_PAT)** | Todo microsserviço backend consome `fase_05_hairdule_shared` usando a secret `GH_PAT` para clone via token seguro no CI/CD + `astral-sh/setup-uv@v5` no SST v4 |
| **Suíte de Testes Manuais AWS (Regra)** | Todo microsserviço backend DEVE obrigatoriamente incluir a pasta `docs/testes_manuais/` com os arquivos `TESTES_SUCESSO.md` e `TESTES_ERROS.md` contendo a massa JSON completa (API Gateway v2 2.0) e resultados esperados |
| **Portas Locais das Lambdas** | auth: 3001 \| barbershop: 3002 \| staff: 3003 \| services: 3004 \| availability: 3005 \| appointments: 3006 \| subscriptions: 3007 \| notifications: 3008 \| analytics: 3009 |
| **Portas Locais dos Frontends** | Dashboard: 4300 \| Portal: 4200 |
| **Centralização Frontend Web** | Todo o Dashboard Web SPA fica centralizado no repositório **`fase_08_hairdule_ui_web`** (Fases 08, 10, 12, 14, 16, 18, 23, 25). Repositórios apartados de UI: apenas **`fase_19_hairdule_portal_public`** (Portal Público SSR) e **`fase_27_hairdule_ui_analytics`** (Dashboard Analytics/IA). |
| **Preços** | Sempre em centavos (int) — nunca float |
| **Timezone** | `America/Sao_Paulo` (via `zoneinfo.ZoneInfo`) |
| **Banco** | Zero triggers, Zero views, Zero stored procedures |
| **IaC** | SST v4 + TypeScript — `destroy: false` como padrão |
| **GitFlow** | `feature/*` → `release-vN` → `producao` → `main` |
| **CI/CD** | 4 workflows por repo: feature, staging, production, hotfix |
| **Actions** | SHA pinado (40 chars) — proteção supply chain |
| **Políticas IAM** | [POLITICAS_IAM_LEAST_PRIVILEGE.md](./POLITICAS_IAM_LEAST_PRIVILEGE.md) — 6 políticas modulares de Menor Privilégio |
