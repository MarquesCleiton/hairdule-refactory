-- =====================================================================
-- HAIRDULE 2.0 — BANCO DE DADOS COMPLETO (PostgreSQL 16)
-- Script SQL Puro (Apenas Tabelas de Domínio, Tabelas de Negócio e Índices)
-- Sem Triggers, Sem Funcoes e Sem Views (Regras mantidas nos serviços)
-- =====================================================================

-- Extensoes necessarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================================
-- 1. TABELAS DE DOMÍNIO (LOOKUP TABLES)
-- =====================================================================

-- 1.1 Segmentos de Negocio
CREATE TABLE IF NOT EXISTS domain_business_types (
    code VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    display_order INT DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 1.2 Status do Estabelecimento
CREATE TABLE IF NOT EXISTS domain_barbershop_statuses (
    code VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    display_order INT DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 1.3 Cargos / Roles da Equipe
CREATE TABLE IF NOT EXISTS domain_staff_roles (
    code VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    display_order INT DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 1.4 Visibilidade da Agenda
CREATE TABLE IF NOT EXISTS domain_agenda_visibilities (
    code VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    display_order INT DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 1.5 Status do Agendamento
CREATE TABLE IF NOT EXISTS domain_appointment_statuses (
    code VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    display_order INT DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 1.6 Status da Assinatura
CREATE TABLE IF NOT EXISTS domain_subscription_statuses (
    code VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    display_order INT DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 1.7 Ciclo de Cobranca
CREATE TABLE IF NOT EXISTS domain_billing_cycles (
    code VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    display_order INT DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 1.8 Tipos de Bloqueio de Agenda
CREATE TABLE IF NOT EXISTS domain_block_types (
    code VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    display_order INT DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 1.9 Tipos de Notificacao
CREATE TABLE IF NOT EXISTS domain_notification_types (
    code VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    display_order INT DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 1.10 Status de Moderacao de Midia / Fotos
CREATE TABLE IF NOT EXISTS domain_moderation_statuses (
    code VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    display_order INT DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- =====================================================================
-- 2. SEED DE DADOS ESTÁTICOS NAS TABELAS DE DOMÍNIO
-- =====================================================================

INSERT INTO domain_business_types (code, name, display_order) VALUES
('BARBERSHOP', 'Barbearia', 1),
('SALON', 'Salão de Beleza', 2),
('SPA', 'Spa & Estética', 3),
('NAIL_DESIGN', 'Nail Design & Esmalteria', 4),
('OTHER', 'Outro Segmento', 99)
ON CONFLICT (code) DO NOTHING;

INSERT INTO domain_barbershop_statuses (code, name, display_order) VALUES
('ONBOARDING', 'Em Cadastro', 1),
('ACTIVE', 'Ativo', 2),
('INACTIVE', 'Inativo', 3),
('SUSPENDED', 'Suspenso', 4)
ON CONFLICT (code) DO NOTHING;

INSERT INTO domain_staff_roles (code, name, display_order) VALUES
('OWNER', 'Dono / Administrador', 1),
('MANAGER', 'Gerente', 2),
('BARBER', 'Profissional / Barbeiro', 3),
('RECEPTIONIST', 'Recepcionista', 4)
ON CONFLICT (code) DO NOTHING;

INSERT INTO domain_agenda_visibilities (code, name, display_order) VALUES
('OWN_ONLY', 'Apenas Própria Agenda', 1),
('TEAM_READ_ONLY', 'Agenda do Time (Leitura)', 2),
('ALL_FULL', 'Acesso Completo', 3)
ON CONFLICT (code) DO NOTHING;

INSERT INTO domain_appointment_statuses (code, name, display_order) VALUES
('AGENDADO', 'Agendado', 1),
('CONFIRMADO', 'Confirmado pelo Cliente', 2),
('EM_ATENDIMENTO', 'Em Atendimento', 3),
('FINALIZADO', 'Finalizado', 4),
('CANCELADO_CLIENTE', 'Cancelado pelo Cliente', 5),
('CANCELADO_BARBEARIA', 'Cancelado pelo Estabelecimento', 6),
('NAO_COMPARECEU', 'Não Compareceu (No-Show)', 7),
('REMARCADO', 'Remarcado', 8)
ON CONFLICT (code) DO NOTHING;

INSERT INTO domain_subscription_statuses (code, name, display_order) VALUES
('TRIAL', 'Período de Teste', 1),
('ACTIVE', 'Assinatura Ativa', 2),
('ATTENTION', 'Pagamento Pendente', 3),
('GRACE_PERIOD', 'Período de Carência', 4),
('BLOCKED', 'Acesso Bloqueado', 5),
('CANCELLED', 'Cancelado', 6)
ON CONFLICT (code) DO NOTHING;

INSERT INTO domain_billing_cycles (code, name, display_order) VALUES
('MONTHLY', 'Mensal', 1),
('YEARLY', 'Anual', 2)
ON CONFLICT (code) DO NOTHING;

INSERT INTO domain_block_types (code, name, display_order) VALUES
('ONE_TIME', 'Bloqueio Pontual', 1),
('RECURRING', 'Bloqueio Recorrente', 2),
('VACATION', 'Férias / Ausência Prolongada', 3)
ON CONFLICT (code) DO NOTHING;

INSERT INTO domain_notification_types (code, name, display_order) VALUES
('NEW_APPOINTMENT', 'Novo Agendamento', 1),
('CANCELLATION', 'Cancelamento', 2),
('REMINDER', 'Lembrete', 3),
('SYSTEM', 'Comunicado do Sistema', 4)
ON CONFLICT (code) DO NOTHING;

INSERT INTO domain_moderation_statuses (code, name, description, display_order) VALUES
('APPROVED', 'Aprovado', 'Conteúdo aprovado pelas diretrizes de moderação', 1),
('FLAGGED', 'Sinalizado', 'Conteúdo com alerta sob revisão', 2),
('REJECTED', 'Rejeitado', 'Conteúdo reprovado por violação das diretrizes', 3),
('PENDING_REVIEW', 'Em Revisão', 'Aguardando avaliação manual do administrador', 4)
ON CONFLICT (code) DO NOTHING;

-- =====================================================================
-- 3. TABELAS DE NEGÓCIO DA APLICAÇÃO
-- =====================================================================

-- 3.1 Barbershops (Estabelecimentos)
CREATE TABLE IF NOT EXISTS barbershops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id VARCHAR(255) NOT NULL,
    trade_name VARCHAR(255) NOT NULL,
    legal_name VARCHAR(255),
    document_cnpj VARCHAR(20) UNIQUE,
    business_type_code VARCHAR(50) NOT NULL DEFAULT 'BARBERSHOP' REFERENCES domain_business_types(code),
    status_code VARCHAR(50) NOT NULL DEFAULT 'ONBOARDING' REFERENCES domain_barbershop_statuses(code),
    phone VARCHAR(30),
    email VARCHAR(255),
    slug VARCHAR(100) UNIQUE,
    
    address_zip_code VARCHAR(20),
    address_street VARCHAR(255),
    address_number VARCHAR(20),
    address_complement VARCHAR(100),
    address_neighborhood VARCHAR(100),
    address_city VARCHAR(100),
    address_state VARCHAR(2),
    
    slot_interval_min INT NOT NULL DEFAULT 30,
    booking_mode VARCHAR(50) NOT NULL DEFAULT 'online',
    logo_url TEXT,
    banner_url TEXT,
    custom_domain VARCHAR(255),
    settings JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.2 User Roles (Permissoes Usuário ↔ Barbearia)
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    barbershop_id UUID NOT NULL REFERENCES barbershops(id) ON DELETE CASCADE,
    role_code VARCHAR(50) NOT NULL REFERENCES domain_staff_roles(code),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_barbershop UNIQUE (user_id, barbershop_id)
);

-- 3.3 Staff (Profissionais)
CREATE TABLE IF NOT EXISTS staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barbershop_id UUID NOT NULL REFERENCES barbershops(id) ON DELETE CASCADE,
    user_id VARCHAR(255),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(30),
    role_code VARCHAR(50) NOT NULL DEFAULT 'BARBER' REFERENCES domain_staff_roles(code),
    agenda_visibility_code VARCHAR(50) NOT NULL DEFAULT 'ALL_FULL' REFERENCES domain_agenda_visibilities(code),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.4 Services (Serviços)
CREATE TABLE IF NOT EXISTS services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barbershop_id UUID NOT NULL REFERENCES barbershops(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price_cents INT NOT NULL,
    duration_min INT NOT NULL,
    buffer_min INT NOT NULL DEFAULT 0,
    pause_after_min INT,
    pause_duration_min INT,
    is_duration_variable BOOLEAN NOT NULL DEFAULT FALSE,
    max_duration_min INT,
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    category VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.5 Staff Services (Vínculo N:N Profissional ↔ Serviço)
CREATE TABLE IF NOT EXISTS staff_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_staff_service UNIQUE (staff_id, service_id)
);

-- 3.6 Business Hours (Horários do Estabelecimento)
CREATE TABLE IF NOT EXISTS business_hours (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barbershop_id UUID NOT NULL REFERENCES barbershops(id) ON DELETE CASCADE,
    day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    is_open BOOLEAN NOT NULL DEFAULT TRUE,
    open_time VARCHAR(8),
    close_time VARCHAR(8),
    breaks JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_barbershop_day UNIQUE (barbershop_id, day_of_week)
);

-- 3.7 Staff Hours (Horários por Profissional)
CREATE TABLE IF NOT EXISTS staff_hours (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
    day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    is_working BOOLEAN NOT NULL DEFAULT TRUE,
    start_time VARCHAR(8),
    end_time VARCHAR(8),
    breaks JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_staff_day UNIQUE (staff_id, day_of_week)
);

-- 3.8 Customers (Base de Clientes)
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barbershop_id UUID NOT NULL REFERENCES barbershops(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    email VARCHAR(255),
    notes TEXT,
    total_appointments INT NOT NULL DEFAULT 0,
    no_show_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_barbershop_customer_phone UNIQUE (barbershop_id, phone)
);

-- 3.9 Appointments (Agendamentos)
CREATE TABLE IF NOT EXISTS appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barbershop_id UUID NOT NULL REFERENCES barbershops(id) ON DELETE CASCADE,
    staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE RESTRICT,
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE RESTRICT,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    
    booking_code VARCHAR(30) NOT NULL UNIQUE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    duration_min INT NOT NULL,
    price_cents INT NOT NULL,
    status_code VARCHAR(50) NOT NULL DEFAULT 'AGENDADO' REFERENCES domain_appointment_statuses(code),
    
    customer_name VARCHAR(255) NOT NULL,
    customer_phone VARCHAR(30) NOT NULL,
    customer_email VARCHAR(255),
    notes TEXT,
    
    cancel_reason TEXT,
    canceled_at TIMESTAMPTZ,
    canceled_by VARCHAR(50),
    canceled_by_user_id VARCHAR(255),
    
    rescheduled_from_id UUID REFERENCES appointments(id),
    rescheduled_to_id UUID REFERENCES appointments(id),
    time_blocks JSONB DEFAULT '[]'::jsonb,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.10 Appointment Audit Logs
CREATE TABLE IF NOT EXISTS appointment_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
    field_changed VARCHAR(100) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    changed_by_user_id VARCHAR(255),
    source VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.11 Availability Blocks (Bloqueios e Folgas)
CREATE TABLE IF NOT EXISTS availability_blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barbershop_id UUID NOT NULL REFERENCES barbershops(id) ON DELETE CASCADE,
    staff_id UUID REFERENCES staff(id) ON DELETE CASCADE,
    block_type_code VARCHAR(50) NOT NULL DEFAULT 'ONE_TIME' REFERENCES domain_block_types(code),
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.12 Plans (Planos da Plataforma)
CREATE TABLE IF NOT EXISTS plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    max_staff INT NOT NULL,
    monthly_price_cents INT NOT NULL,
    yearly_price_cents INT NOT NULL,
    stripe_monthly_price_id VARCHAR(255),
    stripe_yearly_price_id VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO plans (id, code, name, max_staff, monthly_price_cents, yearly_price_cents) VALUES
('11111111-1111-1111-1111-111111111111', 'INDIVIDUAL', 'Plano Individual (1 Profissional)', 1, 5990, 59900),
('22222222-2222-2222-2222-222222222222', 'PEQUENO', 'Plano Equipe Pequena (Até 3)', 3, 9990, 99900),
('33333333-3333-3333-3333-333333333333', 'MEDIO', 'Plano Equipe Média (Até 6)', 6, 14990, 149900),
('44444444-4444-4444-4444-444444444444', 'GRANDE', 'Plano Equipe Grande (Até 10)', 10, 19990, 199900)
ON CONFLICT (code) DO NOTHING;

-- 3.13 Subscriptions (Assinaturas)
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barbershop_id UUID NOT NULL UNIQUE REFERENCES barbershops(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES plans(id) ON DELETE RESTRICT,
    status_code VARCHAR(50) NOT NULL DEFAULT 'TRIAL' REFERENCES domain_subscription_statuses(code),
    billing_cycle_code VARCHAR(50) NOT NULL DEFAULT 'MONTHLY' REFERENCES domain_billing_cycles(code),
    trial_ends_at TIMESTAMPTZ,
    current_period_starts_at TIMESTAMPTZ,
    current_period_ends_at TIMESTAMPTZ,
    canceled_at TIMESTAMPTZ,
    stripe_customer_id VARCHAR(255),
    stripe_subscription_id VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.14 Notifications
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barbershop_id UUID NOT NULL REFERENCES barbershops(id) ON DELETE CASCADE,
    user_id VARCHAR(255) NOT NULL,
    type_code VARCHAR(50) NOT NULL REFERENCES domain_notification_types(code),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    payload JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.15 Notification Preferences
CREATE TABLE IF NOT EXISTS notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL UNIQUE,
    email_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    push_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    in_app_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.16 Push Subscriptions
CREATE TABLE IF NOT EXISTS push_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    endpoint TEXT NOT NULL,
    p256dh VARCHAR(255) NOT NULL,
    auth VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.17 Consents (LGPD Staff/Dono)
CREATE TABLE IF NOT EXISTS consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barbershop_id UUID NOT NULL REFERENCES barbershops(id) ON DELETE CASCADE,
    user_id VARCHAR(255) NOT NULL,
    terms_version VARCHAR(50) NOT NULL,
    privacy_policy_version VARCHAR(50) NOT NULL,
    accepted_at TIMESTAMPTZ NOT NULL,
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.18 Customer Consents (LGPD Cliente Portal)
CREATE TABLE IF NOT EXISTS customer_consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barbershop_id UUID NOT NULL REFERENCES barbershops(id) ON DELETE CASCADE,
    customer_phone VARCHAR(30) NOT NULL,
    policy_version VARCHAR(50) NOT NULL,
    accepted_at TIMESTAMPTZ NOT NULL,
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.19 Suggestion Tracking (AI & Smart Booking)
CREATE TABLE IF NOT EXISTS suggestion_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barbershop_id UUID NOT NULL REFERENCES barbershops(id) ON DELETE CASCADE,
    customer_phone VARCHAR(30),
    suggested_slots JSONB NOT NULL,
    selected_slot JSONB,
    outcome VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.20 Admin Activity Logs
CREATE TABLE IF NOT EXISTS admin_activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id VARCHAR(255) NOT NULL,
    action VARCHAR(100) NOT NULL,
    target_barbershop_id UUID,
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.21 Media Audit Logs (Auditoria e Moderacao de Imagens/Fotos)
CREATE TABLE IF NOT EXISTS media_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barbershop_id UUID NOT NULL REFERENCES barbershops(id) ON DELETE CASCADE,
    uploaded_by_user_id VARCHAR(255) NOT NULL,
    entity_type VARCHAR(50) NOT NULL, -- 'BARBERSHOP_LOGO', 'BARBERSHOP_BANNER', 'STAFF_AVATAR'
    entity_id UUID NOT NULL,          -- ID da barbearia ou do staff
    storage_key TEXT NOT NULL,
    previous_storage_key TEXT,
    file_size_bytes INT,
    content_type VARCHAR(50),
    moderation_status_code VARCHAR(50) NOT NULL DEFAULT 'APPROVED' REFERENCES domain_moderation_statuses(code),
    moderation_labels JSONB DEFAULT '[]'::jsonb,
    rejection_reason TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================================
-- 4. ÍNDICES DE ALTA PERFORMANCE
-- =====================================================================

CREATE INDEX IF NOT EXISTS ix_barbershops_owner_user_id ON barbershops(owner_user_id);
CREATE INDEX IF NOT EXISTS ix_barbershops_status_code ON barbershops(status_code);
CREATE INDEX IF NOT EXISTS ix_barbershops_slug ON barbershops(slug);
CREATE INDEX IF NOT EXISTS ix_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS ix_user_roles_barbershop_id ON user_roles(barbershop_id);
CREATE INDEX IF NOT EXISTS ix_staff_barbershop_id ON staff(barbershop_id);
CREATE INDEX IF NOT EXISTS ix_staff_user_id ON staff(user_id);
CREATE INDEX IF NOT EXISTS ix_services_barbershop_id ON services(barbershop_id);
CREATE INDEX IF NOT EXISTS ix_staff_services_staff_id ON staff_services(staff_id);
CREATE INDEX IF NOT EXISTS ix_staff_services_service_id ON staff_services(service_id);
CREATE INDEX IF NOT EXISTS ix_business_hours_barbershop_id ON business_hours(barbershop_id);
CREATE INDEX IF NOT EXISTS ix_staff_hours_staff_id ON staff_hours(staff_id);
CREATE INDEX IF NOT EXISTS ix_customers_barbershop_id ON customers(barbershop_id);
CREATE INDEX IF NOT EXISTS ix_customers_phone ON customers(phone);
CREATE INDEX IF NOT EXISTS ix_appointments_barbershop_id ON appointments(barbershop_id);
CREATE INDEX IF NOT EXISTS ix_appointments_staff_id ON appointments(staff_id);
CREATE INDEX IF NOT EXISTS ix_appointments_service_id ON appointments(service_id);
CREATE INDEX IF NOT EXISTS ix_appointments_customer_id ON appointments(customer_id);
CREATE INDEX IF NOT EXISTS ix_appointments_booking_code ON appointments(booking_code);
CREATE INDEX IF NOT EXISTS ix_appointments_start_time ON appointments(start_time);
CREATE INDEX IF NOT EXISTS ix_appointments_end_time ON appointments(end_time);
CREATE INDEX IF NOT EXISTS ix_appointments_status_code ON appointments(status_code);
CREATE INDEX IF NOT EXISTS ix_availability_blocks_barbershop_id ON availability_blocks(barbershop_id);
CREATE INDEX IF NOT EXISTS ix_availability_blocks_staff_id ON availability_blocks(staff_id);
CREATE INDEX IF NOT EXISTS ix_availability_blocks_start_time ON availability_blocks(start_time);
CREATE INDEX IF NOT EXISTS ix_availability_blocks_end_time ON availability_blocks(end_time);
CREATE INDEX IF NOT EXISTS ix_subscriptions_status_code ON subscriptions(status_code);
CREATE INDEX IF NOT EXISTS ix_notifications_barbershop_id ON notifications(barbershop_id);
CREATE INDEX IF NOT EXISTS ix_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS ix_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS ix_media_audit_logs_barbershop_id ON media_audit_logs(barbershop_id);
CREATE INDEX IF NOT EXISTS ix_media_audit_logs_uploaded_by_user_id ON media_audit_logs(uploaded_by_user_id);
CREATE INDEX IF NOT EXISTS ix_media_audit_logs_created_at ON media_audit_logs(created_at);
