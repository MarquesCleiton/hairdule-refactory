# 🏢 Plano de Implementação: Detalhe 360° da Barbearia & Governança de Administradores

> **Projeto:** Hairdule 2.0 — Plataforma SaaS Multi-tenant de Agendamentos  
> **Marco:** Marco 7 — Observabilidade de Negócio & Portal SuperAdmin  
> **Repositórios Envolvidos:** `fase_31_hairdule_ui_admin` (Frontend SPA) e `fase_32_hairdule_infra_auth_admin` (Cognito RBAC)  
> **Identificador Único Oficial:** **UUID da Barbearia (`/tenants/:id`)** (Zero uso de slugs na identificação administrativa)  
> **Diretriz de Execução:** Utilizar **estritamente o que já está construído e provisionado na AWS**, sem criação de novos microsserviços ou funcionalidades pendentes no backend (Assinaturas e Pagamentos permanecem indicados como pendentes de forma transparente).  
> **Status:** Pronto para Execução  
> **Data:** 15 de Setembro de 2026  

---

## 🎯 1. Objetivo do Plano

Atender às prioridades imediatas de gestão do SuperAdmin:
1. **Página Dedicada da Barbearia por UUID (`/tenants/:id`)**: Permitir que o SuperAdmin clique em um salão e visualize uma ficha 360° com dados cadastrais, endereço completo, equipe de barbeiros, catálogo de serviços e horários de funcionamento, consumindo os contratos já ativos no backend da AWS (`GET /public/barbershop?id={uuid}`).
2. **Painel de Gestão de Administradores (`/admins`)**: Permitir auditoria e visualização dos operadores com acesso ao SuperAdmin e suas roles atribuídas no AWS Cognito User Pool (`SUPER_ADMIN`, `SUPPORT_ADMIN`, `FINANCE_ADMIN`).
3. **Substituição do Botão "Auditar"**: Trocar o botão anterior (que disparava um alerta visual sem backend) pelo botão funcional **"Ver Detalhes →"**, guiando a navegação para a ficha completa do estabelecimento baseada em seu UUID.

---

## 🏗️ 2. Mapeamento de Dados Reais do Backend (Sem Novas Funcionalidades)

| Bloco de Dados | Microsserviço AWS Existente | Endpoint / Contrato Real | Status na AWS |
|---|---|---|---|
| **Identidade & Endereço** | `hairdule-barbershop-service` (Fase 09) | `GET /public/barbershop?id={uuid}` | ✅ 100% Ativo no API Gateway |
| **Equipe & Barbeiros** | `hairdule-staff-service` (Fase 11) | Propriedade `staff[]` em `/public/barbershop` | ✅ 100% Ativo no API Gateway |
| **Catálogo de Serviços** | `hairdule-service-service` (Fase 13) | Propriedade `services[]` em `/public/barbershop` | ✅ 100% Ativo no API Gateway |
| **Horários de Funcionamento** | `hairdule-availability-engine` (Fase 15) | Propriedade `business_hours[]` em `/public/barbershop` | ✅ 100% Ativo no API Gateway |
| **Contas de Operadores Admin** | `fase_32_hairdule_infra_auth_admin` | Cognito User Pool `us-east-1_tPfrA7wPP` + Grupos RBAC | ✅ 100% Ativo no Cognito |

---

## 📋 3. Checklist de Implementação Separado por Etapas

### 🔹 ETAPA 1 — Modelagem e Camada de Serviços Frontend (`fase_31_hairdule_ui_admin`)
- [x] **1.1 Interfaces e Tipagens em `admin.models.ts`**
  - [x] Atualizar `TenantSummary` para utilizar `id: string` no padrão UUID v4.
  - [x] Criar interface `BarbershopStaff` com `id` (UUID), `name`, `email`, `phone`, `role`, `isActive`, `avatarUrl`.
  - [x] Criar interface `BarbershopServiceItem` com `id` (UUID), `name`, `description`, `priceCents`, `durationMinutes`, `category`.
  - [x] Criar interface `BarbershopBusinessHour` com `dayOfWeek`, `startTime`, `endTime`, `isClosed`.
  - [x] Criar interface `BarbershopFullDetail` com `id` (UUID), Razão Social, Nome, CNPJ, telefone, e-mail, endereço completo (rua, número, complemento, bairro, cidade, UF, CEP), slotIntervalMin, bookingMode, staff, services e businessHours.
  - [x] Criar interface `AdminOperatorUser` com `sub` (UUID Cognito), `email`, `role`, `createdAt`, `status`.

- [x] **1.2 Métodos de Dados em `observability.service.ts`**
  - [x] Implementar método `getTenantById(id: string): Observable<BarbershopFullDetail>` consumindo `GET /public/barbershop?id={id}` do API Gateway com fallback estruturado por UUID para homologação.
  - [x] Implementar método `getAdminOperators(): Observable<AdminOperatorUser[]>` listando os operadores corporativos provisionados no Cognito da Fase 32 (`cleiton2210@gmail.com` como `SUPER_ADMIN`).

---

### 🔹 ETAPA 2 — Página de Detalhe da Barbearia por UUID (`/tenants/:id`)
- [x] **2.1 Configuração de Rota em `app.routes.ts`**
  - [x] Registrar rota `tenants/:id` apontando para `TenantDetailComponent` com `canActivate: [AdminAuthGuard]`.

- [x] **2.2 Componente `TenantDetailComponent` (`features/tenants/tenant-detail.component.ts`)**
  - [x] **Cabeçalho Executivo**:
    - [x] Botão de navegação `← Voltar para Tenantes`.
    - [x] Logo / Iniciais do salão, Nome Comercial e `UUID` em destaque como badge/código copíavel.
    - [x] Badges informativos: Status no Cognito (`Confirmado / Ativo`) e Tag transparente `SEM ASSINATURA (Módulo de Faturamento Pendente)`.
  - [x] **Aba 1 — Ficha Cadastral & Localização**:
    - [x] Identificadores: UUID da Barbearia e CNPJ.
    - [x] Contatos: Nome do Dono, E-mail corporativo, Telefone.
    - [x] Endereço Físico: Logradouro, Número, Complemento, Bairro, Cidade / UF e CEP.
    - [x] Parâmetros Operacionais: Intervalo de agendamento (ex: 30 min) e Modo de reserva.
  - [x] **Aba 2 — Equipe de Profissionais (Staff)**:
    - [x] Tabela/Cards dos colaboradores cadastrados com avatar, nome, cargo, e-mail, telefone e status ativo.
  - [x] **Aba 3 — Catálogo de Serviços**:
    - [x] Tabela com os serviços oferecidos, duração em minutos, categoria e preço formatado em Reais (`R$`).
  - [x] **Aba 4 — Horários de Funcionamento**:
    - [x] Grade semanal organizada (Segunda a Domingo) mostrando horários de abertura, fechamento e dias de folga/fechados.

- [x] **2.3 Atualização da Lista de Tenantes (`tenants.component.ts`)**
  - [x] Exibir o UUID da barbearia na primeira coluna da tabela.
  - [x] Substituir o botão de `alert()` anterior pelo botão **"Ver Detalhes →"** com navegação por UUID para a rota `/tenants/:id`.
  - [x] Habilitar clique direto no nome/linha da barbearia para navegar até a ficha do UUID correspondente.

---

### 🔹 ETAPA 3 — Painel de Gestão de Administradores (`/admins`)
- [x] **3.1 Configuração de Rota e Menu**
  - [x] Adicionar item `"Administradores"` no menu executivo da barra lateral (`sidebar.component.ts`) com restrição `allowedRoles: ['SUPER_ADMIN']`.
  - [x] Registrar rota `/admins` em `app.routes.ts`.

- [x] **3.2 Componente `AdminsComponent` (`features/admins/admins.component.ts`)**
  - [x] Tabela com a listagem de administradores do ecossistema.
  - [x] Exibição das roles do Cognito: `SUPER_ADMIN` (Governança Total), `SUPPORT_ADMIN` (Atendimento N3) e `FINANCE_ADMIN` (Auditoria e Relatórios).
  - [x] Card explicativo sobre a infraestrutura de segurança do User Pool `us-east-1_tPfrA7wPP` e Client ID `obr7mh7mpt05g8if23pgb4b75`.

---

### 🔹 ETAPA 4 — Validação, Compilação e Deploy na AWS CloudFront (HTTPS)
- [x] **4.1 Compilação do Frontend Angular**
  - [x] Executar `npm run build:staging` em `fase_31_hairdule_ui_admin` e assegurar 0 erros de TypeScript.
- [x] **4.2 Publicação no S3 & CloudFront Staging**
  - [x] Executar `aws s3 sync dist/fase_31_hairdule_ui_admin/browser/ s3://hairdule-ui-admin-staging-351083991126/ --delete`.
  - [x] Disparar invalidação de cache no CloudFront: `aws cloudfront create-invalidation --distribution-id E2SISGFW2ZM73A --paths "/*"`.
- [ ] **4.3 Validação Visual Automatizada (Browser Subagent)**
  - [ ] Acessar `https://d2oisu1nq6xe4o.cloudfront.net/tenants`.
  - [ ] Clicar em "Ver Detalhes" de uma barbearia por seu UUID e validar todas as 4 abas.
  - [ ] Acessar `/admins` e validar a tabela de governança de administradores.
- [ ] **4.4 Versionamento no Git**
  - [ ] Realizar commit e push na branch `feature/setup-admin-portal` e merge para `main` (esteira CI/CD).

---

## 🔒 4. Critérios de Aceite e Não-Escopo

* ✅ **Critério 1:** A rota de detalhe deve ser estritamente baseada em UUID (`/tenants/:id`), consultando `GET /public/barbershop?id={uuid}`.
* ✅ **Critério 2:** O design deve seguir à risca o Hairdule 2.0 (`#10DAF5`, Slate/Ink, Outfit + Inter).
* ❌ **Não-Escopo:** Não serão criadas tabelas de faturamento, gateways de pagamento fictícios nem fluxos de impersonate incompletos.
