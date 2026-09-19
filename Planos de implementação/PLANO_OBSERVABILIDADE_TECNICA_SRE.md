# 🛠️ Plano 1: Observabilidade Técnica, SRE & Saúde dos Serviços (360° Technical Observability)

> **Projeto:** Hairdule 2.0 — Plataforma SaaS Multi-tenant de Agendamentos para Barbearias e Salões  
> **Arquitetura Base:** AWS Serverless (Lambda Python 3.12 FastAPI + Aurora PostgreSQL 18.4 Serverless + API Gateway v2 + CloudFront + Angular 19 SPA)  
> **Público-Alvo:** Engenharia de Confiabilidade (SRE), Arquitetura Cloud, DevOps e Tech Leads  
> **Status:** Documento Oficial de Arquitetura & Implementação  
> **Versão:** 1.0  

---

## 1. Visão Geral & Filosofia de SRE no Hairdule

Em um modelo de negócio SaaS de agendamentos em tempo real, **indisponibilidade significa clientes perdendo dinheiro e barbearias perdendo atendimentos**. Um atraso de 3 segundos na tela de disponibilidade ou uma falha silenciosa em lembretes pode resultar em "no-shows" reais e perda direta de receita para os estabelecimentos e cancelamento de planos para o Hairdule.

A observabilidade técnica do Hairdule 2.0 segue os princípios do **Google Site Reliability Engineering (SRE)**, adaptados para o paradigma **Serverless na AWS**, operando em um **Modelo Híbrido em Duas Camadas Complementares**:

1. **Camada 1 — Telemetria Profunda de Engenharia (AWS CloudWatch Dashboards):**
   * Destinada a: Desenvolvedores, DevOps, SREs e investigação de incidentes pós-deploy.
   * Onde vive: Provisionada como Código (IaC) via **SST v4** diretamente no CloudWatch.
   * Foco: Métricas granulares de sistema operacional, percentis P50/P95/P99 de cada microsserviço, Cold Starts (`InitDuration`), memória real consumida, saturação de ACUs do Aurora PostgreSQL, traces X-Ray e consultas do CloudWatch Logs Insights.
2. **Camada 2 — Visibilidade Operacional Unificada (Aba "Saúde dos Serviços" no Portal Admin):**
   * Destinada a: Fundadores, Administradores da Plataforma e Suporte N2/N3.
   * Onde vive: Diretamente dentro do **Portal Web do SuperAdmin (`/admin/system-health`)** construído em Angular 19.
   * Foco: "Semáforo" de disponibilidade em tempo real dos 9 microsserviços, integridade do pool do PostgreSQL, saúde das integrações externas (Stripe, SES, WebPush) e link direto para o CloudWatch quando for necessário aprofundar.

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                              ARQUITETURA DE TELEMETRIA HÍBRIDA 360°                                    │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 [ Browser / PWA ] ────► [ CloudFront CDN + WAF ] ────► [ API Gateway v2 HTTP ]
      │                              │                               │
      ▼                              ▼                               ▼
 [ Angular 19 SPA ]           [ WAF Rule Alarms ]            [ 4xx/5xx / Latency EMF ]
      │                                                              │
      │ ┌────────────────────────────────────────────────────────────┘
      │ ▼
      │ [ AWS Lambda (FastAPI 3.12) ] ◄───► [ AWS Secrets / Cognito IAM ]
      │      │ • Structlog JSON + Correlation ID
      │      │ • CloudWatch EMF (Embedded Metric Format)
      │      │ • AWS X-Ray Traces / OpenTelemetry
      │      │ • InitDuration (Cold Starts) & OOM Tracking
      │      │
      │      ├───► [ Aurora PostgreSQL 18.4 (Serverless) ]
      │      │          • pg_stat_activity, locks, deadlocks, IAM Token Lifecycle
      │      │
      │      ├───► [ External APIs (Stripe, SES, WebPush VAPID, S3) ]
      │      │          • Latency & Error Budgets por gateway externo
      │      │
      │      └───► [ EventBridge Scheduler + SQS DLQ ]
      │                 • Falhas em rotinas periódicas (Lembretes / Analytics Rollup)
      │
      ▼
 ┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │                                   DESTINOS DE VISUALIZAÇÃO HÍBRIDA                                   │
 ├──────────────────────────────────────────────────┬───────────────────────────────────────────────────┤
 │ 🛠️ CAMADA 1: AWS CLOUDWATCH DASHBOARD (IaC SST)  │ 🩺 CAMADA 2: PORTAL SUPERADMIN (/admin/health)    │
 │ • Console AWS / Grafana (Acesso de Engenharia)   │ • Angular 19 SPA (Acesso Administrativo Unificado)│
 │ • Drill-down profundo, Logs Insights, Traces     │ • Semáforo dos Serviços, Status Banco, Latência P95│
 └──────────────────────────────────────────────────┴───────────────────────────────────────────────────┘
```

---

## 2. Os 4 Golden Signals Aplicados ao Hairdule

Os **4 Golden Signals** (Latência, Tráfego, Erros e Saturação) são a espinha dorsal da monitoração do Hairdule. Abaixo estão detalhados para cada microsserviço da plataforma:

### 2.1. Latência (Latency)
O tempo que leva para atender a uma requisição, distinguindo entre sucesso e erro, e entre execuções a quente (*warm*) e a frio (*cold start*).

| Microsserviço / Endpoint | P50 Alvo | P95 Alvo | P99 Alvo | Ponto Crítico Observado |
|---|---|---|---|---|
| **Motor de Disponibilidade** (`POST /availability/calculate`) | < 80ms | < 200ms | < 450ms | Avaliação de 6 camadas (folgas, pausas, buffers e agendamentos existentes). |
| **Criação de Agendamento** (`POST /appointments`) | < 120ms | < 300ms | < 600ms | Lock de concorrência, inserção em `appointments` e gravação em `appointment_audit_logs`. |
| **Autenticação** (`POST /auth/login`, `/auth/refresh`) | < 90ms | < 250ms | < 500ms | Consulta Cognito + validação em `user_roles` e `barbershops`. |
| **Analytics Overview** (`GET /analytics/overview`) | < 150ms | < 450ms | < 1000ms | Queries com agregações e `GROUP BY` no PostgreSQL. |
| **Catálogo & Equipe** (`GET /services`, `GET /staff`) | < 40ms | < 120ms | < 250ms | Consultas leves de leitura. |
| **Invocação Cold Start (Lambda `InitDuration`)** | < 800ms | < 1500ms | < 2500ms | Inicialização do interpretador Python, import de Pydantic/FastAPI e conexão inicial. |
| **Gateway Externo — Stripe Checkout** (`POST /subscriptions/checkout`) | < 300ms | < 700ms | < 1200ms | Latência de rede até os servidores da Stripe. |
| **Gateway Externo — Web Push VAPID** (`POST /notifications/send`) | < 180ms | < 400ms | < 800ms | Handshake com endpoints Apple/Google/Mozilla WebPush. |

### 2.2. Tráfego (Traffic)
A demanda aplicada ao sistema, medida em throughput e requisições concorrentes.

* **API Gateway Requests per Second (RPS):**
  * Baseline médio: 15-50 RPS.
  * Picos previstos: Quintas, sextas-feiras e sábados (11:00 às 20:00 BRT), alcançando 200-500 RPS.
* **Lambda Invocations por Função:**
  * Métricas coletadas: `Invocations` e `ConcurrentExecutions` por microsserviço.
* **CloudFront CDN Request Volume:**
  * Taxa de requisições de assets estáticos do Angular 19 (`fase_08_hairdule_ui_web`).
  * Cache Hit Ratio no CloudFront (Meta: > 92% para bundles JS/CSS e fotos estáticas no S3).
* **Throughput do PostgreSQL:**
  * Transações por segundo (`xact_commit` / `xact_rollback`).
  * Consultas de leitura vs escrita por minuto.

### 2.3. Erros (Errors)
A taxa de requisições com falha, categorizadas explicitamente por causa raiz.

| Código / Categoria | Tolerância | Causa Raiz Investigada | Alerta |
|---|---|---|---|
| **500 Internal Server Error** | < 0.05% | Exceções não tratadas nas Lambdas Python. | 🚨 P1 imediato se > 1% em 3 min. |
| **502 / 504 Bad Gateway / Gateway Timeout** | < 0.01% | Lambda atingiu limite de execução (timeout configurado) ou falhou durante inicialização. | 🚨 P1 imediato. |
| **401 Unauthorized / 403 Forbidden** | < 2% | Token expirado, tentativa de acesso cross-tenant violando `barbershop_id` ou ataque de força bruta. | ⚠️ P2 se houver pico anormal (WAF / Scanners). |
| **409 Conflict (Double Booking)** | Informativo | Tentativa concorrente de reservar o mesmo horário exato (Race condition capturada com sucesso pelo motor). | 📊 Monitor de experiência do cliente. |
| **422 Validation Error** | < 1.5% | Falhas de schema Pydantic v2 enviadas pelo frontend. | ⚠️ P3 para melhoria de UX. |
| **PostgreSQL Connection Failures** | **0% tolerância** | Token IAM expirado, pool esgotado ou Aurora em failover. | 🚨 P1 crítico. |
| **SES Delivery Bounces** | < 2% | E-mails cadastrados incorretamente. | ⚠️ P2 para evitar suspensão da conta AWS SES. |
| **Web Push Failures (HTTP 410 Gone)** | Informativo | Cliente desinstalou ou revogou permissão de push no browser (deve desativar registro em `push_subscriptions`). | Limpeza periódica assíncrona. |

### 2.4. Saturação (Saturation)
Quão próximo de 100% da capacidade os recursos computacionais e limites de infraestrutura estão operando.

* **Aurora Capacity Units (ACU):** Utilização atual de ACUs versus limite configurado (mínimo e máximo). Se a utilização passar de 75% da capacidade máxima, disparar alerta preventivo de autoscaling.
* **Conexões do Aurora (`pg_stat_activity`):** 
  $$\text{Taxa de Ocupação de Conexões} = \frac{\text{Conexões Ativas}}{\text{max\_connections}} \times 100$$
  Alerta em 70% da capacidade do pool.
* **Concorrência de Lambdas (Reserved vs Unreserved):**
  * Monitoramento de `Throttles` da AWS Lambda. O Hairdule não pode sofrer throttling durante horários de pico.
* **Memória da Lambda:**
  * Uso de memória via CloudWatch `MaxMemoryUsed` vs `MemorySize` (Meta: manter entre 60% e 80% do provisionado).
* **Quotas e Limites da AWS:**
  * Cota de envio diário do AWS SES (e-mails transacionais de recuperação de senha e lembretes).
  * Storage dos Buckets S3 (Fotos de perfil, logos e banners).
  * Consumo de WAF WebACL rules e rate limiting (100 req/5min por IP).

---

## 3. Pilares da Observabilidade & Instrumentação

### 3.1. Logs Estruturados (Structured Logging)
O Hairdule utiliza **Structlog com renderizador JSON** (já configurado no `hairdule_shared.middleware.logger`), garantindo rastreabilidade uniforme em todos os microsserviços.

#### Contexto Obrigatório em Cada Linha de Log:
```json
{
  "timestamp": "2026-09-14T23:51:00.123Z",
  "level": "info",
  "event": "appointment_created",
  "correlation_id": "req_8f12a89c4d92",
  "service": "appointment_service",
  "environment": "staging",
  "barbershop_id": "8b9e6f24-7df8-4f51-bc01-1b9a101ff2a0",
  "user_id": "usr_998124a1",
  "role": "OWNER",
  "method": "POST",
  "path": "/appointments",
  "status_code": 201,
  "duration_ms": 114.3,
  "cold_start": false,
  "db_queries_count": 3,
  "db_duration_ms": 42.1,
  "client_ip": "177.136.21.10",
  "user_agent": "Mozilla/5.0 HairduleApp/2.0"
}
```

#### Consultas Essenciais no CloudWatch Logs Insights:

* **Top 10 Endpoints Mais Lentos (P95 e P99):**
  ```sql
  fields path, method, duration_ms
  | filter event = "http_request_completed"
  | stats count() as total, pct(duration_ms, 50) as p50, pct(duration_ms, 95) as p95, pct(duration_ms, 99) as p99 by path, method
  | sort p95 desc
  | limit 10
  ```

* **Detecção de Cold Starts por Função Lambda:**
  ```sql
  filter @type = "REPORT"
  | parse @message /Init Duration: (?<init_duration>[0-9\.]+) ms/
  | stats count() as cold_starts, avg(init_duration) as avg_init, max(init_duration) as max_init by @logStream
  | sort max_init desc
  ```

* **Erros 5xx Agrupados por Causa Raiz:**
  ```sql
  fields @timestamp, service, path, error, correlation_id, barbershop_id
  | filter status_code >= 500 or ispresent(error)
  | stats count() as error_count by service, path, error
  | sort error_count desc
  ```

---

### 3.2. Métricas Customizadas via CloudWatch EMF (Embedded Metric Format)
Para evitar custos com chamadas `boto3.client('cloudwatch').put_metric_data` e eliminar latência de rede adicional na Lambda, o Hairdule adota o padrão **AWS CloudWatch EMF**. As métricas são gravadas diretamente no stdout em formato JSON e o CloudWatch as extrai assincronamente sem nenhum custo de execução para a Lambda.

```json
{
  "_aws": {
    "Timestamp": 1726357860000,
    "CloudWatchMetrics": [
      {
        "Namespace": "Hairdule/Services",
        "Dimensions": [["ServiceName", "Environment"], ["ServiceName", "BarbershopId"]],
        "Metrics": [
          {"Name": "AvailabilityCalculationDurationMs", "Unit": "Milliseconds"},
          {"Name": "AppointmentBookingCount", "Unit": "Count"},
          {"Name": "DoubleBookingConflictCount", "Unit": "Count"},
          {"Name": "DatabaseQueryDurationMs", "Unit": "Milliseconds"}
        ]
      }
    ]
  },
  "ServiceName": "availability_engine",
  "Environment": "production",
  "BarbershopId": "8b9e6f24-7df8-4f51-bc01-1b9a101ff2a0",
  "AvailabilityCalculationDurationMs": 48.2,
  "AppointmentBookingCount": 1,
  "DoubleBookingConflictCount": 0,
  "DatabaseQueryDurationMs": 18.5
}
```

---

### 3.3. Rastreamento Distribuído (Distributed Tracing com AWS X-Ray)
O rastreamento transversal permite diagnosticar em qual componente específico uma requisição gastou tempo ou falhou:

```
[ CloudFront ] ──(15ms)──► [ API Gateway v2 ] ──(12ms)──► [ Lambda FastAPI ]
                                                                  │
                    ┌─────────────────────────────────────────────┴────────────────────────────────┐
                    │                                                                              │
                    ▼ (45ms)                                                                       ▼ (120ms)
       [ Aurora PostgreSQL 18.4 ]                                                        [ Stripe / External API ]
  (IAM Auth + SELECT + INSERT)                                                             (POST /v1/checkout/sessions)
```

* **Headers Injetados:**
  * `X-Amzn-Trace-Id`: Propagado do CloudFront -> API Gateway -> Lambda.
  * `X-Correlation-ID`: Repassado em todas as respostas HTTP para que o frontend exiba no console em caso de erro, facilitando o suporte imediato ao usuário.
* **Subsegmentos Monitorados:**
  * `db.connect` (tempo para obter conexão do pool ou gerar token IAM).
  * `db.query` (execução da instrução SQL).
  * `http.client.stripe` e `http.client.ses`.

---

### 3.4. Observabilidade do Frontend (Angular 19 SPA) & Real User Monitoring (RUM)
A experiência do usuário final nos navegadores (donos de salões e clientes agendando pelo celular) deve ser auditada continuamente:

1. **Core Web Vitals:**
   * **LCP (Largest Contentful Paint):** < 2.5s (Meta para a tela do portal de agendamento e calendário).
   * **INP (Interaction to Next Paint):** < 200ms (Abertura de modais, troca de visualização dia/semana/mês no calendário).
   * **CLS (Cumulative Layout Shift):** < 0.1 (Estabilidade visual no carregamento de slots).
2. **Global Error Handler no Angular (`ErrorHandler`):**
   * Captura automática de exceções Javascript não tratadas na SPA.
   * Envio automático com metadados para endpoint de telemetria: rota atual, `correlation_id` retornado pela última chamada HTTP, versão do app, modelo do dispositivo e navegador.
3. **Resiliência Offline / PWA:**
   * Detecção de perda de conectividade (`navigator.onLine = false`) exibindo aviso não-bloqueante na interface.

---

## 4. Saúde Específica da Camada de Banco de Dados (Aurora PostgreSQL)

Como o banco é compartilhado por todos os microsserviços e adota **IAM Database Authentication** com tokens transitórios de 15 minutos, a monitoração do banco exige métricas especializadas:

### 4.1. Métricas do Sistema Operacional & Cluster Aurora
* **Aurora ACU Consumption:** Variação de capacidade e limites de escalonamento dinâmico.
* **Buffer Cache Hit Ratio:** Deve permanecer **> 99%**. Abaixo de 95% indica falta de índices ou consultas fazendo varredura sequencial (*Full Table Scans*).
* **Active vs Idle Connections:** Relação de conexões ativas vs conexões em espera (`idle in transaction`).

### 4.2. Monitoramento de Queries & Concorrência via `pg_stat_activity`
Implementação de rotina automatizada de verificação periódica de saúde do banco:

```sql
-- Detecção de queries lentas (> 1 segundo) em execução agora
SELECT pid, now() - query_start AS duration, query, state, usename
FROM pg_stat_activity
WHERE state != 'idle' 
  AND (now() - query_start) > interval '1 second'
ORDER BY duration DESC;

-- Detecção de transações presas em 'idle in transaction' (Perigo de esgotamento de conexões)
SELECT pid, now() - state_change AS idle_duration, query
FROM pg_stat_activity
WHERE state = 'idle in transaction' 
  AND (now() - state_change) > interval '10 seconds';

-- Verificação de locks e conflitos entre agendamentos simultâneos
SELECT blocked_locks.pid     AS blocked_pid,
       blocked_activity.usename  AS blocked_user,
       blocking_locks.pid    AS blocking_pid,
       blocking_activity.usename AS blocking_user,
       blocked_activity.query    AS blocked_statement,
       blocking_activity.query   AS blocking_statement
FROM  pg_catalog.pg_locks         blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks         blocking_locks 
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

---

## 5. Acordos de Nível de Serviço: SLIs, SLOs & Error Budgets

Para manter a confiabilidade sem paralisar as entregas contínuas, são formalizados os seguintes acordos internos de engenharia:

### 5.1. Matriz de SLOs do Hairdule 2.0
| Serviço | Indicador de Nível de Serviço (SLI) | Objetivo (SLO Mensal) | Orçamento de Erro (Error Budget) |
|---|---|---|---|
| **Motor de Disponibilidade** | % de requisições com status `200` e tempo de resposta `< 300ms`. | **99.5%** | 0.5% (máx. 21,6 minutos de degradação/mês) |
| **Criação de Agendamentos** | % de agendamentos criados com sucesso (`201` ou `409` esperado) sem erro `5xx`. | **99.9%** | 0.1% (máx. 4,3 minutos de indisponibilidade/mês) |
| **Portal do Cliente / Agendamento Público** | % de carregamento do portal público com status `200` em `< 1.5s`. | **99.8%** | 0.2% |
| **Disparo de Lembretes (EventBridge)** | % de lembretes processados e enfileirados até 5 minutos antes da janela programada. | **99.7%** | 0.3% |
| **Autenticação & Sessão (Cognito)** | % de logins concluídos com sucesso em `< 500ms`. | **99.9%** | 0.1% |

### 5.2. Regra de Governança do Error Budget
* Se o **Error Budget estiver > 50%:** Equipe pode manter ritmo acelerado de deploys de novas funcionalidades.
* Se o **Error Budget cair para < 20%:** Deploys de novas features são congelados temporariamente; o foco exclusivo torna-se correção de bugs, otimização de queries no Aurora e resiliência de infraestrutura.
* Se o **Error Budget for esgotado (0%):** Post-mortem obrigatório sem culpados (*Blameless Post-Mortem*) e criação de tarefas de confiabilidade com prioridade máxima.

---

## 6. Política de Alertas e Matriz de Escalonamento

Os alertas são segmentados em três níveis de criticidade para evitar fadiga de alertas (*Alert Fatigue*):

```
┌──────────────┐     Disparo Imediato      ┌───────────────────────────────────┐
│   NÍVEL P1   │ ────────────────────────► │ PagerDuty / OpsGenie + Telegram   │
│   (Crítico)  │                           │ SMS + Chamada de Voz para On-Call │
└──────────────┘                           └───────────────────────────────────┘

┌──────────────┐     Alerta em 5 min       ┌───────────────────────────────────┐
│   NÍVEL P2   │ ────────────────────────► │ Canal #alerts-tech no Slack       │
│   (Alerta)   │                           │ Ticket automático no Jira/Linear  │
└──────────────┘                           └───────────────────────────────────┘

┌──────────────┐     Relatório Diário      ┌───────────────────────────────────┐
│   NÍVEL P3   │ ────────────────────────► │ Resumo no Canal #dev-insights     │
│ (Informativo)│                           │ Digest matinal por e-mail         │
└──────────────┘                           └───────────────────────────────────┘
```

### 6.1. Especificação de Alertas Críticos (P1)
1. **Aurora DB Inatingível ou Pool Esgotado:**
   * *Condição:* 3 falhas consecutivas de conexão com o PostgreSQL em 1 minuto.
   * *Ação imediata:* Reinício automático de conexões, verificação de IAM token, acionamento do engenheiro de plantão.
2. **Taxa de Erro 5xx no API Gateway > 2% por 3 minutos:**
   * *Condição:* Erros de servidor disparando em múltiplos microsserviços simultaneamente.
   * *Ação:* Verificação de deploy recente no SST v4, rollback automático se acionado via CI/CD.
3. **Dead-Letter Queue (DLQ) com Mensagens Acumuladas:**
   * *Condição:* `ApproximateNumberOfMessagesVisible > 0` na DLQ de notificações ou agendamentos.
   * *Ação:* Investigação de payload corrompido ou indisponibilidade de provedor externo (SES/WebPush).
4. **WAF Bloqueando Tráfego Legítimo:**
   * *Condição:* Salto repentino de 403 originados do AWS WAF (> 15% das requisições).

---

## 7. Estrutura dos Dashboards no Modelo Híbrido

A monitoração técnica opera de forma complementar em **dois ambientes**:

---

### 7.1. Camada A: Telemetria Profunda no AWS CloudWatch Dashboards (SRE & DevOps)
Provisionada via SST v4 (`sst.config.ts`), acessível pelo console da AWS para investigação de causa-raiz.

#### Dashboard 1: "Hairdule Global Command Center" (Telão de Operações)
* **Widget 1 (Top Left):** Status de Saúde dos 9 Microsserviços (Indicadores Verde/Amarelo/Vermelho com uptime 24h).
* **Widget 2 (Top Right):** Requisições por Segundo (RPS) no API Gateway vs Erros 4xx/5xx (Linha temporal).
* **Widget 3 (Center):** Latência P50, P95 e P99 em milissegundos agrupada pelos endpoints de maior impacto (`/availability`, `/appointments`, `/auth`).
* **Widget 4 (Bottom Left):** Utilização de ACUs do Aurora PostgreSQL e Conexões Ativas.
* **Widget 5 (Bottom Right):** Cold Starts por minuto e contagem de Lambda Throttling.

#### Dashboard 2: "Deep-Dive Lambdas & Serverless Runtime"
* Duração média e máxima por função Lambda (`barbershop`, `staff`, `availability`, etc.).
* Gráficos de consumo de memória (MB) por invocação para calibrar o provisionamento exato no SST v4.
* Taxa de invocação síncrona (API Gateway) vs assíncrona (EventBridge Scheduler).

#### Dashboard 3: "PostgreSQL & Persistence Analytics"
* Leituras e gravações por segundo no cluster Aurora.
* Tempo de espera de bloqueios de banco (*Lock Wait Time*).
* Estatísticas de crescimento volumétrico de tabelas: `appointments`, `appointment_audit_logs`, `notifications`.
* Monitor de dead tuples e eficiência do autovacuum.

---

### 7.2. Camada B: Aba "Saúde dos Serviços" no Portal SuperAdmin (`/admin/system-health`)
Projetada para que fundadores e suporte técnico identifiquem instabilidades **sem precisar entrar no console da AWS**.

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  HAIRDULE SUPERADMIN ── PAINEL DE SAÚDE DOS SERVIÇOS (/admin/system-health)   [🔄 Atualizar (Auto 30s)] │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 🩺 STATUS GERAL DA PLATAFORMA:  🟢 TODOS OS SERVIÇOS OPERACIONAIS (Uptime 24h: 99.94%)                 │
│                                                                                                        │
│ ┌───────────────────────────────────────┐ ┌───────────────────────────────────────┐                    │
│ │ 🗄️ AURORA POSTGRESQL 18.4 (SERVERLESS)│ │ ⚡ API GATEWAY V2 & WAF               │                    │
│ │ • Status: 🟢 Saudável (ACU: 1.2 / 8.0) │ │ • Throughput: 42.5 RPS                │                    │
│ │ • Pool de Conexões: 18 / 120 (15%)    │ │ • Taxa de Erro 5xx: 0.00%             │                    │
│ │ • Query P95: 14.2ms | Locks: 0 ativos │ │ • WAF Status: 🟢 0 bloqueios anômalos  │                    │
│ └───────────────────────────────────────┘ └───────────────────────────────────────┘                    │
│                                                                                                        │
│ 📊 SEMÁFORO DOS 9 MICROSSERVIÇOS (FASTAPI LAMBDAS):                                                    │
│ ┌───────────────────────────────────────────────┬────────────┬───────────┬──────────────┬────────────┐ │
│ │ Microsserviço                                 │ Status     │ P95 (ms)  │ Erros (24h)  │ ColdStarts │ │
│ ├───────────────────────────────────────────────┼────────────┼───────────┼──────────────┼────────────┤ │
│ │ 1. Auth Service (3001)                        │ 🟢 Online  │ 142ms     │ 0.01%        │ 3 / hora   │ │
│ │ 2. Barbershop Service (3002)                  │ 🟢 Online  │ 98ms      │ 0.00%        │ 1 / hora   │ │
│ │ 3. Staff Service (3003)                       │ 🟢 Online  │ 85ms      │ 0.00%        │ 1 / hora   │ │
│ │ 4. Service Catalog (3004)                     │ 🟢 Online  │ 62ms      │ 0.00%        │ 0 / hora   │ │
│ │ 5. Availability Engine (3005)                 │ 🟢 Online  │ 184ms     │ 0.02%        │ 4 / hora   │ │
│ │ 6. Appointment Service (3006)                 │ 🟢 Online  │ 210ms     │ 0.01%        │ 5 / hora   │ │
│ │ 7. Subscription Service (3007)                │ 🟢 Online  │ 120ms     │ 0.00%        │ 0 / hora   │ │
│ │ 8. Notification Service (3008)                │ 🟢 Online  │ 94ms      │ 0.00%        │ 2 / hora   │ │
│ │ 9. Analytics Service (3009)                   │ 🟢 Online  │ 310ms     │ 0.00%        │ 1 / hora   │ │
│ └───────────────────────────────────────────────┴────────────┴───────────┴──────────────┴────────────┘ │
│                                                                                                        │
│ 🔌 INTEGRAÇÕES EXTERNAS:                                                                               │
│ • Stripe API: 🟢 Conectado (RTT: 180ms)    • AWS SES: 🟢 Reputação 100% (Bounce: 0.2%)                 │
│ • WebPush VAPID: 🟢 98.4% Entrega          • EventBridge Scheduler: 🟢 0 drops / 0 em DLQ              │
│                                                                                                        │
│ ────────────────────────────────────────────────────────────────────────────────────────────────────── │
│ [ 🔍 Abrir Telemetria Profunda no AWS CloudWatch ] ────► [ Link seguro com SSO IAM ]                   │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

### 7.3. Especificação do Endpoint Backend BFF (`GET /admin/health/status`)
Para alimentar a aba `/admin/system-health` sem sobrecarregar a AWS, criamos uma rota protegida por perfil `SUPERADMIN`:

* **Rota:** `GET /admin/health/status`
* **Mecanismo de Cache:** TTL de 30 a 60 segundos em memória (para que requisições frequentes não gerem custos no CloudWatch GetMetricData).
* **Lógica de Execução:**
  1. Executa um ping leve no Aurora (`SELECT 1`, contagem de conexões ativas em `pg_stat_activity`).
  2. Consulta as últimas métricas sumarizadas das Lambdas via AWS SDK Boto3 (`cloudwatch.get_metric_data`).
  3. Checa métricas de entrega SES e DLQ SQS.
  4. Retorna JSON pronto e formatado para a UI do Angular 19 exibir sem necessidade de cálculos em memória.

---

## 8. Roteiro de Implementação Técnica (Passo a Passo)

1. **Sprint 1 — Fundação de Métricas & EMF:**
   * Instalar utilitário EMF no `fase_05_hairdule_shared`.
   * Enriquecer o `RequestLoggingMiddleware` para registrar automaticamente métricas de latência e cold start sem custo.
2. **Sprint 2 — Dashboards & Alarmes no AWS CloudWatch (IaC SST v4):**
   * Definir os 3 Dashboards no SST v4 (`fase_07_hairdule_infra_api` / infra) contendo os 4 Golden Signals.
   * Criar alarmes de infraestrutura para limites de 5xx, ACU e Lambda Throttling com dispatch via SNS -> Discord/Slack/Telegram.
3. **Sprint 3 — Endpoint BFF Administrativo (`GET /admin/health/status`):**
   * Criar o serviço agregador com Boto3 CloudWatch e verificação do pool Aurora PostgreSQL.
   * Configurar cache de 30s e controle rigoroso de acesso RBAC via Cognito claim `superadmin`.
4. **Sprint 4 — Aba "Saúde dos Serviços" no Frontend Angular 19:**
   * Desenvolver os componentes standalone no repositório `fase_08_hairdule_ui_web` (`features/superadmin/system-health`).
   * Adicionar polling reativo a cada 30 segundos (via Angular Signals) e botão com deep link para o CloudWatch Console.
5. **Sprint 5 — Observabilidade do Aurora & Instrumentação RUM:**
   * Ativar o *Performance Insights* no cluster Aurora PostgreSQL 18.4.
   * Injetar captura de Core Web Vitals no Angular 19 e interceptor HTTP com propagação de `X-Correlation-ID`.

