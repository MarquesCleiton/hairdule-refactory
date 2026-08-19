# ✂️ Fase 14 — UI Catálogo de Serviços & Preços (Angular 19) (`fase_08_hairdule_ui_web`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_08_hairdule_ui_web` (Pasta: `src/app/features/services/`)  
> **Tecnologia:** Angular 19 + Reactive Forms + SCSS | Porta local: `4300`  
> **Dependências Diretas:** Fase 13 (service-service em `localhost:3004`)  
> **Regra de Centralização:** Esta fase é desenvolvida diretamente no repositório central `fase_08_hairdule_ui_web`, compartilhando autenticação, layout e design system.  
> **Última verificação:** 2026-08-18

---

## 🎯 Objetivo da Fase

A Fase 14 implementa o módulo de **Catálogo de Serviços & Preços** no Web Dashboard SPA: cadastro de serviços, categorias, duração em minutos, preços em centavos e reordenação drag-and-drop.

---

## 🎨 Interface — Gestão de Equipe

```
┌─────────────────────────────────────────────────────────────┐
│  👥 MINHA EQUIPE                    [+ Adicionar Profissional]│
│                                                              │
│  ┌──────────────────────────────────────────┐               │
│  │ [foto] João da Silva    Barbeiro  [✏️] [🗑️] │             │
│  │        joao@email.com                    │               │
│  │        ◉ Ativo          👁️ Apenas própria │               │
│  └──────────────────────────────────────────┘               │
│                                                              │
│  ┌──────────────────────────────────────────┐               │
│  │ [foto] Maria Santos     Dono       [✏️]   │               │
│  │        maria@email.com                   │               │
│  │        ◉ Ativo          👁️ Acesso Total   │               │
│  └──────────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ Checklist Completo da Fase 14

### 🖼️ 1. Passo A — Página de Teste Simples

- [ ] **Componente de teste** com botões para:
  - `GET /staff` (lista)
  - `POST /staff` (cria)
  - `PUT /staff` (atualiza)
  - `DELETE /staff/:id` (remove)
  - `GET /public/staff` (sem PII)
  - Exibe response bruta

---

### 🎨 2. Passo B — Telas Polidas

- [ ] **`features/staff/staff-list.component.ts`** — Lista de profissionais:
  - Cards com avatar, nome, cargo, email (se owner), status ativo/inativo
  - Badge de agenda_visibility
  - Botão [+ Adicionar] visível apenas para Owner
  - Botões [Editar] e [Remover] com estado baseado no role do usuário logado
  - Empty state (se lista vazia): ícone + "Nenhum profissional cadastrado"
- [ ] **`features/staff/staff-form.component.ts`** — Formulário (modal `mat-dialog`):
  - Modo Criar e Editar (mesmo componente)
  - Campos: Nome*, Email, Telefone, Cargo (select), Visibilidade de Agenda (select)
  - Multiselect de serviços que o profissional oferece
  - Campos sensíveis desabilitados se usuário for Barber editando próprio perfil
  - Upload de foto avatar (integra com S3 da Fase 07)
- [ ] **`features/staff/staff-delete-confirm.component.ts`** — Dialog de confirmação:
  - "Tem certeza que deseja remover João? Ele não poderá mais acessar o sistema."
  - Botões [Cancelar] e [Remover]

---

### 🧪 3. Validação Manual

- [ ] Owner vê email/phone de todos
- [ ] Barber vê apenas próprios dados sensíveis
- [ ] Botão [+ Adicionar] invisível para Barber
- [ ] Barber não consegue alterar campo "Cargo" (campo desabilitado)
- [ ] Confirmação antes de remover funciona

---

### ⏳ 4. A Fazer — Pendências

- [ ] Criar componentes de lista, formulário e confirmação
- [ ] Implementar controle de permissão no template (structural directives)
- [ ] Integrar com staff-service (Fase 13)
- [ ] Testar controle de acesso (Owner vs Barber)
- [ ] Build sem erros

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Passo A — Teste | 0 | 1 | **0%** ⬜ |
| Passo B — Telas (3 componentes) | 0 | 3 | **0%** ⬜ |
| Validação Manual | 0 | 5 | **0%** ⬜ |
| **TOTAL** | **0** | **9** | **0%** ⬜ |

> **Status:** ⬜ Aguardando Fase 13 concluída.
