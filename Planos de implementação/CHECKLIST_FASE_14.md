# 👤 Fase 14 — Dashboard Staff (Angular) (`fase_14_hairdule_app_dashboard_staff`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_14_hairdule_app_dashboard_staff`
> **Tecnologia:** Angular 18 + Angular Material | Porta local: `4300`
> **Dependências Diretas:** Fase 13 (staff-service em `localhost:3003`)
> **Última verificação:** 2026-08-11

---

## 🎯 Objetivo da Fase

A Fase 14 implementa a **tela de gestão de profissionais** — onde o dono adiciona, edita e remove os colaboradores da barbearia, com controle visual de permissões baseado no papel do usuário logado.

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
