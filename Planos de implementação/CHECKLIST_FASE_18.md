# 🗓️ Fase 18 — Dashboard Availability (Angular) (`fase_18_hairdule_app_dashboard_availability`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_18_hairdule_app_dashboard_availability`
> **Tecnologia:** Angular 18 + Angular Material | Porta local: `4300`
> **Dependências Diretas:** Fase 17 (availability-service em `localhost:3005`)
> **Última verificação:** 2026-08-11

---

## 🎯 Objetivo da Fase

A Fase 18 implementa a **configuração visual de horários e bloqueios** no dashboard. É onde o dono define quando a barbearia abre, quando cada barbeiro trabalha, e quando alguém está de férias.

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
