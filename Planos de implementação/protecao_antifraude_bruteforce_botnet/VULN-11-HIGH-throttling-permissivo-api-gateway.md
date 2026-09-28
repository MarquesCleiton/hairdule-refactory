# VULN-11 — Throttling Permissivo no API Gateway Permitindo Rajadas Rápidas e DoS L7

> **Status:** [ ] 🔴 **Pendente de Correção**  
> **Severidade:** 🔶 **ALTA**  
> **CVSS v3.1:** 7.8 (`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H`)  
> **Repositório Afetado:** [`fase_07_hairdule_infra_api`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api)  
> **Arquivo Alvo:** [`sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/sst.config.ts)

---

## 1. Descrição da Vulnerabilidade

O API Gateway HTTP API v2 possui apenas uma configuração global no stage `$default`:
```typescript
defaultRouteSettings: {
  throttlingBurstLimit: 100,
  throttlingRateLimit: 50,
}
```

O algoritmo *Token Bucket* da AWS permite que uma rajada instantânea de até **100 requisições simultâneas** passe sem nenhum bloqueio. Em testes reais utilizando o Insomnia com taxa de `0,01s` (100 req/s), dezenas de requisições foram repassadas instantaneamente para a Lambda e para o banco de dados Aurora PostgreSQL, todas respondendo com `200 OK`. 

Sob estresse de concorrência, o pool do banco e a concorrência Lambda são esgotados, resultando em `503 Service Unavailable` em vez de frear o invasor com `429 Too Many Requests`.

---

## 2. Cenário de Ataque

```
[ Atacante / Insomnia com intervalo de 0.01s ]
       │
       ▼ (Dispara 30 requisições em 300 milissegundos)
[ API Gateway verifica DefaultRouteSettings: BurstLimit = 100 ]
       │
       ▼ (Como 30 < 100, nenhuma ficha esgotou no balde)
[ API Gateway permite TODAS as 30 requisições ]
       │
       ▼
[ Dispara 30 Lambdas concorrentes contra o banco Aurora PostgreSQL ]
```

---

## 3. Evidência no Código Atual

Arquivo: `fase_07_hairdule_infra_api/sst.config.ts` (linhas 80 a 83):

```typescript
      defaultRouteSettings: {
        throttlingBurstLimit: 100, // ⚠️ Muito permissivo para rotas públicas
        throttlingRateLimit: 50,
      },
```

---

## 4. Solução Técnica Proposta

Adicionar a propriedade `routeSettings` no recurso `aws.apigatewayv2.Stage` definindo limites rígidos individuais para cada rota sensível:

```typescript
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
```

---

## 5. Checklist de Implementação & Validação

- [ ] Atualizar `sst.config.ts` na `fase_07_hairdule_infra_api` com o array `routeSettings`.
- [ ] Executar deploy em Homologação (`release/v19`).
- [ ] Disparar requisições em rajada a cada `0,01s` via Insomnia ou script no endpoint `GET /public/appointments/by-phone`.
- [ ] Validar que a partir da 4ª requisição o Gateway devolve imediatamente:
  ```http
  HTTP/1.1 429 Too Many Requests
  {"message": "Too Many Requests"}
  ```
