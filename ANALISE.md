# Hairdule — Análise Técnica Completa

> Projeto: Hairdule — SAAS de agendamentos online
> Ultima atualizacao: 2026-08-02

---

## Índice

1. Visão Geral
2. Estrutura de Repositórios
3. Stack Tecnológica
4. Banco de Dados
5. Rotas de API
6. Regras de Negócio
7. Segurança e Permissões
8. Sistema de Assinaturas
9. Notificações e Push
10. PWA e Frontend
11. Integrações Externas

---

## 1. Visão Geral

Hairdule é um SaaS B2B multi-tenant de agendamentos online para estabelecimentos de beleza.
Cada tenant e um estabelecimento (barbershop) com profissionais, servicos e agenda próprios.

Segmentos: barbershop, salon, nails, lashes, aesthetics, spa, autonomous, other

Modos de agendamento: manual (só staff) ou online (cliente via portal público)

---

## 2. Estrutura de Repositórios

cloud-loaveble-access/   # BACKEND (Supabase + 58 Edge Functions Deno/TypeScript + 81 migrações SQL)
hair-flow-67/            # FRONTEND (React 18, TypeScript, Vite, Tailwind CSS v3)

---

## 3. Stack Tecnológica

Backend: Supabase, PostgreSQL, Deno, TypeScript, Stripe, WebPush/VAPID, RLS, Supabase Auth, Supabase Storage, Supabase Realtime

Frontend: React 18, TypeScript, Vite, Tailwind CSS v3, shadcn/ui + Radix UI, React Router v6,
TanStack Query v5, React Hook Form v7, Zod, Recharts, date-fns-tz (America/Sao_Paulo),
Sentry, Sonner, next-themes, PWA

---

## 4. Banco de Dados

Plataforma: Supabase (PostgreSQL) | Schema: public | Timezone: America/Sao_Paulo

ENUMs:
- business_type: barbershop|salon|nails|lashes|aesthetics|spa|autonomous|other
- barbershop_status: ONBOARDING|ACTIVE|SUSPENDED|INACTIVE
- appointment_status: AGENDADO|CONFIRMADO|EM_ATENDIMENTO|FINALIZADO|CANCELADO_CLIENTE|CANCELADO_BARBEARIA|NAO_COMPARECEU|REMARCADO
- staff_role: owner|barber
- subscription_status: active|attention|blocked|cancelled
- billing_cycle: monthly|yearly
- agenda_visibility: OWN_ONLY|TEAM_READ_ONLY


### Tabela: public.barbershops

| Coluna | Tipo | Nulo | Default | Descricao |
|---|---|---|---|---|
| id | UUID | NOT NULL | gen_random_uuid() | PK |
| owner_id | UUID | nullable | - | FK auth.users.id ON DELETE SET NULL |
| cnpj | VARCHAR(18) | nullable | - | CNPJ unico |
| razao_social | VARCHAR(255) | nullable | - | Razao social |
| nome_fantasia | VARCHAR(255) | NOT NULL | - | Nome fantasia |
| segment | business_type | NOT NULL | other | Tipo de negocio |
| status | barbershop_status | NOT NULL | ONBOARDING | Status |
| whatsapp | VARCHAR(20) | nullable | - | WhatsApp |
| email | VARCHAR(255) | nullable | - | Email |
| photo_url | TEXT | nullable | - | URL da foto/logo |
| cep | VARCHAR(10) | nullable | - | CEP |
| logradouro | VARCHAR(255) | nullable | - | Rua/Avenida |
| numero | VARCHAR(20) | nullable | - | Numero |
| complemento | VARCHAR(100) | nullable | - | Complemento |
| bairro | VARCHAR(100) | nullable | - | Bairro |
| cidade | VARCHAR(100) | nullable | - | Cidade |
| uf | CHAR(2) | nullable | - | UF |
| lat | DECIMAL(10,8) | nullable | - | Latitude |
| lng | DECIMAL(11,8) | nullable | - | Longitude |
| booking_mode | TEXT | nullable | manual | manual ou online |
| slot_interval_min | INTEGER | nullable | 30 | Intervalo de slots (min) |
| created_at | TIMESTAMPTZ | - | NOW() | - |
| updated_at | TIMESTAMPTZ | - | NOW() | - |

RLS: Público le apenas status=ACTIVE; Owner gerencia sua barbearia.
Indices: idx_barbershops_owner, idx_barbershops_status

---

### Tabela: public.user_roles

| Coluna | Tipo | Nulo | Default | Descricao |
|---|---|---|---|---|
| id | UUID | NOT NULL | gen_random_uuid() | PK |
| user_id | UUID | NOT NULL | - | FK auth.users.id ON DELETE CASCADE |
| barbershop_id | UUID | NOT NULL | - | FK barbershops.id ON DELETE CASCADE |
| role | staff_role | NOT NULL | barber | owner ou barber |
| created_at | TIMESTAMPTZ | - | NOW() | - |

UNIQUE: (user_id, barbershop_id)

---

### Tabela: public.staff

| Coluna | Tipo | Nulo | Default | Descricao |
|---|---|---|---|---|
| id | UUID | NOT NULL | gen_random_uuid() | PK |
| user_id | UUID | nullable | - | FK auth.users.id ON DELETE SET NULL |
| barbershop_id | UUID | NOT NULL | - | FK barbershops.id ON DELETE CASCADE |
| name | VARCHAR(255) | NOT NULL | - | Nome completo |
| email | VARCHAR(255) | nullable | - | Email (PII - restrito) |
| phone | VARCHAR(20) | nullable | - | Telefone (PII - restrito) |
| avatar_url | TEXT | nullable | - | URL da foto |
| role | staff_role | NOT NULL | barber | Cargo |
| active | BOOLEAN | - | TRUE | Se esta ativo |
| agenda_visibility | agenda_visibility | NOT NULL | OWN_ONLY | Visibilidade na agenda |
| created_at | TIMESTAMPTZ | - | NOW() | - |
| updated_at | TIMESTAMPTZ | - | NOW() | - |

View publica: staff_public (sem email e phone)
RLS: PII visivel apenas para owner e o proprio staff.
Indices: idx_staff_barbershop, idx_staff_user, idx_staff_user_id_active

---

### Tabela: public.services

| Coluna | Tipo | Nulo | Default | Descricao |
|---|---|---|---|---|
| id | UUID | NOT NULL | gen_random_uuid() | PK |
| barbershop_id | UUID | NOT NULL | - | FK barbershops.id ON DELETE CASCADE |
| name | VARCHAR(255) | NOT NULL | - | Nome do servico |
| duration_min | INTEGER | NOT NULL | - | Duracao em minutos (tempo ativo) |
| price | INTEGER | nullable | - | Preco em centavos |
| buffer | INTEGER | - | 0 | Buffer (min) entre atendimentos |
| icon | VARCHAR(50) | nullable | - | Icone |
| active | BOOLEAN | - | TRUE | - |
| sort_order | INTEGER | - | 0 | Ordem de exibicao |
| pause_after_min | INTEGER | nullable | - | Min de trabalho antes da pausa |
| pause_duration_min | INTEGER | nullable | - | Duracao da pausa (min) |
| is_duration_variable | BOOLEAN | - | FALSE | Duracao variavel? |
| max_duration_min | INTEGER | nullable | - | Duracao maxima (variaveis) |
| created_at | TIMESTAMPTZ | - | NOW() | - |
| updated_at | TIMESTAMPTZ | - | NOW() | - |

---

### Tabela: public.staff_services

| Coluna | Tipo | Nulo | Descricao |
|---|---|---|---|
| id | UUID | NOT NULL | PK |
| staff_id | UUID | NOT NULL | FK staff.id ON DELETE CASCADE |
| service_id | UUID | NOT NULL | FK services.id ON DELETE CASCADE |
| created_at | TIMESTAMPTZ | - | - |

UNIQUE: (staff_id, service_id)

---

### Tabela: public.business_hours

| Coluna | Tipo | Nulo | Default | Descricao |
|---|---|---|---|---|
| id | UUID | NOT NULL | gen_random_uuid() | PK |
| barbershop_id | UUID | NOT NULL | - | FK barbershops.id ON DELETE CASCADE |
| day_of_week | SMALLINT | NOT NULL | - | 0=Dom, 6=Sab (CHECK 0..6) |
| open_time | TIME | NOT NULL | - | Hora de abertura |
| close_time | TIME | NOT NULL | - | Hora de fechamento |
| is_open | BOOLEAN | - | TRUE | Se o dia esta aberto |
| breaks | JSONB | - | [] | [{start:"12:00",end:"13:00"}] |
| created_at | TIMESTAMPTZ | - | NOW() | - |
| updated_at | TIMESTAMPTZ | - | NOW() | - |

UNIQUE: (barbershop_id, day_of_week)

---

### Tabela: public.staff_hours

| Coluna | Tipo | Nulo | Default | Descricao |
|---|---|---|---|---|
| id | UUID | NOT NULL | gen_random_uuid() | PK |
| staff_id | UUID | NOT NULL | - | FK staff.id ON DELETE CASCADE |
| day_of_week | SMALLINT | NOT NULL | - | 0=Dom, 6=Sab |
| start_time | TIME | NOT NULL | - | Inicio do turno |
| end_time | TIME | NOT NULL | - | Fim do turno |
| is_working | BOOLEAN | - | TRUE | Se trabalha neste dia |
| created_at | TIMESTAMPTZ | - | NOW() | - |
| updated_at | TIMESTAMPTZ | - | NOW() | - |

UNIQUE: (staff_id, day_of_week)


### Tabela: public.appointments

| Coluna | Tipo | Nulo | Default | Descricao |
|---|---|---|---|---|
| id | UUID | NOT NULL | gen_random_uuid() | PK |
| booking_code | VARCHAR(20) | nullable | - | BKG-YYYYMMDD-NNNN (trigger) |
| barbershop_id | UUID | NOT NULL | - | FK barbershops.id ON DELETE CASCADE |
| staff_id | UUID | NOT NULL | - | FK staff.id ON DELETE SET NULL |
| service_id | UUID | NOT NULL | - | FK services.id ON DELETE SET NULL |
| date | DATE | NOT NULL | - | Data (YYYY-MM-DD) |
| start_time | TIME | NOT NULL | - | Horario de inicio |
| end_time | TIME | NOT NULL | - | Horario de termino |
| status | appointment_status | NOT NULL | AGENDADO | Status atual |
| customer_name | VARCHAR(255) | NOT NULL | - | Nome do cliente (PII) |
| customer_phone | VARCHAR(20) | nullable | - | Telefone do cliente (PII) |
| customer_email | VARCHAR(255) | nullable | - | Email do cliente (PII) |
| notes | TEXT | nullable | - | Observacoes (PII) |
| cancel_reason | TEXT | nullable | - | Motivo do cancelamento |
| canceled_at | TIMESTAMPTZ | nullable | - | - |
| canceled_by | VARCHAR(20) | nullable | - | - |
| canceled_by_user_id | UUID | nullable | - | - |
| confirmed_at | TIMESTAMPTZ | nullable | - | - |
| confirmed_by | TEXT | nullable | - | - |
| has_conflict | BOOLEAN | - | FALSE | Flag de conflito |
| conflict_reason | TEXT | nullable | - | - |
| time_blocks | JSONB | nullable | - | [{start,end}] para servicos com pausa |
| pause_start | TIME | nullable | - | Inicio da pausa |
| pause_end | TIME | nullable | - | Fim da pausa |
| active_duration_min | INTEGER | nullable | - | Duracao ativa (min) |
| cancellation_requested_at | TIMESTAMPTZ | nullable | - | Solicitacao de cancelamento |
| status_before_cancellation | appointment_status | nullable | - | Status anterior |
| pending_new_date | DATE | nullable | - | Nova data no reagendamento |
| pending_new_start_time | TIME | nullable | - | Novo horario proposto |
| pending_new_end_time | TIME | nullable | - | Novo fim proposto |
| reschedule_requested_at | TIMESTAMPTZ | nullable | - | Solicitacao de reagendamento |
| rescheduled_from | UUID | nullable | - | FK appointments.id (original) |
| rescheduled_to | UUID | nullable | - | FK appointments.id (novo) |
| created_by | TEXT | nullable | - | client, staff ou system |
| created_at | TIMESTAMPTZ | - | NOW() | - |
| updated_at | TIMESTAMPTZ | - | NOW() | - |

Indices: barbershop_date, staff_date, status, rescheduled_from, rescheduled_to
Trigger: set_booking_code (gera booking_code automatico)
Realtime: habilitado
View: appointments_safe (mascara PII)

---

### Tabela: public.availability_blocks

| Coluna | Tipo | Nulo | Default | Descricao |
|---|---|---|---|---|
| id | UUID | NOT NULL | gen_random_uuid() | PK |
| staff_id | UUID | NOT NULL | - | FK staff.id |
| barbershop_id | UUID | NOT NULL | - | FK barbershops.id |
| block_type | TEXT | NOT NULL | - | one_time, recurring ou vacation |
| title | TEXT | nullable | - | Titulo |
| is_active | BOOLEAN | - | TRUE | - |
| start_at | TIMESTAMPTZ | nullable | - | Inicio UTC (one_time) |
| end_at | TIMESTAMPTZ | nullable | - | Fim UTC (one_time) |
| weekday | INTEGER | nullable | - | Dia 0-6 (recurring) |
| start_time | TIME | nullable | - | Hora inicio (recurring) |
| end_time | TIME | nullable | - | Hora fim (recurring) |
| effective_from | DATE | nullable | - | Inicio da recorrencia |
| effective_to | DATE | nullable | - | Fim da recorrencia |
| start_date | DATE | nullable | - | Data inicio (vacation) |
| end_date | DATE | nullable | - | Data fim (vacation) |
| created_at | TIMESTAMPTZ | - | NOW() | - |

---

### Tabela: public.time_off (legada)

| Coluna | Tipo | Nulo | Descricao |
|---|---|---|---|
| id | UUID | NOT NULL | PK |
| staff_id | UUID | NOT NULL | FK staff.id ON DELETE CASCADE |
| date | DATE | NOT NULL | Data da folga |
| start_time | TIME | nullable | Inicio (parcial) |
| end_time | TIME | nullable | Fim (parcial) |
| reason | VARCHAR(255) | nullable | Motivo |
| created_at | TIMESTAMPTZ | - | - |

---

### Tabela: public.plans

| Coluna | Tipo | Nulo | Default | Descricao |
|---|---|---|---|---|
| id | UUID | NOT NULL | gen_random_uuid() | PK |
| slug | TEXT | NOT NULL UNIQUE | - | individual,pequeno,medio,grande,trial |
| name | TEXT | NOT NULL | - | Nome do plano |
| description | TEXT | nullable | - | - |
| max_staff | INTEGER | NOT NULL | - | Limite de profissionais |
| price_monthly | INTEGER | NOT NULL | - | Preco mensal em centavos |
| price_yearly | INTEGER | NOT NULL | - | Preco anual em centavos |
| features | JSONB | - | [] | Lista de features |
| active | BOOLEAN | NOT NULL | TRUE | - |
| sort_order | INTEGER | NOT NULL | 0 | - |
| created_at | TIMESTAMPTZ | NOT NULL | NOW() | - |
| updated_at | TIMESTAMPTZ | NOT NULL | NOW() | - |

Planos: individual (1 staff, R/mes), pequeno (3, R), medio (6, R), grande (10, R)

---

### Tabela: public.subscriptions

| Coluna | Tipo | Nulo | Descricao |
|---|---|---|---|
| id | UUID | NOT NULL | PK |
| barbershop_id | UUID | NOT NULL | FK barbershops.id (UNIQUE — 1 assinatura/barbearia) |
| plan_id | UUID | NOT NULL | FK plans.id |
| status | subscription_status | NOT NULL | active,attention,blocked,cancelled |
| billing_cycle | billing_cycle | NOT NULL | monthly ou yearly |
| current_period_start | TIMESTAMPTZ | NOT NULL | - |
| current_period_end | TIMESTAMPTZ | NOT NULL | - |
| trial_start | TIMESTAMPTZ | nullable | - |
| trial_end | TIMESTAMPTZ | nullable | - |
| canceled_at | TIMESTAMPTZ | nullable | - |
| cancel_reason | TEXT | nullable | - |
| stripe_customer_id | TEXT | nullable | - |
| stripe_subscription_id | TEXT | nullable | - |
| stripe_price_id | TEXT | nullable | - |
| override_reason | TEXT | nullable | Override manual por admin |
| override_by | UUID | nullable | Admin que fez override |
| grace_period_end | TIMESTAMPTZ | nullable | - |
| created_at | TIMESTAMPTZ | NOT NULL | - |
| updated_at | TIMESTAMPTZ | NOT NULL | - |

---

### Tabela: public.customers

| Coluna | Tipo | Nulo | Default | Descricao |
|---|---|---|---|---|
| id | UUID | NOT NULL | gen_random_uuid() | PK |
| barbershop_id | UUID | NOT NULL | - | FK barbershops.id ON DELETE CASCADE |
| phone | VARCHAR | NOT NULL | - | Chave de identificacao |
| name | VARCHAR | NOT NULL | - | Nome |
| email | VARCHAR | nullable | - | Email |
| notes | TEXT | nullable | - | Notas internas |
| birthday | DATE | nullable | - | Data de nascimento |
| total_appointments | INTEGER | NOT NULL | 0 | Total de agendamentos |
| last_appointment_at | TIMESTAMPTZ | nullable | - | - |
| created_at | TIMESTAMPTZ | NOT NULL | NOW() | - |
| updated_at | TIMESTAMPTZ | NOT NULL | NOW() | - |

UNIQUE: (barbershop_id, phone)
RLS: apenas staff autenticado da barbearia

---

### Tabela: public.consents (usuarios da plataforma)

| Coluna | Tipo | Nulo | Descricao |
|---|---|---|---|
| id | UUID | NOT NULL | PK |
| user_id | UUID | NOT NULL | FK auth.users.id |
| barbershop_id | UUID | NOT NULL | FK barbershops.id |
| terms_accepted | BOOLEAN | NOT NULL | Aceite dos termos |
| terms_accepted_at | TIMESTAMPTZ | nullable | - |
| privacy_accepted | BOOLEAN | NOT NULL | Aceite de privacidade |
| privacy_accepted_at | TIMESTAMPTZ | nullable | - |
| marketing_accepted | BOOLEAN | - | - |
| marketing_accepted_at | TIMESTAMPTZ | nullable | - |
| ip_address | INET | nullable | - |
| user_agent | TEXT | nullable | - |
| created_at | TIMESTAMPTZ | - | - |

---

### Tabela: public.customer_consents (clientes finais — LGPD)

| Coluna | Tipo | Nulo | Descricao |
|---|---|---|---|
| id | UUID | NOT NULL | PK |
| barbershop_id | UUID | NOT NULL | FK barbershops.id |
| phone | VARCHAR | NOT NULL | Telefone do cliente |
| policy_version | TEXT | NOT NULL | Versao da politica (ex: 1.0) |
| accepted_at | TIMESTAMPTZ | - | - |

UNIQUE: (barbershop_id, phone)

---

### Tabela: public.notification_preferences

| Coluna | Tipo | Default | Descricao |
|---|---|---|---|
| id | UUID | gen_random_uuid() | PK |
| user_id | UUID | - | FK auth.users.id |
| barbershop_id | UUID | - | FK barbershops.id |
| new_appointments | BOOLEAN | TRUE | Notif novos agendamentos |
| appointment_reminders | BOOLEAN | TRUE | Lembretes |
| cancellations | BOOLEAN | TRUE | Cancelamentos |
| email_notifications | BOOLEAN | TRUE | Por email |
| whatsapp_notifications | BOOLEAN | FALSE | Por WhatsApp |
| daily_summary | BOOLEAN | TRUE | Resumo diario |
| daily_summary_time | TIME | 08:00 | Horario do resumo |

---

### Tabela: public.notifications

| Coluna | Tipo | Nulo | Descricao |
|---|---|---|---|
| id | UUID | NOT NULL | PK |
| user_id | UUID | NOT NULL | FK auth.users.id |
| barbershop_id | UUID | NOT NULL | FK barbershops.id |
| type | TEXT | NOT NULL | NEW_APPOINTMENT, CANCELLATION, REMINDER |
| title | TEXT | NOT NULL | - |
| body | TEXT | nullable | - |
| data | JSONB | nullable | Payload estruturado |
| read | BOOLEAN | - | Se foi lida |
| created_at | TIMESTAMPTZ | - | - |

---

### Tabela: public.push_subscriptions

| Coluna | Tipo | Nulo | Descricao |
|---|---|---|---|
| id | UUID | NOT NULL | PK |
| user_id | UUID | NOT NULL | FK auth.users.id |
| barbershop_id | UUID | NOT NULL | FK barbershops.id |
| endpoint | TEXT | NOT NULL | URL do endpoint WebPush |
| p256dh | TEXT | NOT NULL | Chave publica P-256 |
| auth | TEXT | NOT NULL | Auth secret |
| user_agent | TEXT | nullable | - |
| created_at | TIMESTAMPTZ | - | - |

---

### Tabela: public.role_permissions

Cargo owner — permissoes: manage_services, manage_staff, manage_business_hours,
manage_agenda_visibility, view_all_agendas, create_appointments, manage_any_appointment,
manage_availability_blocks, manage_barbershop, delete_business, view_metrics,
manage_payments, manage_notifications, assign_services_to_staff, edit_own_profile

Cargo barber — permissoes: view_own_agenda, create_own_appointments, manage_own_appointments,
manage_own_availability_blocks, edit_own_profile, manage_own_notifications, start_pause_finish_service

---

### Tabela: public.internal_admins (Hairdule interno)

Apenas service_role tem acesso. Campos: id, email (UNIQUE), user_id, name, level, invited_by, requires_password_change, is_active, created_at, updated_at

---

### Tabela: public.suggestion_tracking (sugestoes IA)

Apenas service_role tem acesso.
Campos: id, barbershop_id, customer_id, suggestion_rank, confidence (high/medium/low), score,
suggested_date, suggested_start_time, services (JSONB), score_breakdown (JSONB),
outcome (pending/accepted/modified/rejected/expired), resulting_appointment_id, created_at, resolved_at

---

### Tabela: public.appointment_audit_log

Campos: id, appointment_id, barbershop_id, field_name, old_value, new_value, changed_by, changed_at, reason, source (staff/client/system), metadata (JSONB)

---

### Tabela: public.admin_activity_log

Apenas service_role. Campos: id, barbershop_id, user_id, event_type, metadata (JSONB), created_at

---

### Views

- appointments_safe: mascara PII — customer_name="Primeiro ***", phone=NULL, email=NULL, notes=NULL para nao-autorizados
- staff_public: sem email e phone — para portal publico
- plans_public: planos para leitura publica

---

### Funcoes SQL Helper

- get_user_barbershop_id(_user_id) → UUID
- has_barbershop_role(_user_id, _barbershop_id, _role) → BOOLEAN
- is_barbershop_owner(_user_id, _barbershop_id) → BOOLEAN
- get_user_staff_id(_user_id) → UUID
- get_staff_agenda_visibility(_user_id) → agenda_visibility
- can_see_appointment_pii(_staff_id, _barbershop_id) → BOOLEAN
- get_subscription_status(_barbershop_id) → JSONB
- can_barbershop_write(_barbershop_id) → BOOLEAN
- can_add_staff(_barbershop_id) → BOOLEAN
- has_permission(_user_id, _permission) → BOOLEAN
- get_user_permissions(_user_id) → SETOF TEXT
- generate_booking_code() → TRIGGER
- upsert_customer(...) → RPC


---

## 5. Rotas de API

Base URL: https://<PROJECT_ID>.supabase.co/functions/v1/<function>
Local: http://127.0.0.1:54321/functions/v1/<function>
Headers autenticados: Authorization: Bearer <jwt>, Content-Type: application/json, apikey: <anon_key>

---

### POST /auth-signup (Publico)

Cria usuario, barbearia, role de owner e staff em operacao atomica.

Request:
{
  email: "obrigatorio",
  password: "obrigatorio (min 6 chars)",
  tradeName: "obrigatorio (nome fantasia)",
  ownerName: "opcional",
  cnpj: "opcional",
  razaoSocial: "opcional",
  whatsapp: "opcional",
  segment: "opcional",
  bookingMode: "opcional (manual|online, default: manual)",
  address: { cep, logradouro, numero, complemento, bairro, cidade, estado }
}

Response 201:
{
  tokens: { accessToken, refreshToken },
  user: { id, email, role: "owner" },
  barbershop: { barbershopId, tradeName, status: "ONBOARDING" }
}

Erros: 400 (VALIDATION_ERROR, INVALID_EMAIL_FORMAT), 409 (EMAIL_ALREADY_EXISTS, CNPJ_ALREADY_EXISTS),
422 (PASSWORD_COMPROMISED), 500 (BARBERSHOP_ERROR, ROLE_ERROR)

---

### POST /auth-login (Publico)

Request: { email, password }
Response 200: { tokens: {accessToken, refreshToken}, user: {id, email}, barbershop: {id, nome_fantasia, status} }

---

### POST /auth-forgot-password (Publico)

Request: { email } | Response: { message }

---

### POST /auth-reset-password

Request: { token, password }

---

### POST /auth-change-password (JWT obrigatorio)

Request: { currentPassword, newPassword }

---

### GET /barbershop-get (JWT obrigatorio)

Response: objeto completo do barbershop (nome, endereco, configuracoes)

---

### PUT /barbershop-update (JWT obrigatorio — apenas owner)

Request: qualquer campo do barbershop (todos opcionais)

---

### GET /appointments-manage?mode=list&date=YYYY-MM-DD (JWT obrigatorio)

Params opcionais: staff_id (filtrar por profissional)

Response 200:
{
  date: "YYYY-MM-DD",
  appointments: [{
    id, booking_code: "BKG-YYYYMMDD-XXXX",
    date, start_time, end_time, status: "AGENDADO",
    customer_name: "(mascarado para nao-autorizados)",
    customer_phone, customer_email, notes,
    staff_id, service_id,
    time_blocks: "[{start,end}]|null",
    pause_start, pause_end
  }]
}

---

### GET /appointments-manage?mode=availability&date=YYYY-MM-DD (JWT obrigatorio)

Params opcionais: staff_id, service_id, custom_duration_min (5-480), exclude_appointment_id

Response 200:
{
  date, closed: false, business_hours_week: [...],
  staff: [{
    staff_id, staff_name, avatar_url,
    business_hours: { open, close, breaks },
    available_slots: ["09:00", "09:30"],
    occupied_slots: [{ start, end, appointment_id, customer_name, service_name, status }],
    blocked_slots: [{ start, end, reason, type: "recurring|one_time|vacation|time_off|break" }]
  }]
}

---

### GET /appointments-manage?mode=audit_log&appointment_id=<uuid> (JWT obrigatorio)

Param opcional: limit (default 100, max 100)
Response: { audit_log: [{ id, field_name, old_value, new_value, changed_by, changed_at, reason, source, metadata }] }

---

### POST /appointments-manage (JWT obrigatorio) — Criar agendamento pelo staff

Request:
{
  date: "YYYY-MM-DD (obrigatorio)",
  start_time: "HH:MM (obrigatorio)",
  customer_name: "obrigatorio",
  staff_id: "uuid (obrigatorio)",
  service_id: "uuid (obrigatorio)",
  customer_phone: "opcional",
  customer_email: "opcional",
  notes: "opcional",
  custom_duration_min: "opcional (para variaveis)",
  custom_price: "opcional (centavos, modo manual)",
  time_blocks: "[{start,end}] opcional (para servicos com pausa)",
  rescheduled_from: "uuid opcional (ID original)"
}

Response 201: { id, booking_code, date, start_time, end_time, status: "AGENDADO" }

Erros: 400 (campos ausentes, passado, fora horario, duracao invalida), 403 (assinatura bloqueada),
409 (conflito de horario, profissional indisponivel)

---

### PUT /appointments-manage (JWT obrigatorio)

Request: { id (obrigatorio), status?, date?, start_time?, notes?, cancel_reason? (obrigatorio se cancelando) }

---

### POST /public-booking (Publico) — Agendamento pelo cliente final

Request:
{
  barbershop_id: "uuid (obrigatorio)",
  service_id: "uuid (obrigatorio)",
  staff_id: "uuid (obrigatorio)",
  date: "YYYY-MM-DD (obrigatorio)",
  start_time: "HH:MM (obrigatorio)",
  customer_name: "obrigatorio (min 2 chars)",
  customer_phone: "obrigatorio (10-11 digitos BR)",
  customer_email: "obrigatorio (para magic link de cancelamento)",
  notes: "opcional (max 500 chars)",
  consent_accepted: "boolean (obrigatorio na 1a vez por telefone/barbearia)"
}

Response 201:
{
  id, booking_code, date, start_time, end_time, status: "AGENDADO",
  customer_name, service_name, staff_name
}

Erros: 400 (campos ausentes, formato, passado, OUT_OF_BUSINESS_HOURS, LGPD_CONSENT_REQUIRED),
403 (assinatura bloqueada), 404 (barbearia/servico/staff nao encontrado),
405 (metodo invalido), 409 (SLOT_TAKEN, EMPLOYEE_UNAVAILABLE)

---

### GET /public-availability (Publico)

Query: barbershop_id (obrigatorio), date (obrigatorio), service_id?, staff_id?

---

### GET /public-barbershop (Publico) — Query: slug ou id

### GET /public-services (Publico) — Query: barbershop_id (obrigatorio)

### GET /public-staff (Publico) — Query: barbershop_id (obrigatorio)

### GET /public-appointments-by-phone (Publico) — Query: phone, barbershop_id

---

### Cancelamento / Reagendamento Publico

| Metodo | Rota | Descricao |
|---|---|---|
| POST | /public-cancel-confirm | Confirmar cancelamento via magic link |
| POST | /public-cancel-revert | Reverter solicitacao de cancelamento |
| POST | /public-reschedule-confirm | Confirmar reagendamento |
| POST | /public-reschedule-revert | Reverter reagendamento |

---

### Staff (JWT obrigatorio)

GET /staff-manage — Listar profissionais (com servicos associados)
POST /staff-manage — Criar (apenas owner) — Body: { name (obrig), email?, phone?, role (obrig), service_ids?, agenda_visibility? }
PUT /staff-manage — Atualizar — Body: { id (obrig), ...campos }
DELETE /staff-manage?id=uuid — Remover (apenas owner)

---

### Servicos (JWT obrigatorio)

GET /services-manage — Listar
POST /services-manage — Criar — Body: { name, duration_min (obrig), price?, buffer?, icon?, active?, pause_after_min?, pause_duration_min?, is_duration_variable?, max_duration_min? }
PUT /services-manage — Atualizar
DELETE /services-manage?id=uuid — Remover

---

### Horarios de Funcionamento (JWT obrigatorio)

GET /business-hours-manage — Listar
POST /business-hours-manage — Criar/atualizar — Body: { day_of_week (0-6), open_time, close_time (obrig), is_open?, breaks? }

---

### Bloqueios de Disponibilidade (JWT obrigatorio)

GET /availability-blocks-manage
POST /availability-blocks-manage — Body: {
  staff_id (obrig), block_type (one_time|recurring|vacation obrig), title?,
  start_at/end_at (ISO8601 UTC — para one_time),
  weekday/start_time/end_time (para recurring),
  effective_from/effective_to (opcionals para recurring),
  start_date/end_date (para vacation)
}
PUT /availability-blocks-manage
DELETE /availability-blocks-manage?id=uuid

---

### Analytics (JWT obrigatorio)

GET /analytics — Query: period (7d|30d|90d), date_from, date_to
Response: metricas de agendamentos, receita, taxa de cancelamento, profissionais mais ativos, etc.

---

### Inteligencia Artificial (JWT obrigatorio)

POST /ai-insights — Insights sobre o estabelecimento

POST /smart-booking-suggestion — Sugestao inteligente de horario
Body: { customer_phone, service_ids: ["uuid"], preferred_staff_id? }

---

### Notificacoes (JWT obrigatorio)

GET /notifications-manage — Listar in-app
PUT /notifications-manage — Marcar como lida
GET /notification-preferences-manage — Obter preferencias
PUT /notification-preferences-manage — Atualizar preferencias
POST /push-subscriptions — Registrar push (body: { endpoint, p256dh, auth, user_agent? })
DELETE /push-subscriptions — Remover push

---

### Assinaturas

GET /subscription-check (JWT obrigatorio)
Response: { has_subscription, status (active|attention|blocked|cancelled), can_write, plan_slug, plan_name,
max_staff, current_staff, can_add_staff, current_period_end, is_trial, needs_plan_selection, billing_cycle }

POST /subscription-select-plan (JWT obrigatorio)
Body: { plan_slug: "individual|pequeno|medio|grande", billing_cycle: "monthly|yearly" }

POST /stripe-webhook — Header: Stripe-Signature

---

### Onboarding (JWT obrigatorio)

POST /onboarding-complete
Body: {
  barbershopId (obrig),
  profile: { cnpj, corporateName, tradeName, address: { cep, street, number, complement, district, city, state } },
  segment,
  professionals: [{ email, role: "owner|barber" }],
  services: [{ name, durationMin, price, active, buffer }],
  schedule: { days: ["mon","tue",...], hours: { monday: { start, end } } },
  consents: { privacy: true, terms: true }
}
Response: { status: "READY", barbershopId, next: "dashboard", summary: { professionals, services, workingDays } }

---

### Upload de Fotos (JWT obrigatorio)

POST /photo-upload — Content-Type: multipart/form-data, campo: file
Storage path: photos/barbershops/<barbershop_id>/staff/<staff_id>/<filename>

---

### LGPD / Consentimentos

GET /consents-manage (JWT) — Verificar
POST /consents-manage (JWT) — Registrar
POST /public-consent (Publico) — Consentimento do cliente final

---

### Portal do Cliente

GET /customer-portal — Autenticacao: magic link token (enviado por email)

---

### Admin da Plataforma (Hairdule interno)

POST /admin-login, GET /admin-dashboard, DELETE /admin-delete-barbershop, POST /admin-push-broadcast

---

### Tarefas Agendadas

auto-status-transition — Transicao automatica de status
revert-pending-cancellations — Reverter cancelamentos expirados
send-appointment-reminders — Enviar lembretes
rate-limit-cleanup — Limpar rate limiting
scheduled-tasks — Orquestrador
appointments-retrospective — Processamento retroativo

---

### Outros Endpoints Publicos

GET /public-lookup — Buscar estabelecimento por slug/CNPJ
GET /check-availability — Verificar disponibilidade (alternativa)
GET /availability-week — Disponibilidade semanal
GET /my-services — Servicos do staff autenticado


---

## 6. Regras de Negocio

### Status de Agendamento — Maquina de Estados

AGENDADO → CONFIRMADO → EM_ATENDIMENTO → FINALIZADO
AGENDADO → CANCELADO_CLIENTE | CANCELADO_BARBEARIA | NAO_COMPARECEU
CONFIRMADO → CANCELADO_CLIENTE | CANCELADO_BARBEARIA | NAO_COMPARECEU
EM_ATENDIMENTO → CANCELADO_BARBEARIA
AGENDADO → REMARCADO (quando substituido por novo agendamento via reagendamento)

---

### Logica de Conflito de Horarios

Hierarquia de verificacoes:
1. Horario de funcionamento (business_hours)
2. Intervalos da barbearia (campo breaks JSONB)
3. Agendamentos existentes do mesmo profissional
4. Bloqueios de disponibilidade (availability_blocks)
5. Folgas legadas (time_off)

Buffer: footprint efetivo = end_time + buffer_do_servico
Status ignorados no conflito: CANCELADO_CLIENTE, CANCELADO_BARBEARIA, REMARCADO

---

### Servicos com Pausa (Dual-Block)

Exemplo: coloracao onde cliente aguarda produto agir.

- pause_after_min: minutos de trabalho antes da pausa
- pause_duration_min: duracao da pausa (staff livre)
- duration_min: apenas tempo de trabalho ativo (SEM a pausa)
- Tempo total reservado = duration_min + pause_duration_min

Dois blocos de trabalho em time_blocks. A pausa nao e verificada para conflito.
Para servicos variaveis (is_duration_variable=true), booking publico reserva max_duration_min por padrao.

---

### Visibilidade de Agenda

OWN_ONLY: staff ve apenas seus proprios agendamentos, PII visivel so nos proprios
TEAM_READ_ONLY: ve agenda de todos, mas PII mascarada via appointments_safe
Owner: ve tudo com PII completo

Mascara PII (appointments_safe):
- customer_name = "Primeiro ***"
- customer_phone = NULL
- customer_email = NULL
- notes = NULL

---

### Booking Publico vs Manual

Manual: so staff cria, email opcional, slot_interval_min configuravel
Online: cliente cria via portal, email obrigatorio (magic link), LGPD obrigatorio na 1a vez

---

### Codigo de Agendamento

Trigger automatico no INSERT: BKG-YYYYMMDD-NNNN
NNNN = sequencial por barbearia/data

---

### Fluxo de Reagendamento

1. Novo agendamento com rescheduled_from = <id_original>
2. Original → status REMARCADO
3. Original recebe rescheduled_to = <id_novo>

---

## 7. Seguranca e Permissoes

### RLS

Anonimo: apenas dados publicos (barbearias ACTIVE, servicos ativos, staff_public)
Autenticado: limitado a propria barbearia via get_user_barbershop_id(auth.uid())
Owner: completo na barbearia
Service Role: irrestrito (Edge Functions)

### Protecao de PII

Staff: email/phone visivel apenas para owner e o proprio staff
Appointments: PII mascarada via appointments_safe para staff sem permissao
Customers: apenas staff autenticado da barbearia

### Controle de Escrita por Assinatura

can_barbershop_write() verificada antes de criar agendamentos.
Status blocked ou cancelled bloqueiam a operacao.

### Trigger de Protecao

protect_staff_sensitive_fields(): apenas owner pode alterar role, active, agenda_visibility, barbershop_id.

---

## 8. Sistema de Assinaturas

### Ciclo

1. Trial ao criar conta (plano trial)
2. Apos trial: selecionar plano pago via /subscription-select-plan
3. Stripe: cobranca recorrente mensal/anual
4. Status attention: falha de pagamento, periodo de graca, ainda pode operar
5. Status blocked: bloqueia criacao de novos agendamentos

### Status vs Permissoes

| Status | Criar agendamentos | Ver agenda |
|---|---|---|
| active | Sim | Sim |
| attention | Sim | Sim |
| blocked | Nao | Sim |
| cancelled | Nao | Sim |

### Limites

individual: 1 staff, R/mes, R,80/ano
pequeno: 3 staff, R/mes, R,80/ano
medio: 6 staff, R/mes, R.417,80/ano
grande: 10 staff, R/mes, R.029,80/ano

---

## 9. Notificacoes e Push

### Tipos

NEW_APPOINTMENT — agendamento criado pelo cliente via portal publico
CANCELLATION — cancelamento pelo cliente
REMINDER — lembrete antes do agendamento

NOTA: Acoes do staff (criar/cancelar pelo dashboard) NAO geram push, apenas notificacoes in-app.

### Fluxo Push (WebPush VAPID)

1. Staff registra subscricao via POST /push-subscriptions (endpoint, p256dh, auth)
2. Booking publico → send-push-notification → push para staff responsavel + owner
3. Payload: { type, customer_name, service_name, date, start_time, appointment_id }

### Preferencias

Cada staff pode desabilitar individualmente: new_appointments, appointment_reminders, cancellations,
email_notifications, whatsapp_notifications, daily_summary

---

## 10. PWA e Frontend

### Feature Flags (src/lib/features.ts)

ANALYTICS — Dashboard de metricas
NOTIFICATIONS — Push notifications
ONLINE_BOOKING — Portal de agendamento publico

### Design System

- Cor primaria: Aqua #22BEF5
- Tema: light/dark (next-themes)
- Componentes: shadcn/ui + Radix UI
- Icones: Lucide React
- Animacoes: animate-fade-in, animate-slide-up

### Onboarding (5 etapas)

1. Register → POST /auth-signup
2. BusinessType (dados salvos no localStorage)
3. StaffCount (dados salvos no localStorage)
4. Services (dados salvos no localStorage)
5. Hours/TimeSlots → POST /onboarding-complete (envia tudo de uma vez)

---

## 11. Integracoes Externas

Stripe — Pagamentos e assinaturas (webhook: /stripe-webhook, header: Stripe-Signature)
WebPush/VAPID — Push no navegador (sem app nativo necessario)
Supabase Auth — JWT, sessoes, reset de senha
Supabase Storage — Fotos (bucket photos, path: photos/barbershops/<id>/staff/<id>/<file>)
Supabase Realtime — Agenda em tempo real (tabela appointments)
Sentry — Monitoramento de erros em producao (frontend)
ViaCEP — Autocomplete de endereco por CEP no onboarding

---

## Notas para Desenvolvedores

TIMEZONE: America/Sao_Paulo em toda a logica de negocio.
Blocos one_time (availability_blocks) sao armazenados em UTC e convertidos na aplicacao.

PRECOS EM CENTAVOS: price (services), price_monthly e price_yearly (plans) sao INTEGER.
Exemplo: R$ 39,00 = 3900.

DOIS CLIENTES SUPABASE nas Edge Functions autenticadas:
1. supabase (anon key + JWT do usuario) — para validar identidade via RLS
2. supabaseAdmin (service role key) — para operacoes que precisam bypassar RLS

IDEMPOTENCIA: O cliente HTTP do frontend envia Idempotency-Key (UUID v4) em todas as mutacoes
(POST, PUT, PATCH, DELETE) para evitar duplicacoes em caso de retry.

TRIGGER DE SEGURANCA: protect_staff_sensitive_fields() garante que barbers nao possam alterar
role, active, agenda_visibility ou barbershop_id — apenas owners tem esse poder, mesmo que RLS
permita o UPDATE.

SLOT INTERVAL: configuravel via slot_interval_min no barbershop.
Para servicos menores que 30min, o intervalo de slots igual a duracao do servico.

BOOKING CODE: gerado por trigger SQL no INSERT em appointments.
Formato: BKG-YYYYMMDD-NNNN onde NNNN e o contador sequencial por barbearia/data.
