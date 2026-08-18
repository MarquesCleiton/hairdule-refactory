# 🏗️ Fase 10 — UI Wizard Onboarding (Angular) (`fase_10_hairdule_ui_onboarding`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_10_hairdule_ui_onboarding`
> **Tecnologia:** Angular 19 + Angular Material | Porta local: `4300`
> **Dependências Diretas:** Fase 09 (barbershop-service em `localhost:3002`)
> **Última verificação:** 2026-08-16

---

## 🎯 Objetivo da Fase

A Fase 10 implementa o **wizard de onboarding de 5 etapas** em Angular — a jornada que transforma um usuário recém-cadastrado em um estabelecimento totalmente configurado e pronto para atender clientes.

Ela fecha o **Marco 2 de Entrega Testável E2E**: o usuário faz login (Marco 1) e configura sua barbearia visualmente (dados, segmento, profissionais iniciais, serviços e horários).

---

## 🧙 Analogia — O Assistente de Configuração em 5 Etapas

```
ETAPA 1: Registro    → já feito (Fase 08)
ETAPA 2: Tipo        → "Que tipo de estabelecimento você tem?"
         BusinessType    Cards visuais: 💈 Barbearia | 💅 Salão | 🧴 Spa...

ETAPA 3: Profissionais → "Quem trabalha com você?"
         StaffCount      Lista dinâmica: [+ Adicionar profissional]
                         Nome + Cargo (Dono/Barbeiro)

ETAPA 4: Serviços    → "O que você oferece?"
         Services        Lista dinâmica: Nome + Duração + Preço

ETAPA 5: Horários    → "Quando você abre?"
         Hours           7 toggles (Dom-Sáb) + time pickers
                         → POST /barbershop/onboarding-complete ✅
```

---

## ✅ Checklist Completo da Fase 10

### 🔗 1. Pré-requisitos

- [ ] Fase 09 funcional (barbershop-service rodando em `localhost:3002`)
- [ ] Fase 08 concluída (usuário consegue fazer login e chegar ao onboarding)

---

### 🎨 2. Wizard de Onboarding Angular Material

- [ ] **`features/onboarding/onboarding.component.ts`** — container do `mat-stepper`:
  - `linear: true` — não pula etapas
  - Envio único no passo final (POST onboarding-complete)
- [ ] **Etapa 2 — `business-type.component.ts`**:
  - Cards visuais com ícone e nome por segmento
- [ ] **Etapa 3 — `staff-count.component.ts`**:
  - Lista dinâmica de profissionais
- [ ] **Etapa 4 — `services-setup.component.ts`**:
  - Lista dinâmica de serviços
- [ ] **Etapa 5 — `hours-setup.component.ts`**:
  - 7 linhas (Dom a Sáb) com toggles e time pickers

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Pré-requisitos | 0 | 2 | **0%** ⬜ |
| Wizard Angular Material (5 etapas) | 0 | 5 | **0%** ⬜ |
| **TOTAL** | **0** | **7** | **0%** ⬜ |

> **Status:** ⬜ Aguarda conclusão da Fase 09 (Barbershop Service).
