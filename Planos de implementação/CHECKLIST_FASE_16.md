# 🗃️ Fase 16 — Dashboard Services (Angular) (`fase_16_hairdule_app_dashboard_services`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_16_hairdule_app_dashboard_services`
> **Tecnologia:** Angular 18 + Angular Material | Porta local: `4300`
> **Dependências Diretas:** Fase 15 (services-service em `localhost:3004`)
> **Última verificação:** 2026-08-11

---

## 🎯 Objetivo da Fase

A Fase 16 implementa a **tela de catálogo de serviços** do dashboard — onde o dono cria, edita e reordena os cortes e tratamentos que a barbearia oferece.

O destaque técnico é o **drag-and-drop de reordenação** e a **máscara de preço** em reais que converte para centavos antes de enviar para a API.

---

## ✅ Checklist Completo da Fase 16

### 🖼️ 1. Passo A — Página de Teste Simples

- [ ] Componente de teste com botões para todos os endpoints da Fase 15
- [ ] Campo de preço em reais → exibe centavos enviados

---

### 🎨 2. Passo B — Telas Polidas

- [ ] **`features/services/services-list.component.ts`** — Catálogo de serviços:
  - Lista com `cdkDropList` (Angular CDK) para drag-and-drop
  - Cada card: nome, duração (em horas/minutos formatado), preço (R$), badge "Variável" se aplicável
  - Toggle ativo/inativo inline
  - Botões [Editar] e [Remover]
  - Botão [+ Novo Serviço]
  - **Autosave da ordem** após drag (chama `PATCH /services/reorder`)
- [ ] **`features/services/service-form.component.ts`** — Formulário (modal `mat-dialog`):
  - Campo Nome
  - Campo Duração (slider 15min → 8h com step de 15min, exibe "2h 30min")
  - Toggle "Preço Variável" (quando ativo, desabilita campo de preço)
  - Campo Preço com máscara monetária (R$ 35,00 → envia 3500)
  - Campo Buffer pós-atendimento (minutos)
  - Toggle "Requer Pausa"
  - Toggle "Ativo"
- [ ] **Máscara monetária** com `CurrencyMaskDirective` própria:
  - Input aceita `35.00`, converte para `3500` ao salvar
  - Exibição sempre no formato R$ XX,XX

---

### 🧪 3. Validação Manual

- [ ] Drag-and-drop reordena e salva automaticamente
- [ ] Preço variável desabilita campo de preço
- [ ] Preço formatado corretamente na lista
- [ ] Duração exibida como "1h 30min" em vez de "90 minutos"
- [ ] Build sem erros

---

### ⏳ 4. A Fazer — Pendências

- [ ] Implementar componentes com CDK Drag-and-Drop
- [ ] Implementar máscara monetária
- [ ] Integrar com services-service (Fase 15)
- [ ] Testar reordenação e formulário
- [ ] Build sem erros

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Passo A — Teste | 0 | 1 | **0%** ⬜ |
| Passo B — Lista + Formulário | 0 | 3 | **0%** ⬜ |
| Máscara Monetária | 0 | 1 | **0%** ⬜ |
| Validação Manual | 0 | 5 | **0%** ⬜ |
| **TOTAL** | **0** | **10** | **0%** ⬜ |

> **Status:** ⬜ Aguardando Fase 15 concluída.
