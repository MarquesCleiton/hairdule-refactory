# 💼 Plano 2: Observabilidade de Negócio, Business Intelligence & Portal SuperAdmin (360° Business Observability)

> **Projeto:** Hairdule 2.0 — Plataforma SaaS Multi-tenant de Agendamentos para Barbearias e Salões  
> **Arquitetura Base:** Frontend Apartado Angular 19 (`fase_31_hairdule_ui_admin`) + Infra Cognito Admin SST v4 (`fase_32_hairdule_infra_auth_admin`) + API Gateway / Lambdas Admin + Aurora PostgreSQL 18.4 (Analytics Cross-tenant) + Stripe Billing API  
> **Público-Alvo:** Fundadores, C-Level, Desenvolvedores Independentes, Operações, Customer Success (CS) e Suporte N3  
> **Status:** Documento Oficial de Arquitetura & Implementação  
> **Versão:** 2.0 (Front Apartado + Infra Auth Admin Dedicada)  

---

## 1. Visão Geral & Diferenciação Estratégica

No Hairdule 2.0, existem **dois níveis completamente distintos de visão de negócio**:

1. **Analytics do Estabelecimento (Fases 26 e 27 — Dono da Barbearia):**
   * Foco: "Como a minha barbearia está faturando? Quais barbeiros cortaram mais cabelo este mês? Quais horários devo abrir?"
   * Escopo: Estritamente limitado ao `barbershop_id` do próprio usuário.
2. **Observabilidade de Negócio da Plataforma (Plano 2 — Portal SuperAdmin / Backoffice):**
   * Foco: "Qual é o MRR total do Hairdule? Quantas barbearias entraram no ar esta semana? Qual a taxa de cancelamento de planos? Quantos R$ foram agendados em todo o ecossistema (GMV)? Quais barbearias correm risco de churn por desuso?"
   * Escopo: **Cross-tenant global (Visão 360° de todo o SaaS)**, com ferramentas administrativas de auditoria, suporte ao cliente, governança e métricas de crescimento.

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                COCKPIT SUPERADMIN HAIRDULE                                      │
├───────────────────────────────┬───────────────────────────────┬─────────────────────────────────┤
│  MÉTRICAS SAAS & MONETIZAÇÃO  │  VOLUME OPERACIONAL (GMV)     │  ADOÇÃO & HEALTH SCORE          │
│  • MRR / ARR / Churn Rate     │  • Agendamentos Totais / Dia  │  • Barbearias Ativas vs Zumbis  │
│  • Conversão de Trials        │  • R$ Movimentados (GMV)      │  • Adoção do Portal Público     │
│  • Inadimplência (Past Due)   │  • No-Show Médio da Rede      │  • Eficácia de IA (Suggestions) │
└───────────────────────────────┴───────────────────────────────┴─────────────────────────────────┘
                                                │
 ┌──────────────────────────────────────────────┴────────────────────────────────────────────────┐
 │                              FERRAMENTAS OPERACIONAIS 360°                                     │
 ├──────────────────────────────┬───────────────────────────────┬────────────────────────────────┤
 │ 🏢 DIRETÓRIO DE TENANTS      │ 🔍 DESPACHANTE DE SUPORTE     │ 🛡️ AUDITORIA & LGPD            │
 │ • Busca & Filtros Globais    │ • Localizador por BookingCode │ • Log de Ações Administrativas │
 │ • Ficha 360° do Salão        │ • Histórico de Auditoria      │ • Gestão de Consentimentos     │
 │ • Impersonate Seguro         │ • Linha do tempo de alterações│ • Direito ao Esquecimento      │
 └──────────────────────────────┴───────────────────────────────┴────────────────────────────────┘
```

---

## 2. Framework de Métricas de Negócio 360°

Para gerenciar a saúde da empresa com rigor, as métricas são agrupadas em **4 Dimensões Estratégicas**:

---

### 2.1. Dimensão 1: Finanças & Economia do SaaS (Monetização)
Métricas fundamentais para a viabilidade e escala financeira da plataforma Hairdule, calculadas com base nas tabelas `subscriptions`, `plans` e eventos de webhook do Stripe.

| Métrica | Definição / Fórmula | Meta do Negócio | Impacto Estratégico |
|---|---|---|---|
| **MRR (Monthly Recurring Revenue)** | $\sum (\text{Assinaturas Ativas} \times \text{Valor Mensal do Plano})$ | Crescimento > 15% MoM | Previsibilidade de receita recorrente. |
| **ARR (Annual Recurring Revenue)** | $\text{MRR} \times 12$ | Acompanhamento anual | Valoração da empresa e investimentos. |
| **ARPU (Average Revenue Per User)** | $\frac{\text{MRR Total}}{\text{Total de Barbearias Pagantes}}$ | Subir via upsell de planos | Mede a expansão da receita por cliente. |
| **Trial Conversion Rate** | $\frac{\text{Novos Assinantes Ativos}}{\text{Total de Barbearias em Trial no Mês}} \times 100$ | > 25% | Eficácia do onboarding e valor percebido na degustação. |
| **Logo Churn (Taxa de Perda de Barbearias)**| $\frac{\text{Barbearias Canceladas no Mês}}{\text{Barbearias Ativas no Início do Mês}} \times 100$ | < 3% ao mês | Retenção da base de estabelecimentos. |
| **Revenue Churn (Perda de MRR)** | $\frac{\text{MRR Perdido por Cancelamento ou Downgrade}}{\text{MRR Inicial do Mês}} \times 100$ | < 2% ao mês | Mede a saúde financeira líquida. |
| **Inadimplência / Past Due Ratio** | $\frac{\text{Assinaturas em 'PAST\_DUE'}}{\text{Total de Assinaturas Ativas}} \times 100$ | < 4% | Alerta para cobrança ativa ou problemas em gateways. |

---

### 2.2. Dimensão 2: Volume Operacional & Ecossistema (GMV & Agendamentos)
Métricas que indicam o quanto as barbearias estão efetivamente dependendo do Hairdule para faturar no dia a dia.

| Métrica | Definição / Fórmula | Indicador Observado |
|---|---|---|
| **GMV da Plataforma (Gross Merchandise Value)** | $\sum (\text{appointments.price\_cents})$ com status `CONCLUIDO` | O volume total em R$ transacionado pelos salões no Hairdule. Quanto maior o GMV, mais indispensável o software se torna. |
| **Throughput Diário de Agendamentos** | $\text{COUNT(appointments)}$ por dia | Pulso operacional. Identifica dias e horários de maior fluxo em âmbito nacional. |
| **Taxa Global de Conclusão** | $\frac{\text{Agendamentos CONCLUIDO}}{\text{Total de Agendamentos Criados}} \times 100$ | Indicador de eficiência operacional do ecossistema (> 75% saudável). |
| **Taxa Global de No-Show** | $\frac{\text{Agendamentos NO\_SHOW}}{\text{Total de Agendamentos Criados}} \times 100$ | Média de clientes que faltam sem avisar em todas as barbearias (Normal: 8% a 15%). |
| **Taxa Global de Cancelamento** | $\frac{\text{Agendamentos CANCELADO}}{\text{Total de Agendamentos Criados}} \times 100$ | Cancelamentos por iniciativa do cliente ou do profissional. |
| **Adoção do Portal Público (Self-Service)** | $\frac{\text{Agendamentos via /client-portal}}{\text{Total de Agendamentos}} \times 100$ | Percentual de agendamentos feitos pelos próprios clientes finais vs inseridos manualmente na recepção. |

---

### 2.3. Dimensão 3: Adoção do Produto & Engajamento
Métricas de uso das funcionalidades do Hairdule pelos donos e suas equipes.

* **Funil de Ativação do Onboarding (5 Passos):**
  * Passo 1: Dados do Estabelecimento (`barbershops`)
  * Passo 2: Horários de Funcionamento (`business_hours`)
  * Passo 3: Cadastro da Equipe (`staff` com permissão restrita padrão `OWN_ONLY`)
  * Passo 4: Catálogo de Serviços (`services`)
  * Passo 5: Publicação & Ativação do Link Público
  * *Métrica:* Taxa de conclusão do funil em menos de 24 horas (Meta: > 70%).
* **Intensidade de Uso da Equipe:**
  * Média de profissionais cadastrados por estabelecimento (`staff.is_active = true`).
  * Número de acessos diários de profissionais à tela `/my-day`.
* **Adoção de Notificações WebPush:**
  * Percentual de profissionais com inscrições ativas na tabela `push_subscriptions`.
* **Eficácia da Inteligência Artificial (Smart Booking):**
  * Tabela `suggestion_tracking`:
    $$\text{Taxa de Conversão de Sugestões} = \frac{\text{Agendamentos com outcome = 'ACCEPTED'}}{\text{Total de Sugestões Ofertadas}} \times 100$$
  * Valida se a IA está sugerindo horários que realmente preenchem a ociosidade das barbearias.

---

### 2.4. Dimensão 4: Saúde do Cliente (Health Score) & Prevenção de Churn
Algoritmo determinístico para alertar o time de operações sobre barbearias que estão em risco de abandonar a plataforma.

#### Fórmula do Health Score do Estabelecimento (0 a 100 pontos):
1. **Atividade Recente (30 pontos):** Pelo menos 1 agendamento criado nas últimas 48 horas (+30 pts).
2. **Engajamento da Equipe (25 pontos):** Pelo menos 2 profissionais diferentes acessando o sistema na semana (+25 pts).
3. **Volume de Clientes (25 pontos):** Mais de 10 clientes cadastrados em `customers` (+25 pts).
4. **Adimplência da Assinatura (20 pontos):** Assinatura `ACTIVE` em dia (+20 pts).

```
┌─────────────────┬─────────────────┬────────────────────────────────────────────────────────┐
│  PONTUAÇÃO      │  CLASSIFICAÇÃO  │  AÇÃO AUTOMÁTICA DISPARADA PELO SISTEMA                │
├─────────────────┼─────────────────┼────────────────────────────────────────────────────────┤
│  80 a 100 pts   │ 🟢 Campeão      │ Apto a receber convite para programa de indicação/VIP. │
│  50 a 79 pts    │ 🟡 Regular      │ Acompanhamento padrão de CS.                           │
│  25 a 49 pts    │ 🟠 Em Alerta    │ E-mail automático com dicas de ativação de clientes.   │
│  0 a 24 pts     │ 🔴 Risco Crítico│ Alerta no Slack/Telegram para contato telefônico do CS.│
└─────────────────┴─────────────────┴────────────────────────────────────────────────────────┘
```

---

## 3. Arquitetura das Telas do Portal SuperAdmin

O portal SuperAdmin é projetado como uma interface separada e de alta segurança (acessível apenas para usuários com claim de sistema `superadmin = true` no AWS Cognito).

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  HAIRDULE 2.0 ── PLATFORM BACKOFFICE & SUPERADMIN                              [👤 Admin Master | Sair] │
├─────────────────┬───────────────────────────────────────────────────────────────────────────────────────┤
│ 🧭 NAVEGAÇÃO    │ 📊 COCKPIT EXECUTIVO GERAL (Tempo Real)                                               │
│                 ├───────────────────┬───────────────────┬───────────────────┬───────────────────────────┤
│ 🏠 Visão Geral  │ MRR DA PLATAFORMA │ ASSINANTES ATIVOS │ AGENDAMENTOS HOJE │ GMV DO MÊS (TRANSACTIONED)│
│ 🏢 Estabelec.   │ R$ 48.920,00      │ 324 Barbearias    │ 1.842 Agendamentos│ R$ 412.800,00             │
│ 💳 Assinaturas  │ (+18% vs mês ant) │ (14 em Trial)     │ (88% concluídos)  │ (Ticket Médio: R$ 45,00)  │
│ 🔍 Despachante  ├───────────────────┴───────────────────┴───────────────────┴───────────────────────────┤
│ 🛡️ Conformidade │ 📈 GRÁFICO: EVOLUÇÃO DE MRR & CRESCIMENTO DE ASSINATURAS (ÚLTIMOS 12 MESES)          │
│ 🩺 Saúde Técnica│ [────────────────────────────────── Sparkline / Gráfico de Área ───────────────────]  │
│ ⚙️ Configs Glob │ 🚨 RADAR DE RISCO & CHURN WARNING (Barbearias sem agendamentos há > 5 dias)           │
│                 │ • Barbearia Dom Pedro (Campinas-SP) — 6 dias sem agendamentos [📞 Chamar no WhatsApp] │
│                 │ • Studio Alpha (Curitiba-PR) — Falha no cartão (Tentativa 2/3) [💳 Reenviar Link]     │
└─────────────────┴───────────────────────────────────────────────────────────────────────────────────────┘
```

---

### 3.1. Tela 1: Diretório de Tenants 360° (`/admin/barbershops`)
Permite ao time operacional do Hairdule gerenciar o ciclo de vida completo de cada estabelecimento parceiro.

#### Recursos e Filtros da Tela:
* **Filtros Avançados:** Por Status (`ONBOARDING`, `ACTIVE`, `SUSPENDED`, `INACTIVE`), Plano (`STARTER`, `PRO`, `ENTERPRISE`), Estado/Cidade e Faixa de Faturamento.
* **Tabela de Tenants:** Exibe Nome Fantasia, CNPJ/CPF, Dono, Telefone, Quantidade de Barbeiros, Total de Agendamentos, Status da Assinatura e Data de Entrada.

#### Modal "Ficha 360° do Tenant":
Ao clicar em uma barbearia, abre-se um painel de auditoria profunda com:
1. **Dados de Contrato & Faturamento:** ID do cliente Stripe, cartão atual, histórico de faturas pagas e pendentes.
2. **Equipe & Serviços:** Quantos profissionais ativos, quais serviços oferecidos e configuração de buffers de tempo.
3. **Métricas de Performance do Salão:** Gráfico de agendamentos dos últimos 30 dias e taxa de no-show daquele salão.
4. **Painel de Ações de Suporte N3:**
   * **Simular Acesso (Impersonation):** Permite ao suporte entrar na conta do cliente com um token de sessão de suporte válido por 30 minutos. Cada clique registra obrigatoriamente um evento rastreável em `admin_activity_logs`.
   * **Estender Período de Testes (Trial Extension):** Adiciona +7 ou +15 dias de degustação gratuita direto no banco.
   * **Bloqueio Cautelar / Reativação:** Pausa o acesso em caso de fraude ou disputa comercial.

---

### 3.2. Tela 2: Despachante de Atendimento & Suporte Rápido (`/admin/support`)
A ferramenta diária do time de suporte para atender clientes que ligam com dúvidas ou reclamações sobre horários.

* **Busca Universal Global:**
  * Busca por **Código do Agendamento** (`booking_code` - ex: `HAIR-98124`).
  * Busca por **Telefone do Cliente** (Dígitos do WhatsApp).
  * Busca por **E-mail** ou **ID de Transação**.
* **Painel da Linha do Tempo Auditável (Time-Travel Debugger):**
  Consulta a tabela `appointment_audit_logs` e reconstrói o que aconteceu com o agendamento minuto a minuto:
  * *14/09 10:00:* Agendamento criado pelo cliente via portal público (IP: 189.20.11.4).
  * *14/09 11:30:* Barbeiro "Carlos" alterou o horário de 15:00 para 16:30 (`field_changed: start_time`).
  * *14/09 14:00:* Cliente cancelou o atendimento via WhatsApp link (`canceled_by: CUSTOMER`).

---

### 3.3. Tela 3: Monitor de Faturamento & Inadimplência (`/admin/billing`)
Focada em garantir que o Hairdule não perca receita por falhas técnicas de pagamento.

* **Acompanhamento de Vencimento de Trials:**
  * Lista de estabelecimentos cujos testes encerram em 3 dias, 24 horas e hoje.
  * Disparo de automações de incentivo comercial.
* **Painel de Recuperação de Inadimplência (Dunning Management):**
  * Lista de estabelecimentos com status `PAST_DUE` no Stripe.
  * Exibição do motivo da recusa bancária (saldo insuficiente, cartão expirado, suspeita de fraude).
  * Botão de 1 clique para gerar e copiar link de atualização rápida de pagamento da Stripe.

---

### 3.4. Tela 4: Painel de Conformidade & LGPD (`/admin/compliance`)
Garante que a plataforma cumpra integralmente a legislação brasileira de proteção de dados pessoais:

* **Auditoria de Consentimentos:**
  * Total de termos aceitos por colaboradores (`consents`) e clientes finais no portal (`customer_consents`).
  * Rastreamento da versão dos Termos de Uso e Política de Privacidade aceitos com IP e Timestamp imutável.
* **Direito do Titular (Exportação & Expurgo):**
  * Busca por telefone do cliente final e botão para **"Anonimizar Dados Pessoais"** (substituindo nome e telefone em `appointments` e `customers` por hashes irreversíveis, mantendo apenas os números financeiros agregados).

---

### 3.5. Tela 5: Monitor de Saúde dos Serviços (`/admin/system-health`)
A ponte da **Solução Híbrida de Observabilidade**: traz a saúde técnica diretamente para o portal administrativo, sem exigir que o gestor ou suporte acesse o console da AWS.

#### Por que isso é vital para o Negócio?
Quando um proprietário de barbearia liga para o suporte reclamando: *"Meus clientes não estão conseguindo agendar!"*, o suporte abre a aba **Saúde dos Serviços** e tem uma resposta instantânea em 5 segundos:
* Se o serviço de agendamentos (`fase_17_appointment_service`) estiver com semáforo 🔴 ou latência P95 > 2s, é um **incidente técnico geral** (o suporte avisa o time técnico e acalma o cliente).
* Se todos os 9 serviços e o banco estiverem 🟢 Verdes, o suporte sabe imediatamente que é uma **questão de configuração local da barbearia** (ex: horários de funcionamento bloqueados ou profissional sem serviços vinculados).

#### Componentes Visuais da Tela no Angular 19:
1. **Semáforo dos 9 Microsserviços:** Cards dinâmicos com indicador visual (🟢 Online, 🟡 Degradado, 🔴 Fora do Ar), tempo de resposta P95 e taxa de erros nas últimas 24h.
2. **Saúde da Persistência (Aurora PostgreSQL 18.4):**
   * Medidor de capacidade de ACUs Serverless.
   * Porcentagem de ocupação do pool de conexões (ex: 18 de 120 conexões ativas).
   * Indicador de locks ou bloqueios concorrentes ativos.
3. **Saúde de Parceiros Críticos:**
   * Stripe API (Status de resposta para pagamentos e webhooks).
   * AWS SES (Taxa de entrega de e-mails transacionais e índice de reputação da conta).
   * WebPush VAPID (Taxa de sucesso de entrega nos navegadores).
4. **Botão de Aprofundamento (Deep Link Seguro):**
   * Botão `[ 🔍 Abrir Telemetria Profunda no AWS CloudWatch ]` que redireciona os engenheiros diretamente para o dashboard de SRE no CloudWatch com autenticação SSO IAM.

---

## 4. Banco de Dados: Consultas SQL Analíticas Pré-fabricadas

Abaixo estão as consultas SQL otimizadas para o PostgreSQL 18.4, prontas para serem transformadas em endpoints da API de administração ou painéis de BI:

### 4.1. Cálculo Consolidado de MRR e Distribuição de Assinaturas
```sql
-- Consolidação de MRR, Total de Contas Ativas e Distribuição por Plano
SELECT 
    p.code AS plano_codigo,
    p.name AS plano_nome,
    COUNT(s.id) AS total_assinaturas,
    SUM(CASE 
        WHEN s.billing_cycle_code = 'YEARLY' THEN (p.yearly_price_cents / 12) / 100.0
        ELSE p.monthly_price_cents / 100.0
    END) AS mrr_gerado_reais,
    COUNT(CASE WHEN s.status_code = 'TRIAL' THEN 1 END) AS em_periodo_teste,
    COUNT(CASE WHEN s.status_code = 'ACTIVE' THEN 1 END) AS ativas_pagantes,
    COUNT(CASE WHEN s.status_code = 'PAST_DUE' THEN 1 END) AS inadimplentes
FROM plans p
LEFT JOIN subscriptions s ON s.plan_id = p.id
GROUP BY p.code, p.name
ORDER BY mrr_gerado_reais DESC;
```

### 4.2. Detecção de Barbearias em Risco de Churn (Inativas nos Últimos 5 Dias)
```sql
-- Barbearias ativas ou em trial que não registraram NENHUM agendamento recente
SELECT 
    b.id AS barbershop_id,
    b.trade_name AS nome_fantasia,
    b.phone AS telefone_contato,
    b.email AS email_dono,
    s.status_code AS status_assinatura,
    MAX(a.created_at) AS ultimo_agendamento_registrado,
    NOW() - COALESCE(MAX(a.created_at), b.created_at) AS tempo_sem_atividade
FROM barbershops b
JOIN subscriptions s ON s.barbershop_id = b.id
LEFT JOIN appointments a ON a.barbershop_id = b.id
WHERE s.status_code IN ('ACTIVE', 'TRIAL')
  AND b.status_code = 'ACTIVE'
GROUP BY b.id, b.trade_name, b.phone, b.email, s.status_code
HAVING MAX(a.created_at) < NOW() - INTERVAL '5 days' 
    OR MAX(a.created_at) IS NULL
ORDER BY tempo_sem_atividade DESC;
```

### 4.3. Volume Operacional Geral da Plataforma (GMV e Agendamentos no Mês)
```sql
-- Faturamento total movimentado no ecossistema (GMV) e métricas de qualidade
SELECT 
    DATE_TRUNC('month', start_time) AS mes_referencia,
    COUNT(*) AS total_agendamentos,
    SUM(CASE WHEN status_code = 'CONCLUIDO' THEN price_cents ELSE 0 END) / 100.0 AS gmv_concluido_reais,
    ROUND(AVG(CASE WHEN status_code = 'CONCLUIDO' THEN price_cents ELSE NULL END) / 100.0, 2) AS ticket_medio_reais,
    ROUND(100.0 * COUNT(CASE WHEN status_code = 'CONCLUIDO' THEN 1 END) / COUNT(*), 2) AS taxa_conclusao_pct,
    ROUND(100.0 * COUNT(CASE WHEN status_code = 'NO_SHOW' THEN 1 END) / COUNT(*), 2) AS taxa_no_show_pct,
    ROUND(100.0 * COUNT(CASE WHEN status_code = 'CANCELADO' THEN 1 END) / COUNT(*), 2) AS taxa_cancelamento_pct
FROM appointments
WHERE created_at >= NOW() - INTERVAL '6 months'
GROUP BY DATE_TRUNC('month', start_time)
ORDER BY mes_referencia DESC;
```

### 4.4. Eficácia do Motor de Sugestões de Inteligência Artificial
```sql
-- Desempenho do recomendador inteligente de slots
SELECT 
    DATE_TRUNC('week', created_at) AS semana,
    COUNT(*) AS total_sugestoes_exibidas,
    COUNT(CASE WHEN outcome = 'ACCEPTED' THEN 1 END) AS sugestoes_aceitas,
    COUNT(CASE WHEN outcome = 'REJECTED' THEN 1 END) AS sugestoes_rejeitadas,
    ROUND(100.0 * COUNT(CASE WHEN outcome = 'ACCEPTED' THEN 1 END) / NULLIF(COUNT(*), 0), 2) AS taxa_sucesso_ia_pct
FROM suggestion_tracking
GROUP BY DATE_TRUNC('week', created_at)
ORDER BY semana DESC;
```

---

## 5. Automações de Alertas de Negócio (Webhooks Proativos)

Assim como a engenharia precisa de alarmes de latência, a **equipe de negócios precisa de alertas automáticos em canais de comunicação (Slack / Discord / Telegram / WhatsApp)** para agir imediatamente:

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   ALERTAS DE NEGÓCIO PROATIVOS                                   │
├───────────────────────┬───────────────────────────────┬──────────────────────────────────────────┤
│ GATILHO               │ CANAL DESTINO                 │ MENSAGEM GERADA                          │
├───────────────────────┼───────────────────────────────┼──────────────────────────────────────────┤
│ Nova Barbearia Ativa  │ #business-wins (Slack/Discord)│ 🚀 Nova barbearia finalizou o Onboarding!│
│                       │                               │ "Barbearia Vintage", São Paulo-SP (3 pro)│
├───────────────────────┼───────────────────────────────┼──────────────────────────────────────────┤
│ Novo Pagante (Upgrade)│ #revenue-stream               │ 💰 Nova assinatura confirmada!           │
│                       │                               │ Plano PRO (R$ 119/mês) via Cartão Stripe │
├───────────────────────┼───────────────────────────────┼──────────────────────────────────────────┤
│ Falha no Pagamento    │ #dunning-billing              │ ⚠️ Falha na cobrança de mensalidade!    │
│                       │                               │ Salão VIP (Tentativa 1 de 3)             │
├───────────────────────┼───────────────────────────────┼──────────────────────────────────────────┤
│ Risco Iminente Churn  │ #customer-success             │ 🚨 ALERTA DE CHURN: Barbearia Central    │
│                       │                               │ sem agendamentos há 5 dias seguidos!     │
├───────────────────────┼───────────────────────────────┼──────────────────────────────────────────┤
│ Pico de Cancelamentos │ #product-risk                 │ ⚠️ Anomalia: Salão X teve 60% de cortes │
│                       │                               │ cancelados nas últimas 24 horas!         │
└───────────────────────┴───────────────────────────────┴──────────────────────────────────────────┘
```

---

## 6. Arquitetura em Repositórios Apartados & Roteiro de Implementação

Para garantir independência operacional, segurança por design e zero acoplamento com o aplicativo principal das barbearias, o Portal SuperAdmin é estruturado em **dois novos repositórios dedicados**:

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                ARQUITETURA DE REPOSITÓRIOS APARTADOS                                   │
├──────────────────────────────────────────┬─────────────────────────────────────────────────────────────┤
│ 🔐 INFRAESTRUTURA AUTH ADMIN (SST v4)    │ 🖥️ FRONTEND PORTAL ADMIN (ANGULAR 19)                      │
│ Repositório: fase_32_hairdule_infra_auth_admin│ Repositório: fase_31_hairdule_ui_admin                 │
│ • App Client Cognito dedicado            │ • SPA Angular 19 Standalone 100% apartada                   │
│ • Grupos Cognito (SUPER_ADMIN, etc.)     │ • Design Ultra-Elegante, Alta Densidade e Performático      │
│ • Parâmetros SSM para consumo do Front   │ • Bundle mínimo (< 300KB) com Signals e Micro-interações    │
│ • Esteira CI/CD para Staging e Produção  │ • Esteira CI/CD própria (S3 + CloudFront CDN)               │
└──────────────────────────────────────────┴─────────────────────────────────────────────────────────────┘
```

---

### 6.1. Repositório 1: `fase_32_hairdule_infra_auth_admin` (Infraestrutura de Autenticação Admin)
* **Objetivo:** Gerenciar com exclusividade todas as configurações de identidade, App Clients e permissões do SuperAdmin via IaC (SST v4 / Pulumi), com deploy 100% automatizado por esteiras GitHub Actions sem intervenção manual na AWS.
* **Componentes Provisionados:**
  1. **App Client Cognito Dedicado (`hairdule-admin-client-${stage}`):**
     * Auth flows: `ALLOW_USER_PASSWORD_AUTH`, `ALLOW_USER_SRP_AUTH`, `ALLOW_REFRESH_TOKEN_AUTH`.
     * Validade customizada de tokens de sessão executiva (AccessToken: 8 horas, RefreshToken: 30 dias).
     * `PreventUserExistenceErrors: ENABLED` para proteção contra enumeração de contas.
  2. **Grupos de Usuários no Cognito (RBAC):**
     * `SUPER_ADMIN` (Precedência 1 — Acesso irrestrito a todos os relatórios, impersonate e auditoria).
     * `SUPPORT_ADMIN` (Precedência 2 — Acesso ao Despachante de agendamentos e Saúde de Serviços, sem acesso a dados bancários/Stripe).
     * `FINANCE_ADMIN` (Precedência 3 — Acesso a relatórios de MRR, Churn e Inadimplência).
  3. **Contratos de Integração no SSM Parameter Store:**
     * `/sst/hairdule/${stage}/admin-auth/user-pool-id`
     * `/sst/hairdule/${stage}/admin-auth/client-id`
  4. **Esteira CI/CD GitFlow:**
     * Validação sintática, deploy automático em Homologação (`release/v*`) e abertura de PR para Produção.

---

### 6.2. Repositório 2: `fase_31_hairdule_ui_admin` (Portal SuperAdmin Web)
* **Objetivo:** SPA dedicada aos fundadores e administradores da plataforma.
* **Premissas de Design & Engenharia (Identidade Oficial Hairdule 2.0):**
  * **Design System Idêntico ao App Principal:**
    * **Paleta Brand Aqua:** `#10DAF5` (Main Brand Aqua), `#0CBBD2` (Gradient Accent), `#089EB5` (Brand Dark).
    * **Paleta Ink / Slate:** `#0F172A` (Ink 900), `#1E293B` (Ink 800), `#334155` (Ink 700), `#64748B` (Ink 500), `#E2E8F0` (Ink 200), `#F8FAFC` (Ink 50).
    * **Superfícies:** Fundo oficial `#F6F7FB` (`--bg-page`) e cards em `#FFFFFF` (`--bg-card`) com suporte a Dark Mode elegante.
    * **Tipografia Oficial:** `Outfit` (títulos, números de KPIs e headers) e `Inter` (corpo, tabelas e dados).
    * **Iconografia:** Lucide Icons com mesmo padrão de espessura e alinhamento do app.
    * **Sombras e Raios:** Raios arredondados padronizados (`12px`, `16px`, `24px`) e sombra de marca `rgba(16, 218, 245, 0.35)`.
  * **Simplicidade & Performance Absoluta:**
    * Zero dependências visuais infladas; componentes puros e leves baseados no CSS do Hairdule.
    * Arquitetura de Signals do Angular 19 garantindo renderização reativa sem Zone.js e sem re-renderizações desnecessárias.
    * Gráficos SVG nativos ultraleves e tabelas com paginação/ordenação virtualizadas instantâneas.
    * Bundle compilado inferior a 300KB (carregamento inicial em < 300ms).
  * **Acesso Direto Seguro:** Sem exigência de VPN ou IP allowlist (viabilizando trabalho ágil e remoto de desenvolvedores independentes), protegido por autenticação direta no Cognito com desafio de MFA (TOTP) e verificação estrita de claims no frontend e backend.

---

### 6.3. Roteiro de Entrega por Fases

1. **Fase 32 — `fase_32_hairdule_infra_auth_admin`:**
   * Criação do projeto SST v4, definição do App Client Admin, Grupos Cognito e parâmetros SSM.
   * Esteiras de CI/CD para Staging e Produção configuradas e homologadas na AWS.
2. **Fase 31 — `fase_31_hairdule_ui_admin`:**
   * Inicialização do projeto Angular 19 Standalone com Design System Executivo.
   * Fluxo de autenticação: Tela de Login, Desafio MFA e guarda de rotas baseada em roles (`SUPER_ADMIN`).
   * Telas do Cockpit:
     * `Overview` (KPIs SaaS: MRR, ARR, GMV, Churn).
     * `Tenants Directory` (Busca, filtros, ficha 360° da barbearia).
     * `Support Debugger` (Localizador por BookingCode, histórico e timeline).
     * `Billing & Dunning` (Status de assinaturas Stripe e cobrança ativa).
     * `System Health` (Semáforo dos microsserviços e links CloudWatch).
   * Esteira de CI/CD para deploy no CloudFront CDN.
3. **Rotas Backend BFF no API Gateway (`fase_07_hairdule_infra_api`):**
   * Configuração de rotas agrupadas `/admin/*` protegidas pelo Authorizer validando a claim do grupo `SUPER_ADMIN`.
