# 🛡️ Estudo Arquitetural & Especificação Técnica: Níveis de Acesso, RBAC & Permissões Granulares

> **Projeto:** Hairdule 2.0 — Plataforma SaaS de Agendamentos e Gestão de Barbearias  
> **Arquitetura:** AWS Serverless (FastAPI Lambda + Aurora PostgreSQL + Angular 19 SPA)  
> **Status:** Estudo Técnico & Especificação Completa de Arquitetura (Versão 2.1 — Padrão Onboarding Própria Agenda)  
> **Data:** 2026-09-07  
> **Alinhamento:** Manifesto Frontend "Dumb UI" & Backend Authoritative (Zero Trust)  

---

## 1. Sumário Executivo & Princípios de Segurança

Este documento estabelece a especificação formal para o controle de acesso baseado em funções e permissões (RBAC — *Role-Based Access Control* com extensões contextuais ABAC — *Attribute-Based Access Control*) da plataforma Hairdule 2.0.

### 🏛️ Leis Fundamentais de Segurança da Plataforma:

1. **Backend Authoritative (Zero Trust no Cliente):**  
   Nenhuma restrição visual no frontend (ocultar botões, bloquear rotas ou desabilitar campos) é considerada controle de segurança. O backend valida obrigatoriamente a identidade, o estabelecimento (`barbershop_id`), o cargo (`role`) e a permissão específica antes de processar **qualquer requisição**.
2. **Isolamento Multi-tenant Estrito:**  
   Todo recurso pertence a um `barbershop_id`. Um usuário autenticado só pode operar sob o `barbershop_id` vinculado à sua sessão ativa. Requisições cruzadas disparam imediatamente `403 Forbidden` (`BARBERSHOP_ACCESS_DENIED`).
3. **Hierarquia de Permissão ("Editar implica Leitura"):**  
   Para qualquer recurso gerenciável, a permissão segue a escala:  
   $$\text{NONE (0)} < \text{READ (1)} < \text{EDIT (2)}$$  
   Se um colaborador possui permissão `EDIT`, ele possui implicitamente permissão `READ`.
4. **Padrão Conservador no Cadastro (Privacy by Default):**  
   Ao cadastrar qualquer novo colaborador — seja durante o **Onboarding (Passo 3)** ou no painel de **Equipe (`/staff`)** —, o acesso padrão obrigatório é **estritamente à sua própria agenda** (`team_schedule: NONE` / `agenda_visibility_code: OWN_ONLY`). O Dono ou Gerente tem total liberdade para, caso deseje, ampliar a visibilidade para a equipe posteriormente.
5. **Row-Level Scoping nos Relatórios (`/analytics`):**  
   O acesso a relatórios e métricas pelo Profissional é processado diretamente no nível de banco de dados (`WHERE staff_id = :my_staff_id`). O Profissional tem acesso total ao seu desempenho individual, mas é matematicamente impossível que ele acesse dados financeiros globais do salão ou de colegas.

---

## 2. Definição dos 3 Cargos (Roles) da Plataforma

A plataforma adota **3 cargos canônicos** no nível de estabelecimento:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             ESTABELECIMENTO                                 │
├────────────────────────┬────────────────────────────┬───────────────────────┤
│  1. PROPRIETÁRIO       │  2. GERENTE                │  3. PROFISSIONAL      │
│  (OWNER)               │  (MANAGER)                 │  (PROFESSIONAL)       │
├────────────────────────┼────────────────────────────┼───────────────────────┤
│ • Criador da conta     │ • Administrador operacional│ • Prestador de serviço│
│ • Titular financeiro   │ • Configurações do negócio │ • Padrão Onboarding:  │
│ • Paga a assinatura    │ • Gestão de equipe         │   APENAS própria      │
│ • Acesso irrestrito    │ • Agenda completa (default)│   agenda (OWN_ONLY)   │
│ • Exclusividades legais│ • SEM acesso a cartão/plano│ • Analytics restrito  │
│   e destrutivas        │ • NÃO exclui o salão       │   à sua performance   │
└────────────────────────┴────────────────────────────┴───────────────────────┘
```

### 👑 1. Proprietário (`OWNER`)
* **Papel:** É o dono legal do negócio e quem contratou a plataforma Hairdule.
* **Responsabilidades:** Criação da conta, pagamento da mensalidade (cartão de crédito / Stripe), definição dos rumos do negócio e titularidade jurídica.
* **Acessos:** Acesso irrestrito e total a todas as telas, configurações, dados financeiros da empresa, relatórios de IA e agendas.
* **Privilégios Exclusivos (Que NINGUÉM mais possui):**
  - Gerenciamento de Assinatura, Planos e Cartão de Crédito (`/billing`, Stripe Checkout, faturas, cancelamento de plano).
  - Exclusão permanente do estabelecimento (`DELETE /barbershop` / Excluir Conta).
  - Transferência de titularidade da barbearia para outro usuário.
  - Alteração de dados fiscais (CNPJ, Razão Social) e dados bancários para repasses.
  - Imutabilidade: Nenhum outro usuário pode desativar, rebaixar de cargo ou excluir o Proprietário.

### 👔 2. Gerente (`MANAGER`)
* **Papel:** É o braço direito do proprietário, responsável pela operação diária do salão.
* **Responsabilidades:** Ajuste de dados comerciais da barbearia, definição de horários de funcionamento, gestão da equipe (admissão/demissão no app), criação e precificação de serviços, análise de relatórios operacionais e resolução de conflitos de agenda.
* **Acessos:**
  - Acesso a todas as configurações operacionais da conta.
  - Visibilidade da agenda: **por padrão completa (`ALL_FULL`)**, podendo ver, criar, remarcar e cancelar agendamentos de qualquer profissional da casa.
  - Acesso a `/analytics` em **Modo Estabelecimento** (faturamento total do salão, rankings de todos os profissionais, gráficos globais e IA corporativa).
* **Restrições Rígidas em Relação ao Proprietário:**
  - ❌ **Zero Acesso a Cobrança:** Não visualiza dados do cartão de crédito do proprietário nem pode alterar/cancelar o plano da assinatura da plataforma.
  - ❌ **Sem Poder de Exclusão da Empresa:** Não pode solicitar a exclusão permanente da barbearia nem alterar o titular da conta.
  - ❌ **Sem Poder sobre o Proprietário:** Não pode inativar, demitir ou alterar o cargo do Proprietário na equipe.

### ✂️ 3. Profissional (`PROFESSIONAL`)
* **Papel:** É o colaborador técnico (barbeiro, cabeleireiro, manicure, esteticista) focado na excelência do atendimento ao cliente.
* **Regra Padrão no Cadastro (Onboarding e RH):**  
  > [!IMPORTANT]
  > Todo colaborador cadastrado nasce com **`team_schedule: NONE` (Visibilidade: Apenas Própria Agenda / `OWN_ONLY`)**. Ele só tem acesso aos seus próprios horários e clientes, garantindo privacidade e controle total desde o primeiro minuto.
* **Páginas Liberadas e Sua Experiência Adaptada:**
  1. `/my-day` — Seu painel diário de trabalho (seus clientes, atendimentos e encaixes).
  2. `/calendar` — Visão da agenda (por padrão, apenas a sua coluna; agenda dos colegas oculta).
  3. `/analytics` — **Modo "Minha Performance":** Acesso individualizado (sua produção em R$, volume de cortes, seu ticket médio, seu heatmap pessoal e sugestões da IA para sua carreira).
  4. `/staff` — **Modo "Nossa Equipe & Meu Perfil":** Visualização dos colegas e gerenciamento do seu próprio perfil (foto de perfil, bio e telefone pessoal).
  5. `/notifications` — Central pessoal de notificações in-app e WebPush (VAPID) no celular.
* **Páginas Bloqueadas (Removidas do menu e barradas com 403 no Backend):**
  - ❌ `/settings` (Configurações Gerais da Empresa / CNPJ / Endereço)
  - ❌ `/services` (Catálogo Master de Serviços do Salão)
  - ❌ `/availability` (Horários Globais de Funcionamento do Estabelecimento)
  - ❌ `/billing` (Gestão de Planos e Cartão de Crédito)

---

## 3. Fluxo de Cadastro no Onboarding (Passo 3 — Colaboradores)

Durante o fluxo de Onboarding (`/onboarding` - Etapa 3: Equipe), o sistema aplica a seguinte regra determinística:

1. **O Usuário Criador (Dono / Barbeiro 1):**
   - Cargo: `OWNER`
   - Visibilidade: `ALL_FULL` (Acesso completo e irrestrito)
   - Permissões: Acesso total administrativo
2. **Novos Colaboradores Adicionados no Onboarding:**
   - Cargo Padrão: `PROFESSIONAL` (ou `BARBER`)
   - Visibilidade Padrão: **`OWN_ONLY` (Apenas Própria Agenda)**
   - Formulário do Onboarding: O toggle de permissão vem pré-selecionado como **"Apenas própria agenda"**.
   - Permissões Gravadas no Banco:
     ```json
     {
       "own_schedule": "EDIT",
       "team_schedule": "NONE",
       "own_hours": "EDIT",
       "services": "READ",
       "client_contact": "MASKED",
       "financial_view": "PRICES_ONLY"
     }
     ```
3. **Pós-Onboarding (Painel de Gestão `/staff`):**
   - O Proprietário ou Gerente pode abrir a edição do colaborador a qualquer momento e alterar o switch de *"Apenas própria agenda"* para *"Ver agenda da equipe"* (`TEAM_READ_ONLY`) ou *"Acesso completo"* (`ALL_FULL`).

---

## 4. O `/analytics` em Modo Duplo: Estabelecimento vs Minha Performance

A liberação da página `/analytics` para o Profissional de forma restrita valoriza o profissional e estimula seu engajamento sem expor os números globais do negócio.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           A PÁGINA /analytics                               │
├──────────────────────────────────────┬──────────────────────────────────────┤
│  MODO ESTABELECIMENTO                │  MODO MINHA PERFORMANCE             │
│  (Proprietário & Gerente)            │  (Profissional)                      │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ • Faturamento Total do Salão (R$)    │ • Minha Produção / Faturamento (R$)  │
│ • Ticket Médio Geral do Estabelecimento│ • Meu Ticket Médio Individual      │
│ • Ranking de Faturamento da Equipe   │ • Meus Serviços Mais Realizados (%)  │
│ • Heatmap Geral de Todas as Cadeiras │ • Meu Heatmap de Ocupação Pessoal    │
│ • Taxa Geral de No-Show e Cancelamento│ • Minha Taxa de Clientes Concluídos │
│ • IA: Dicas Corporativas & Ociosidade│ • IA: Dicas para Aumentar Minha Renda│
│ ❌ Sem restrições                     │ ❌ Faturamento dos colegas OCULTO    │
│                                      │ ❌ Faturamento total da loja OCULTO  │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

### 🔒 Backend Row-Level Scoping em `/analytics`:
1. **Endpoint `GET /analytics/overview`:**
   - Se `user.role == 'PROFESSIONAL'`:
     - Executa `WHERE barbershop_id = :shop_id AND staff_id = :my_staff_id`.
     - Retorna: `total_revenue` (apenas dos atendimentos dele), `total_appointments` (dele), `average_ticket` (dele), `completion_rate` (dele).
2. **Endpoint `GET /analytics/revenue`:**
   - Se `user.role == 'PROFESSIONAL'`:
     - Retorna o gráfico temporal (dia a dia) apenas dos atendimentos dele.
     - A lista `by_staff` é retornada contendo **apenas a linha dele** (dados dos outros profissionais são suprimidos).
3. **Endpoint `GET /analytics/appointments`:**
   - Se `user.role == 'PROFESSIONAL'`:
     - O Heatmap 7x24 reflete a ocupação da cadeira DELE (quais horários ele mais atende).
     - O ranking de serviços reflete os serviços que ELE mais realizou.
4. **Endpoint `GET /analytics/suggestions`:**
   - A IA Heurística analisa os dados do profissional e gera sugestões focadas no seu ganho pessoal (ex: combos de barba nos horários vagos).

---

## 5. Matriz Completa de Permissões Granulares (Cargo + Pessoa)

Adotamos a regra: **"Editar permite tanto leitura quanto escrita"** ($\text{NONE} < \text{READ} < \text{EDIT}$).

| Recurso | Nível `NONE` | Nível `READ` (Leitura) | Nível `EDIT` (Edição — Leitura + Escrita) |
|---|---|---|---|
| **Própria Agenda (`own_schedule`)** | *(N/A)* | Apenas consulta seus horários (somente a recepção/gerente agenda ou altera para ele). | **(Padrão)** Consulta, cria agendamentos para si, atualiza status (Iniciar, Concluir, Cancelar, No-show) e remarca. |
| **Agenda dos Colegas (`team_schedule`)** | **(Padrão Onboarding/Cadastro):** No `/calendar` só vê a sua coluna; no `/my-day` não acessa filtro de equipe. | Vê a grade e horários dos colegas (ideal para encaixes), mas com drag-and-drop e edição desativados para terceiros. | Pode agendar para colegas, mover horários entre profissionais e remarcar atendimentos de terceiros. |
| **Seus Horários (`own_hours`)** | *(N/A)* | Apenas cumpre sua escala semanal cadastrada pela gerência, sem alterar. | **(Padrão)** Customiza sua própria grade de trabalho semanal, pausas de almoço e cadastra bloqueios/folgas pontuais na sua agenda. |
| **Serviços Próprios (`services`)** | *(N/A)* | **(Padrão)** Consulta quais serviços do salão está habilitado a prestar. | Auto-atribui quais serviços do salão executa (marca/desmarca) e customiza seus preços e durações pessoais de atendimento. |

---

## 6. Pontos Críticos Inspirados na Primeira Versão (ANALISE.md)

### 🛡️ 1. Proteção de Dados de Clientes (Anti-Desvio & LGPD — `appointments_safe`)
* Nos agendamentos **do próprio profissional**: ele vê o telefone/WhatsApp para poder confirmar o atendimento com o cliente dele.
* Nos agendamentos **dos colegas**: o telefone e notas do cliente alheio vêm **mascarados/ocultos**:
  - Nome do cliente: `Carlos ***`
  - Telefone: `(11) 9****-5678` (ou `NULL`)
  - E-mail e Notas: `NULL`
* Impede que um barbeiro capture a carteira de clientes dos colegas ou da barbearia para levá-los embora.

### 💰 2. Visualização Financeira (`financial_view`)
* `NONE`: O profissional não vê valores em R$ nos cards nem na agenda.
* `PRICES_ONLY`: **(Padrão)** Vê o preço do serviço para poder cobrar o cliente no balcão.
* `COMMISSION`: Vê o valor do serviço e sua comissão individual acumulada.

---

## 7. Experiência de Navegação no Desktop e Mobile (PWA)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       DESKTOP TOPBAR (APP-HEADER)                           │
├───────────────────┬─────────────────────────────────────────────────────────┤
│ OWNER / MANAGER   │ [Meu Dia] [Agenda] [Relatórios] [Serviços] [Horários]   │
│                   │ [Equipe]                    [Sino] [Pílula Barbearia ▾] │
├───────────────────┼─────────────────────────────────────────────────────────┤
│ PROFESSIONAL      │ [Meu Dia] [Agenda] [Desempenho] [Equipe]                │
│                   │                             [Sino] [Meu Perfil (Avatar)]│
└───────────────────┴─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                       MOBILE BOTTOM NAV (PWA)                               │
├───────────────────┬─────────────────────────────────────────────────────────┤
│ OWNER / MANAGER   │ [ Início ]   [ Agenda ]   [ Relatórios ]   [ Ajustes ]      │
├───────────────────┼─────────────────────────────────────────────────────────┤
│ PROFESSIONAL      │ [ Meu Dia ]  [ Agenda ]   [ Desempenho ]   [ Meu Perfil ]   │
└───────────────────┴─────────────────────────────────────────────────────────┘
```

---

## 8. Modelo de Dados no Aurora PostgreSQL (DDL Atualizado)

```sql
-- 1. Atualização dos Cargos no Domínio
INSERT INTO domain_staff_roles (code, name, display_order) VALUES
('OWNER', 'Proprietário', 1),
('MANAGER', 'Gerente', 2),
('PROFESSIONAL', 'Profissional', 3)
ON CONFLICT (code) DO UPDATE SET 
    name = EXCLUDED.name, 
    display_order = EXCLUDED.display_order;

-- 2. Atualização dos Níveis de Visibilidade de Agenda
-- Default canônico passa a ser OWN_ONLY para novos registros
INSERT INTO domain_agenda_visibilities (code, name, display_order) VALUES
('OWN_ONLY', 'Apenas Própria Agenda', 1),
('TEAM_READ_ONLY', 'Agenda do Time (Leitura)', 2),
('ALL_FULL', 'Acesso Completo', 3)
ON CONFLICT (code) DO NOTHING;

-- 3. Permissões Granulares na Tabela Staff com Default Conservador (Privacy by Default)
ALTER TABLE staff 
ADD COLUMN IF NOT EXISTS permissions JSONB NOT NULL DEFAULT '{
    "own_schedule": "EDIT",
    "team_schedule": "NONE",
    "own_hours": "EDIT",
    "services": "READ",
    "client_contact": "MASKED",
    "financial_view": "PRICES_ONLY",
    "apply_discounts": false
}'::jsonb;

-- 4. Garantir que o valor padrão da coluna agenda_visibility_code seja OWN_ONLY
ALTER TABLE staff ALTER COLUMN agenda_visibility_code SET DEFAULT 'OWN_ONLY';

CREATE INDEX IF NOT EXISTS idx_staff_permissions_gin ON staff USING GIN (permissions);
```

---

## 9. Roteiro Faseado de Execução

1. **Etapa 1 — Shared Layer & Banco (`fase_05` + DB):**
   - Alterar default de `agenda_visibility_code` para `'OWN_ONLY'` no model e DDL.
   - Model `Staff.permissions` em JSONB com default `team_schedule: NONE`.
2. **Etapa 2 — Onboarding & Auth (`fase_09` e `fase_06`):**
   - Garantir que todo colaborador criado via `POST /onboarding-complete` receba `agenda_visibility_code: 'OWN_ONLY'` e `team_schedule: 'NONE'` por padrão (exceto o OWNER).
   - Enriquecer token JWT com `role`, `staff_id` e permissões ativas.
3. **Etapa 3 — Scoping de Analytics (`fase_26`):**
   - Forçar filtro `staff_id = user.staff_id` para usuários `PROFESSIONAL`.
4. **Etapa 4 — Staff & Agendamentos (`fase_11` e `fase_17`):**
   - Proteção de PII nos agendamentos de colegas (`appointments_safe`).
   - Default de criação de staff em `POST /staff` como `OWN_ONLY`.
5. **Etapa 5 — Fechamento das Rotas Administrativas (`fase_09`, `fase_13`, `fase_15`):**
   - Injeção de `require_roles("OWNER", "MANAGER")`.
6. **Etapa 6 — Interface Web Angular (`fase_08`):**
   - Formulário do Onboarding (Passo 3) pré-selecionado como "Apenas própria agenda (`OWN_ONLY`)".
   - `roleGuard` nas rotas proibidas (`/settings`, `/services`, `/availability`, `/billing`).
   - Header e Bottom Nav adaptados para o Profissional com acesso a `/my-day`, `/calendar`, `/analytics` e perfil.
