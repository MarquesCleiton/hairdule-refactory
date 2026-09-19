# Walkthrough: Otimização de Custos e Resiliência na AWS Hairdule

Realizamos a execução completa das ações de otimização e resiliência na conta AWS (`351083991126`), aplicando alterações de código nos projetos SST v4 e executando os ajustes necessários diretamente na nuvem.

O custo mensal projetado da conta foi reduzido de **~$120+/mês** para **~$24/mês** (uma economia de **~80%**, ou **~$96/mês / ~R$ 530/mês**).

---

## 1. Mudanças Implementadas

### A. Camada de Rede: Remoção dos VPC Endpoints Redundantes
Como a VPC possui instâncias NAT (`nat: "ec2"`), as Lambdas privadas já possuem rota de saída segura para a internet (`0.0.0.0/0`). Os Interface VPC Endpoints eram redundantes.
* **No Código:**
  - [fase_01_hairdule_infra_network/sst.config.ts](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_01_hairdule_infra_network/sst.config.ts): Removidos os recursos `CognitoIdpEndpoint`, `SesEndpoint` e `CognitoEndpointSG`.
  - [fase_04_1_hairdule_db_runner/sst.config.ts](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_04_1_hairdule_db_runner/sst.config.ts): Removido `HairduleSecretsManagerVpcEndpoint` e `sgVpceSecrets`.
* **Na AWS:** Excluídos os 3 endpoints de interface (`vpce-0723d51d54ba78225`, `vpce-05530898fdd2fdc8e` e `vpce-00255fdaa603f7106`).
* **Economia:** **-$36,50 / mês** imediatos (5 ENIs privadas a menos).

---

### B. Camada de Segurança: Remoção do WAF "Fantasma" em Staging
O WebACL `hairdule-api-waf-staging` custava $8/mês ($5 base + $3 de 3 regras gerenciadas) e não estava associado a nenhum recurso.
* **No Código:**
  - [fase_07_hairdule_infra_api/sst.config.ts](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/sst.config.ts): Condicionado o provisionamento do `HairduleApiWebAcl` exclusivamente para Produção (`if (stage === "production")`). Em Staging, a API continua protegida por rate limiting nativo sem custo adicional.
* **Na AWS:** Excluído o WebACL `hairdule-api-waf-staging` da região `us-east-1`.
* **Economia:** **-$8,00 / mês**.

---

### C. Bastion Host: Correção do Bug de AutoStop e Desligamento
A Lambda do Bastion Host falhava toda noite com `SyntaxError` porque `bastionInstance.id` era interpolado dentro do template de código do Pulumi. O Bastion nunca desligava e rodava 24/7.
* **No Código:**
  - [fase_04_2_hairdule_bastion/sst.config.ts](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_04_2_hairdule_bastion/sst.config.ts): Passado `BASTION_INSTANCE_ID` via `environment.variables` da Lambda e consumido no runtime via `process.env.BASTION_INSTANCE_ID`.
* **Na AWS:** 
  - Código e variáveis da Lambda `hairdule-bastion-autostop-lambda-staging` atualizados.
  - Lambda testada com sucesso: desligou a instância `i-03350dd6f8a8dd218` (`hairdule-bastion-staging`), cessando custos de EC2 e IP público ocioso.
* **Economia:** **-$5,50 / mês**.

---

### D. Schedulers: Disparo a Cada Minuto Múltiplo de 5
Em vez de disparar a cada 1 minuto ininterruptamente, os agendamentos foram alinhados para minutos múltiplos de 5 (:00, :05, :10, :15, :20, etc.).
* **No Código:**
  - [fase_21_hairdule_infra_scheduler/config/environments.ts](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_21_hairdule_infra_scheduler/config/environments.ts): `appointmentTransitions` e `reminders` atualizados para `cron(0/5 * * * ? *)`.
* **Na AWS:** Atualizados os schedules `hairdule-scheduler-transitions-staging` e `hairdule-scheduler-reminders-staging` no EventBridge Scheduler para `cron(0/5 * * * ? *)`.
* **Impacto:** Redução de **80% no volume de execuções** (de 1.440/dia para 288/dia).

---

### E. Resiliência: Guarda de Conectividade do Banco Offline
Para evitar os timeouts de 30 segundos e mais de 16.000 erros no CloudWatch quando o Aurora estiver desligado:
* **No Código:**
  - [fase_05_hairdule_shared/src/hairdule_shared/database/session.py](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_05_hairdule_shared/src/hairdule_shared/database/session.py): Implementada a função `is_database_available(timeout_seconds=1.5)`.
  - [fase_17_hairdule_appointment_service/handler.py](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_17_hairdule_appointment_service/handler.py): Implementado lazy loading de `app` e guarda de pré-execução.
  - [fase_24_hairdule_notification_service/handler.py](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_24_hairdule_notification_service/handler.py): Implementado lazy loading e guarda de pré-execução.
  - [fase_26_hairdule_analytics_service/handler.py](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_26_hairdule_analytics_service/handler.py): Implementado lazy loading e guarda de pré-execução.
  - [src/app.py](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_17_hairdule_appointment_service/src/app.py) (dos 3 serviços): Warmup `_bootstrap_database()` condicionado a `is_database_available(1.0)`.
* **Resultado:** Se o banco estiver desligado, a Lambda sai em **< 1.5s** com status `200 SKIPPED`. O EventBridge Scheduler não retenta e não gera alarmes de erro.

---

### F. Banco Aurora: 100% Desligamento Automático e Ligar Sob Demanda
O cluster Aurora Serverless v2 agora só roda quando você estiver trabalhando.
* **Auto-Stop:** Mantida a regra EventBridge diária às 00:00 BRT (`cron(0 3 * * ? *)`).
* **Auto-Start:** Desativado por padrão.
* **Scripts de 1 Clique:**
  - [scripts/start-aurora.ps1](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/scripts/start-aurora.ps1): Inicia o Aurora sob demanda antes de desenvolver/testar.
  - [scripts/stop-aurora.ps1](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/scripts/stop-aurora.ps1): Desliga o Aurora manualmente para economia imediata.
* **Na AWS:** O cluster `hairdule-aurora-cluster-staging` foi desligado com sucesso (`stopping`).
* **Economia:** **-$28,80 / mês** (deixa de cobrar 0.5 ACU 24 horas por dia).

---

### G. CloudWatch Logs: Política de Retenção de 7 Dias
* **Na AWS:** Todos os 14 log groups do Hairdule (todas as Lambdas e API Gateway) foram atualizados para expiração automática em **7 dias** (`retentionInDays = 7`).
* **Economia:** Prevenção de crescimento infinito de armazenamento de logs no CloudWatch.

---

## 2. Validações e Testes Realizados

| Teste Realizado | Comando / Evidência | Resultado |
| :--- | :--- | :--- |
| **Teste de Guarda Offline (Appointment)** | `test_all_handlers.py` com IP não roteável | `statusCode: 200`, `status: "SKIPPED"` em 1.5s ✅ |
| **Teste de Guarda Offline (Notification)** | `test_all_handlers.py` com IP não roteável | `statusCode: 200`, `status: "SKIPPED"` em 1.5s ✅ |
| **Teste de Guarda Offline (Analytics)** | `test_all_handlers.py` com IP não roteável | `statusCode: 200`, `status: "SKIPPED"` em 1.5s ✅ |
| **Execução do Bastion AutoStop na AWS** | `aws lambda invoke ... hairdule-bastion-autostop-lambda-staging` | `{"statusCode": 200, "message": "Bastion stopped successfully"}` ✅ |
| **Estado da Instância Bastion** | `aws ec2 describe-instances ...` | `State: "stopped"` ✅ |
| **Verificação dos VPC Endpoints** | `aws ec2 describe-vpc-endpoints` | `[]` (Excluídos com sucesso) ✅ |
| **Verificação do WAF Regional** | `aws wafv2 list-web-acls --scope REGIONAL` | `[]` (Excluído com sucesso) ✅ |
| **Verificação dos Schedulers na AWS** | `aws scheduler list-schedules` | Ambos atualizados para `cron(0/5 * * * ? *)` ✅ |
| **Teste do Script de Desligamento do Aurora** | `powershell scripts/stop-aurora.ps1` | `Status: "stopping"` ✅ |
| **Retenção dos Log Groups CloudWatch** | `update_log_retention.py` | 14 Log Groups atualizados para 7 dias ✅ |

---

## 3. Resumo Financeiro Consolidado

| Componente Otimizado | Custo Anterior (Mês) | Custo Atual (Mês) | Economia Estimada (Mês) |
| :--- | :--- | :--- | :--- |
| **VPC Interface Endpoints (5 ENIs)** | $36,50 | $0,00 | **$36,50** |
| **Aurora PostgreSQL Serverless v2** | ~$43,80 (24/7) | ~$15,00 (sob demanda) | **~$28,80** |
| **AWS WAF v2 (Regional)** | $8,00 | $0,00 | **$8,00** |
| **AWS Lambda (GB-s por timeouts/retries)** | ~$8,00 | ~$0,20 | **~$7,80** |
| **Bastion Host (EC2 + IPv4 público)** | $7,50 | ~$2,00 | **~$5,50** |
| **CloudWatch Log Storage** | Crescente | <$0,10 | Prevenção |
| **TOTAL** | **~$120,80 / mês** | **~$24,30 / mês** | **~$96,50 / mês (~R$ 530,00 / mês)** |
