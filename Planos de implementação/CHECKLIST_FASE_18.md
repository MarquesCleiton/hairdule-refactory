# 📅 Fase 18 — UI Calendário Interativo & Agendamentos (Angular 19) (`fase_08_hairdule_ui_web`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_08_hairdule_ui_web` (Pasta: `src/app/features/calendar/`)  
> **Tecnologia:** Angular 19 + Reactive Forms + SCSS | Porta local: `4300`  
> **Dependências Diretas:** Fase 17 (appointment-service em `localhost:3006`)  
> **Regra de Centralização:** Esta fase é desenvolvida diretamente no repositório central `fase_08_hairdule_ui_web`, compartilhando autenticação, layout e design system.  
> **Última verificação:** 2026-08-18

---

## 🎯 Objetivo da Fase

A Fase 18 implementa o **Calendário Interativo de Agendamentos (Grade Diária/Semanal)** no Web Dashboard SPA: visualização de horários por profissional, criação manual de agendamentos pelo balcão, cancelamento e remarcação.

---

## ✅ Checklist Completo da Fase 18

### 🖼️ 1. Passo A — Página de Teste Simples

- [ ] Componente de teste com todos os endpoints da Fase 17
- [ ] Teste especial do motor: input de parâmetros → exibe slots calculados

---

### 🎨 2. Passo B — Telas Polidas

- [ ] **`features/availability/business-hours.component.ts`** — Horários da barbearia:
  - Tabela com 7 linhas (Dom → Sab)
  - Toggle "Aberto/Fechado" por dia
  - Time pickers de abertura e fechamento
  - Seção de "Pausas" (adicionar/remover intervalos, ex: almoço)
  - Autosave com debounce 500ms
- [ ] **`features/availability/staff-hours.component.ts`** — Horários por profissional:
  - Dropdown para selecionar profissional
  - Mesma tabela de 7 dias
  - Tooltip: "Se não configurado, usa o horário da barbearia"
- [ ] **`features/availability/blocks.component.ts`** — Bloqueios e ausências:
  - Lista de bloqueios existentes com período e tipo
  - Formulário para criar bloqueio:
    - Tipo (Pontual / Recorrente / Férias)
    - Profissional
    - Data (se pontual) ou Dia da Semana (se recorrente) ou Intervalo (se férias)
    - Motivo (opcional)
  - Alerta visual se houver agendamentos no período

---

### 🧪 3. Validação Manual

- [ ] Toggle "Fechado" desabilita time pickers
- [ ] Adicionar pausa de almoço reflete nos slots disponíveis
- [ ] Criar bloqueio em período com agendamentos → toast de aviso
- [ ] Configurar horário do profissional sobrepõe horário da barbearia
- [ ] Build sem erros

---

### ⏳ 4. A Fazer — Pendências

- [ ] Implementar todos os componentes com Angular Material
- [ ] Implementar autosave com debounce
- [ ] Integrar com availability-service (Fase 17)
- [ ] Testar fluxo completo
- [ ] Build sem erros

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Passo A — Teste | 0 | 1 | **0%** ⬜ |
| Passo B — 3 componentes | 0 | 3 | **0%** ⬜ |
| Validação Manual | 0 | 5 | **0%** ⬜ |
| **TOTAL** | **0** | **9** | **0%** ⬜ |

> **Status:** ⬜ Aguardando Fase 17 concluída (motor de disponibilidade).
