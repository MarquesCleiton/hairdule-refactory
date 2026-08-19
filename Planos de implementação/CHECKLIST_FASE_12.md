# 👥 Fase 12 — UI Gestão de Profissionais / Staff (Angular 19) (`fase_08_hairdule_ui_web`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_08_hairdule_ui_web` (Pasta: `src/app/features/staff/`)  
> **Tecnologia:** Angular 19 + Reactive Forms + SCSS | Porta local: `4300`  
> **Dependências Diretas:** Fase 11 (staff-service em `localhost:3003`)  
> **Regra de Centralização:** Esta fase é desenvolvida diretamente no repositório central `fase_08_hairdule_ui_web`, compartilhando autenticação, layout e design system.  
> **Última verificação:** 2026-08-18

---

## 🎯 Objetivo da Fase

A Fase 12 implementa o módulo de **Gestão da Equipe / Profissionais (Staff)** no Web Dashboard SPA: listagem de barbeiros/profissionais, convite de novos colaboradores, definição de permissões (Dono vs Colaborador) e foto de perfil.

É o "assistente de configuração inicial" da barbearia. Como configurar um celular novo: você passa por telas guiadas, define seus dados básicos, e no final está tudo pronto para usar.

---

## 🧙 Analogia — O Assistente de Configuração em 5 Etapas

```
ETAPA 1: Registro    → já feito (Fase 10)
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

## ✅ Checklist Completo da Fase 12

### 🔗 1. Pré-requisitos

- [ ] Fase 11 funcional (barbershop-service rodando em `localhost:3002`)
- [ ] Fase 10 concluída (usuário consegue fazer login e chegar ao onboarding)

---

### 🖼️ 2. Passo A — Página de Teste Simples

- [ ] **`features/onboarding-test/`** — componente de teste técnico:
  - Formulário único com todos os campos do `POST /barbershop/onboarding-complete`
  - Exibe response bruta em `<pre>`
  - Testa também `GET /barbershop` e `PUT /barbershop`

---

### 🎨 3. Passo B — Wizard de Onboarding Angular Material

- [ ] **`features/onboarding/onboarding.component.ts`** — container do `mat-stepper`:
  - `linear: true` — não pula etapas
  - Dados intermediários salvos em `localStorage` (previne perda ao recarregar)
  - Envio único no passo final (POST onboarding-complete)
- [ ] **Etapa 2 — `business-type.component.ts`**:
  - Cards visuais com ícone e nome por segmento
  - Segmentos: 💈 Barbearia, 💅 Salão, 🧴 Spa, 💍 Esmalteria, 🌿 Estética, Outro
  - Seleção única com feedback visual (card destacado)
- [ ] **Etapa 3 — `staff-count.component.ts`**:
  - Lista dinâmica de profissionais com `FormArray`
  - Botão "Adicionar profissional" (min 1, max ilimitado)
  - Campos: Nome (obrigatório), Cargo (Dono/Barbeiro)
  - Botão remover em cada item
- [ ] **Etapa 4 — `services-setup.component.ts`**:
  - Lista dinâmica de serviços com `FormArray`
  - Campos: Nome, Duração (minutos), Preço (R$)
  - Botão "Adicionar serviço" (min 1)
- [ ] **Etapa 5 — `hours-setup.component.ts`**:
  - 7 linhas (Dom a Sáb) com toggle "Aberto/Fechado"
  - Time pickers de abertura e fechamento
  - Desabilitado quando fechado
  - [Finalizar] → chama `POST /barbershop/onboarding-complete`
  - Loading state + error handling
  - Redirect para `/dashboard` após sucesso

---

### 🔄 4. Gestão de Estado

- [ ] `localStorage` salva dados intermediários de cada etapa
- [ ] `localStorage` é limpo após onboarding bem-sucedido
- [ ] Se usuário recarrega a página, retoma da etapa em que estava

---

### 🧪 5. Validação Manual

- [ ] Signup → redireciona para `/onboarding`
- [ ] Todas as 5 etapas funcionam sem erro
- [ ] POST onboarding-complete cria tudo no banco
- [ ] Redirect para `/dashboard` após sucesso
- [ ] Usuário que já completou onboarding não volta para esta tela

---

### ⏳ 6. A Fazer — Pendências

- [ ] Criar componentes do wizard
- [ ] Implementar FormArray para staff e serviços
- [ ] Integrar com barbershop-service (Fase 11)
- [ ] Testar fluxo completo end-to-end
- [ ] Build sem erros

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Pré-requisitos | 0 | 2 | **0%** ⬜ |
| Passo A — Teste | 0 | 1 | **0%** ⬜ |
| Passo B — Wizard (5 etapas) | 0 | 5 | **0%** ⬜ |
| Gestão de Estado | 0 | 3 | **0%** ⬜ |
| Validação Manual | 0 | 5 | **0%** ⬜ |
| **TOTAL** | **0** | **16** | **0%** ⬜ |

> **Status:** ⬜ Aguardando Fase 11 concluída.
