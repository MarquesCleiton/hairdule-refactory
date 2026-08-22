# ✂️ Fase 14 — UI Catálogo de Serviços & Preços (Angular 19) (`fase_08_hairdule_ui_web`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_08_hairdule_ui_web` (Pasta: `src/app/features/services/`)  
> **Tecnologia:** Angular 19 + Angular CDK (Drag & Drop) + Reactive Forms + SCSS | Porta local: `4300`  
> **Dependências Diretas:** Fase 13 (services-service em `localhost:3004` ou via API Gateway)  
> **Regra de Centralização:** Esta fase é desenvolvida diretamente no repositório central `fase_08_hairdule_ui_web`.  
> **Última atualização:** 2026-08-22  
> **Status:** ✅ **100% CONCLUÍDO (Build de Produção Validado com 0 Erros)**

---

## 🎯 Objetivo da Fase

A Fase 14 implementa a **interface visual de Catálogo de Serviços e Preços** no Web Dashboard SPA:
1. Listagem visual de serviços organizados por status e categorias (`Cabelo`, `Barba`, `Tratamento`, `Combos`, `Estética`, `Outro`).
2. **Reordenação interativa via Drag & Drop** (Angular CDK) com salvamento automático em lote na API (`PATCH /services/reorder`).
3. Modal de criação e edição com máscara monetária em tempo real (R$ com conversão para centavos inteiros `price_cents`).
4. Controle visual de duração (`DurationInput`) com stepper e formatação amigável (`45 min`, `1h 30min`).
5. Configuração avançada de tempo: Duração variável (`is_duration_variable`), buffer pós-atendimento (`buffer_min`) e pausas intermediárias (`PauseConfigInput`) com validação de tempo de retorno (mínimo 10 min).
6. Seleção múltipla de colaboradores habilitados com avatares, badge "Dono" e alertas de vinculação.
7. Cards com chips comportamentais (`Pode variar`, `+X min após`, `Com pausa`), switch de ativação imediata e diálogo de confirmação de desativação (soft delete).

---

## ✅ Checklist Completo da Fase 14

### 🎨 1. Camada de Modelos, Tipos & Serviços (`src/app/core/`)
- [x] **`src/app/core/models/service.models.ts`**: Modelos TypeScript completos (`ServiceItem`, `ServiceCreateRequest`, `ServiceUpdateRequest`, `ServiceReorderRequest`, `StaffSummaryItem`, `PRESET_CATEGORIES`, helpers `formatDuration`, `formatPriceCents`, `centsToReais`, `reaisToCents`, `maskToCents`, `isPauseConfigValid`)
- [x] **`src/app/core/services/service.service.ts`**: Cliente HTTP tipado com Signals reativos (`servicesList`, `isLoading`, `isSaving`, `error`), operações CRUD, `toggleServiceStatus`, `reorderServices`, `assignStaff` e `removeStaff`
- [x] **`src/app/core/http/api.service.ts`**: Adicionado método `patch<T>()` para requisições `PATCH /services/reorder`
- [x] **`proxy.conf.json`**: Configuração das rotas `/services` e `/staff` para API Gateway

### 🧩 2. Componentes Angular 19 Standalone (`src/app/features/services/`)
- [x] **`components/duration-input/duration-input.component.ts|html|scss`**:
  - Stepper de duração com botões de incremento/decremento com limites e formatação legível (`45 min`, `1h 30min`, `2h`)
- [x] **`components/pause-config-input/pause-config-input.component.ts|html|scss`**:
  - Divisão de atendimento ("Atende por" + "Pausa de"), timeline visual com 3 etapas (1ª etapa, pausa, retorno), validação em tempo real e alerta visual quando tempo restante for inferior a 10 min
- [x] **`components/service-card/service-card.component.ts|html|scss`**:
  - Alça de arraste Angular CDK (`cdkDragHandle`), badges coloridos por categoria, chips de comportamento (`Pode variar`, `+X min após`, `Com pausa`), switch de ativação rápida, lista de avatares dos profissionais habilitados e botões de edição/exclusão
- [x] **`components/service-form-dialog/service-form-dialog.component.ts|html|scss`**:
  - Modal com formulário reativo, máscara monetária em tempo real, botões de atalho de duração (15m, 30m, 45m, 60m, 90m, 120m), seletor de categorias em pills, dropdown de vinculação de colaboradores com avatares, seção expansível "Configurações Avançadas" com cards toggle para duração variável, buffer e pausa intermediária, e aviso sobre alteração de duração
- [x] **`components/service-delete-dialog/service-delete-dialog.component.ts|html|scss`**:
  - Confirmação de desativação lógica (soft delete) com explicação clara sobre o impacto no catálogo de agendamento online
- [x] **`services.component.ts|html|scss`**:
  - Página principal do catálogo com Top Aqua Header Accent, 4 cards de métricas (Total, Ativos, Preço Médio, Categorias), barra de busca, abas de filtro (`Todos`, `Ativos`, `Inativos`), pills de categoria dinâmicas, lista com `cdkDropList` para Drag & Drop e reordenação otimista, separador de inativos, estados de loading, empty state e floating toast

### 🛣️ 3. Roteamento & Navegação
- [x] **`app.routes.ts`**: Rota `/services` configurada com `authGuard` e lazy loading
- [x] **`dashboard-placeholder.component.html`**: Adicionado botão de acesso direto ao Catálogo de Serviços
- [x] **`app.config.ts`**: Ícones Lucide registrados (`GripVertical`, `Pause`, `Hourglass`, `Timer`, `Sliders`, `Tag`, `DollarSign`, `Layers`, `Sparkles`, `CheckSquare`)

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Modelos & Infraestrutura | 4 | 4 | **100%** ✅ |
| Componentes & Telas | 6 | 6 | **100%** ✅ |
| Roteamento & Integração | 3 | 3 | **100%** ✅ |
| **TOTAL** | **13** | **13** | **100%** ✅ |

> **Status:** ✅ **Fase 14 100% Concluída — Marco 3 Concluído.**
