# 💰 Fase 23 — UI Planos e Faturamento (Angular 19) (`fase_08_hairdule_ui_web`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_08_hairdule_ui_web` (Pasta: `src/app/features/billing/`)  
> **Tecnologia:** Angular 19 + Reactive Forms + SCSS | Porta local: `4300`  
> **Dependências Diretas:** Fase 22 (subscription-service em `localhost:3007`)  
> **Regra de Centralização:** Esta fase é desenvolvida diretamente no repositório central `fase_08_hairdule_ui_web`, compartilhando autenticação, layout e design system.  
> **Última verificação:** 2026-08-18

---

## 🎯 Objetivo da Fase

A Fase 23 implementa a **tela de gestão de assinatura, planos e faturamento** no Web Dashboard SPA: comparação de planos (Starter vs Pro vs Enterprise), integração com checkout Stripe e portal do cliente.

---

## ✅ Checklist Completo da Fase 23

### 🖼️ 1. Passo A — Página de Teste Simples

- [ ] Componente de teste com botões para: listar planos, status da assinatura, iniciar checkout, acessar portal

---

### 🎨 2. Passo B — Telas Polidas

- [ ] **`features/subscription/plans.component.ts`** — Comparativo de Planos:
  - Cards lado a lado (Free, Básico, Profissional, Ilimitado)
  - Toggle "Mensal / Anual" (desconto destacado)
  - Card do plano atual destacado em azul
  - Botão "Assinar" ou "Fazer Upgrade"
  - Bullets de features por plano (✅ Disponível | ❌ Não disponível)
  - Card recomendado com badge "🌟 Popular"
- [ ] **`features/subscription/status.component.ts`** — Status Atual:
  - Badge colorido por status (Trial: laranja, Ativo: verde, Atenção: amarelo, Bloqueado: vermelho)
  - Data de vencimento / renovação
  - Últimos 4 dígitos do cartão
  - Botões: "Gerenciar Assinatura" (Portal Stripe) e "Ver Planos"
- [ ] **Banner de bloqueio** (se `status === 'BLOQUEADO'`):
  - Banner vermelho no topo de todas as páginas
  - "⚠️ Sua assinatura está suspensa. Regularize para continuar usando."
  - Link direto para a página de planos

---

### 🧪 3. Validação Manual

- [ ] Cards de planos exibem corretamente com preços
- [ ] Toggle mensal/anual atualiza preços
- [ ] Click "Assinar" → redirect para Stripe Checkout
- [ ] Retorno do Stripe → status atualizado
- [ ] Banner de bloqueio aparece quando status é BLOQUEADO
- [ ] Build sem erros

---

### ⏳ 4. A Fazer — Pendências

- [ ] Implementar comparativo de planos
- [ ] Implementar toggle mensal/anual
- [ ] Integrar redirect para Stripe Checkout
- [ ] Implementar banner global de bloqueio
- [ ] Testar fluxo completo com Stripe sandbox

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Passo A — Teste | 0 | 1 | **0%** ⬜ |
| Passo B — Telas (3 componentes) | 0 | 3 | **0%** ⬜ |
| Banner Global | 0 | 1 | **0%** ⬜ |
| Validação Manual | 0 | 6 | **0%** ⬜ |
| **TOTAL** | **0** | **11** | **0%** ⬜ |

> **Status:** ⬜ Aguardando Fase 22 concluída (subscriptions-service + Stripe configurado).
