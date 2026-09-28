# 🛡️ Plano de Implementação: RouteSettings e Throttling no AWS API Gateway

> **Status:** 📋 Pronto para Execução  
> **Prioridade:** 🚨 Imediata (Mitigação direta de testes de estresse e bots)  
> **Repositório Afetado:** `fase_07_hairdule_infra_api`  
> **Arquivo Alvo:** [`sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/sst.config.ts)

---

## 1. Problema Identificado

Atualmente, o `DefaultStage` do AWS API Gateway HTTP API v2 possui apenas uma configuração global:
```typescript
defaultRouteSettings: {
  throttlingBurstLimit: 100,
  throttlingRateLimit: 50,
}
```
Como o limite é agregado no estágio, testes rápidos como o realizado com o Insomnia (requisições a cada `0,01s`) passam sem bloqueio porque uma rajada curta (ex: 20 requisições) consome menos que os 100 tokens do balde.

---

## 2. Solução Técnica

Configurar a propriedade `routeSettings` diretamente no recurso `aws.apigatewayv2.Stage` em `sst.config.ts`. O API Gateway HTTP API permite especificar limites individuais por `routeKey`.

### Tabela de Parâmetros Proposta

| Rota (`routeKey`) | Burst Limit | Rate Limit (req/s) | Justificativa |
| :--- | :---: | :---: | :--- |
| `GET /public/appointments/by-phone` | **3** | **1.0** | Um cliente humano nunca consulta mais de 1x por segundo. Bloqueia scraping instantaneamente. |
| `POST /auth/login` | **5** | **2.0** | Limita tentativas consecutivas de brute-force e ataques de dicionário. |
| `POST /auth/signup` | **3** | **1.0** | Criação de barbearias e usuários; impede criação automatizada em massa. |
| `POST /auth/forgot-password` | **3** | **1.0** | Impede spam e esgotamento da cota de envio de e-mails via SES. |
| `POST /public/appointments` | **5** | **2.0** | Protege a agenda das barbearias contra preenchimento massivo por robôs. |
| `POST /public/appointments/{booking_code}/request-cancel` | **3** | **1.0** | Previne email bombing de magic links de cancelamento. |
| `POST /public/appointments/{booking_code}/request-reschedule` | **3** | **1.0** | Previne email bombing de magic links de remarcação. |

---

## 3. Implementação Proposta (`sst.config.ts`)

```typescript
    // 3. STAGE PADRÃO ($default) COM AUTO-DEPLOY E ACCESS LOGS
    const apiStage = new aws.apigatewayv2.Stage("DefaultStage", {
      apiId: httpApi.id,
      name: "$default",
      autoDeploy: true,
      defaultRouteSettings: {
        throttlingBurstLimit: 50,
        throttlingRateLimit: 25,
      },
      routeSettings: [
        {
          routeKey: "GET /public/appointments/by-phone",
          throttlingBurstLimit: 3,
          throttlingRateLimit: 1,
        },
        {
          routeKey: "POST /auth/login",
          throttlingBurstLimit: 5,
          throttlingRateLimit: 2,
        },
        {
          routeKey: "POST /auth/signup",
          throttlingBurstLimit: 3,
          throttlingRateLimit: 1,
        },
        {
          routeKey: "POST /auth/forgot-password",
          throttlingBurstLimit: 3,
          throttlingRateLimit: 1,
        },
        {
          routeKey: "POST /public/appointments",
          throttlingBurstLimit: 5,
          throttlingRateLimit: 2,
        },
        {
          routeKey: "POST /public/appointments/{booking_code}/request-cancel",
          throttlingBurstLimit: 3,
          throttlingRateLimit: 1,
        },
        {
          routeKey: "POST /public/appointments/{booking_code}/request-reschedule",
          throttlingBurstLimit: 3,
          throttlingRateLimit: 1,
        },
      ],
      accessLogSettings: {
        destinationArn: accessLogsLogGroup.arn,
        format: JSON.stringify({
          requestId: "$context.requestId",
          ip: "$context.identity.sourceIp",
          requestTime: "$context.requestTime",
          httpMethod: "$context.httpMethod",
          routeKey: "$context.routeKey",
          status: "$context.status",
          protocol: "$context.protocol",
          responseLength: "$context.responseLength",
          integrationLatency: "$context.integrationLatency",
        }),
      },
    });
```

---

## 4. Plano de Teste e Validação

1. **Deploy via GitFlow**:
   - Push na branch de feature da `fase_07_hairdule_infra_api`, PR e merge para `release/v19` acionando o deploy de homologação.
2. **Teste com Insomnia / Script**:
   - Enviar 10 requisições seguidas para `GET /public/appointments/by-phone` com intervalo de `0,01s`.
   - **Resultado Esperado:** As primeiras 3 requisições retornam `200`, e a partir da 4ª requisição o API Gateway responde imediatamente com:
     ```http
     HTTP/1.1 429 Too Many Requests
     Content-Type: application/json

     {"message": "Too Many Requests"}
     ```
   - Nenhuma chamada excedente chega a invocar a função Lambda ou abrir conexões com o Aurora PostgreSQL.
