# Plano de Implementação: Otimização de Custos AWS e Resiliência de Schedulers

Este plano detalha a implementação técnica de todas as ações de otimização de custos e melhorias operacionais solicitadas para o ambiente de Staging do Hairdule 2.0.

A meta é reduzir a fatura da AWS de **~$115+/mês** para **~$24/mês** (economia de **~80%** ou **~$90/mês / R$ 500/mês**), garantindo que o banco de dados seja desligado e religado diariamente e que os Schedulers nunca gerem erros ou timeouts desnecessários durante a hibernação do Aurora.

---

## Revisão do Usuário & Decisões de Design

> [!IMPORTANT]
> **1. Aurora PostgreSQL (100% Desligamento Automático, Religamento Apenas Manual):**
> * **Auto-Stop:** Diariamente às **00:00 BRT** (`cron(0 3 * * ? *)`). O banco desliga sozinho todas as noites se estiver ligado.
> * **Auto-Start:** **DESATIVADO**. O cluster **NÃO** ligará sozinho. Ficará desligado economizando 100% do custo de ACUs até que você decida ligá-lo manualmente para testar/desenvolver.
> * **Facilidade para ligar:** Criaremos um script/comando rápido de 1 clique (`scripts/start-aurora.ps1`) para ligar o banco quando você for trabalhar.
>
> **2. Schedulers em Minutos Múltiplos de 5 (`cron(0/5 * * * ? *)`):**
> * Em vez de rodar a cada 1 minuto (que causava 1.440 invocações/dia e impedia o banco de dormir) ou `rate(5 minutes)` descompassado do relógio, os schedulers serão alinhados para disparar **exatamente nos minutos múltiplos de 5** (:00, :05, :10, :15, :20, :25, :30, :35, :40, :45, :50, :55).
> * Expressão cron: `cron(0/5 * * * ? *)`.
> * Isso reduz em **80% o número de execuções**, mantém a pontualidade perfeita dos agendamentos (já que atendimentos são marcados em blocos de 15/30/45 min) e permite que os lembretes de push saiam no minuto exato.
>
> **3. Schedulers Resilientes (Guarda de Conectividade com o Banco):**
> * Todas as rotinas que rodarem no minuto múltiplo de 5 validarão se o banco está de pé via teste TCP rápido (< 1.5s).
> * Se o Aurora estiver desligado (hibernado), a Lambda retorna imediatamente `200 SKIPPED`, sem ficar 30s pendurada em timeout, sem erros no CloudWatch e sem custo desnecessário.

---

## Mudanças Propostas

### 1. Camada de Rede: Remoção de VPC Endpoints Redundantes

Como a VPC já possui instâncias NAT (`nat: "ec2"`) provisionadas na [Fase 01](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_01_hairdule_infra_network/sst.config.ts), todas as subnets privadas já possuem saída para a internet. Os Interface VPC Endpoints para Cognito, SES e Secrets Manager são completamente redundantes e custam **$36,50/mês** (5 ENIs privadas).

#### [MODIFY] [fase_01_hairdule_infra_network/sst.config.ts](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_01_hairdule_infra_network/sst.config.ts)
* Remover `CognitoEndpointSG`, `CognitoIdpEndpoint` e `SesEndpoint`.
* Atualizar outputs para não expor os IDs dos endpoints removidos.

#### [MODIFY] [fase_04_1_hairdule_db_runner/sst.config.ts](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_04_1_hairdule_db_runner/sst.config.ts)
* Remover `HairduleSecretsManagerVpcEndpoint` e `sgVpceSecrets`. O `db-runner` já acessa o Secrets Manager perfeitamente via rota padrão NAT.

---

### 2. Camada de Banco de Dados: Auto-Stop Diário do Aurora e Script de Religamento Manual

O cluster Aurora Serverless v2 (`hairdule-aurora-cluster-staging`) ficará desligado por padrão, ligando **somente quando você for usar** e desligando automaticamente todas as noites se estiver ligado.

#### [MODIFY] [fase_04_hairdule_db/config/environments.ts](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_04_hairdule_db/config/environments.ts)
* Manter `autoStopSchedule: "cron(0 3 * * ? *)"` (00:00 BRT / 03:00 UTC) em Staging.
* Manter `autoStartSchedule: undefined` (desativado) para não ligar sozinho.

#### [NEW] [scripts/start-aurora.ps1](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/scripts/start-aurora.ps1) e [scripts/stop-aurora.ps1](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/scripts/stop-aurora.ps1)
* Scripts práticos em PowerShell para você iniciar ou parar o banco com 1 clique/comando antes e depois de desenvolver/testar.

---

### 3. Camada do Bastion Host: Correção do Bug de Auto-Stop

A Lambda `hairdule-bastion-autostop-lambda-staging` falha todas as noites com `SyntaxError` devido à interpolação de `bastionInstance.id` dentro do código JavaScript.

#### [MODIFY] [fase_04_2_hairdule_bastion/sst.config.ts](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_04_2_hairdule_bastion/sst.config.ts)
* Passar `BASTION_INSTANCE_ID: bastionInstance.id` através da propriedade `environment.variables` da Lambda.
* Atualizar o handler inline para ler `process.env.BASTION_INSTANCE_ID`.
* O Bastion passará a desligar todas as noites à meia-noite, cessando custo de computação e IPv4 ocioso.

---

### 4. Camada de API: Desativação do WAF "Fantasma" em Staging

O WebACL `hairdule-api-waf-staging` gera custo fixo de **$8,00/mês** e atualmente **não está associado a nenhum recurso**.

#### [MODIFY] [fase_07_hairdule_infra_api/sst.config.ts](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/sst.config.ts)
* Condicionar o provisionamento do `HairduleApiWebAcl` para rodar apenas em Produção (`stage === "production"`).
* Em Staging, o API Gateway HTTP API continua protegido por throttling padrão nativo sem custo adicional.

---

### 5. Resiliência dos Schedulers & Disparo em Múltiplos de 5 (`cron(0/5 * * * ? *)`)

Quando o Aurora está desligado (madrugada/fins de semana), as Lambdas acionadas pelo EventBridge Scheduler tentavam conectar ao banco, ficavam presas até o timeout de 30 segundos e retornavam erro 500. Isso gerou **16.471 erros** e queimou **254.000 GB-segundos** de Lambda.

#### [MODIFY] [fase_21_hairdule_infra_scheduler/config/environments.ts](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_21_hairdule_infra_scheduler/config/environments.ts)
* Configurar os agendamentos (`appointmentTransitions` e `reminders`) com a expressão cron:
  `scheduleExpression: "cron(0/5 * * * ? *)"`
* Isso garante que rodem **exatamente nos minutos múltiplos de 5** (:00, :05, :10, :15, :20, :25, :30, :35, :40, :45, :50, :55), sincronizados com o relógio.
* Corta o volume de execuções de transições de 1.440/dia para apenas 288/dia (redução de 80%).

#### [MODIFY] [fase_05_hairdule_shared/src/hairdule_shared/database/session.py](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_05_hairdule_shared/src/hairdule_shared/database/session.py)
* Adicionar a função `is_database_available(timeout_seconds: float = 1.5) -> bool`.
* Realiza um teste de conectividade TCP rápido com timeout curto (1.5s).
  - Se o banco estiver ligado: handshake TCP conclui em ~5ms dentro da VPC -> retorna `True`.
  - Se o banco estiver desligado: atinge timeout de 1.5s -> retorna `False`.

#### [MODIFY] [fase_17_hairdule_appointment_service/handler.py](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_17_hairdule_appointment_service/handler.py)
* No início do bloco `AUTO_TRANSITION_STATUSES`, verificar `is_database_available()`.
* Se retornar `False`: registrar log informativo `info` ("Banco hibernado, ignorando execução") e retornar imediatamente `{ "statusCode": 200, "status": "SKIPPED", "reason": "DATABASE_OFFLINE" }`.

#### [MODIFY] [fase_24_hairdule_notification_service/handler.py](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_24_hairdule_notification_service/handler.py)
* Adicionar a mesma validação para as ações `PROCESS_REMINDERS` e `PURGE_NOTIFICATIONS`.

#### [MODIFY] [fase_26_hairdule_analytics_service/handler.py](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_26_hairdule_analytics_service/handler.py)
* Adicionar a mesma validação para a ação `CONSOLIDATE_DAILY_ANALYTICS`.

---

### 6. CloudWatch Logs: Política de Retenção de 7 Dias

Atualmente, todos os 14 log groups de Lambdas em Staging estão com retenção indefinida (`Never Expire`), acumulando dezenas de megabytes sem expiração.

* Aplicar política de retenção de **7 dias** (`retentionInDays: 7`) em todos os Log Groups de Staging via script/AWS CLI.

---

## Plano de Verificação

### Testes Automatizados e Pré-Validação
1. **Validação de Sintaxe e Compilação SST:**
   - Executar `npx tsc --noEmit` nas fases modificadas para garantir tipagem perfeita.
2. **Teste Unitário da Validação de Banco:**
   - Testar `is_database_available()` com porta fechada/host inexistente para validar se retorna `False` em menos de 2 segundos sem lançar exceção não tratada.
   - Testar os handlers com o mock de banco offline garantindo retorno `HTTP 200 (SKIPPED)`.

### Verificação Manual na AWS
1. **Verificação do Aurora Start/Stop:**
   - Invocar manualmente a Lambda de controle do Aurora com `{"action": "STOP"}` e depois `{"action": "START"}` via AWS CLI / Console e monitorar a transição de estado.
2. **Verificação do Bastion Auto-Stop:**
   - Invocar manualmente `hairdule-bastion-autostop-lambda-staging` e verificar nos logs do CloudWatch se executou sem `SyntaxError`.
3. **Verificação dos Schedulers:**
   - Acionar a Lambda de agendamentos com evento de Scheduler simulando banco desligado e checar se o retorno é `200 SKIPPED` em < 2s sem estourar timeout de 30s.
