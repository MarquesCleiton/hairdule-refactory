# 🟢 [VULN-08] [BAIXO / FINOPS] Ausência de WAF em Staging e Política Permissiva no Cognito (MFA e Proteção Avançada Desativados)

| Metadado | Detalhe |
|---|---|
| **ID da Vulnerabilidade** | `VULN-08` |
| **Status da Correção** | [x] ✅ **CORRIGIDO E VALIDADO** (2026-09-28) |
| **Severidade** | 🟢 **BAIXA / FINOPS (CVSS 4.3)** |
| **CVSS v3.1 Vector** | `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:L` |
| **Classificação CWE** | [CWE-307: Improper Restriction of Excessive Authentication Attempts](https://cwe.mitre.org/data/definitions/307.html) / [CWE-308: Use of Single-factor Authentication](https://cwe.mitre.org/data/definitions/308.html) |
| **Componentes Afetados** | [`fase_07_hairdule_infra_api/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/sst.config.ts#L481-L565)<br>AWS Cognito User Pool `us-east-1_tPfrA7wPP`<br>[`fase_03_hairdule_infra_auth/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_03_hairdule_infra_auth/sst.config.ts) |
| **Evidência AWS Coletada** | `MfaConfiguration: "OFF"`, `UserPoolAddOns: null`, `RequireSymbols: false` |

---

## 1. Descrição Técnica da Falha

Durante a auditoria da infraestrutura AWS ativa e do código de infraestrutura como código (IaC SST v4), foram identificadas duas configurações permissivas:

### 1.1 Desativação de WAF e Rate Limiting no Ambiente de Homologação
No arquivo [`fase_07_hairdule_infra_api/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/sst.config.ts#L481-L485):
```typescript
let webAclArn: pulumi.Input<string> = "none";
if (stage === "production") {
  const webAcl = new aws.wafv2.WebAcl("HairduleApiWebAcl", { ... });
  webAclArn = webAcl.arn;
}
```
Para fins de economia em Staging, o AWS WAF v2 só é instanciado em produção. Com isso, no ambiente de homologação (que está público na internet), **não há nenhuma barreira de Rate Limiting por IP nem inspeção contra OWASP Top 10** na borda do API Gateway.

### 1.2 Configuração Permissiva no Cognito User Pool
A consulta ao User Pool do projeto (`us-east-1_tPfrA7wPP`) revelou:
- `MfaConfiguration`: `"OFF"` (Autenticação de Dois Fatores desativada para todos os perfis, inclusive proprietários e administradores).
- `UserPoolAddOns`: `null` (Advanced Security Features desativadas — sem detecção de senhas vazadas, sem bloqueio adaptativo de IP e sem análise heurística de risco).
- `RequireSymbols`: `false` (senhas não exigem caracteres especiais).

---

## 2. Cenário de Ataque e Exploração Teórica

### Vetor Teórico de Exploração:
1. **Ataque de Credential Stuffing / Força Bruta**:
   Um atacante obtém listas de vazamentos de credenciais da internet (combinações de e-mail e senha frequentes).
2. Como o WAF está desligado em Staging e o Cognito Advanced Security está desligado, um bot pode disparar centenas de tentativas por segundo contra o endpoint `POST /auth/login`.
3. O sistema não bloqueia o IP de origem por taxa de requisição nem aplica desafios de CAPTCHA / MFA.
4. **Impacto FinOps e de Disponibilidade**: As chamadas contínuas acionam conexões com o Aurora PostgreSQL Serverless v2, forçando o cluster a escalar sua capacidade em ACUs (Aurora Capacity Units), gerando custo desnecessário e consumo de conexões do pool.

---

## 3. Impacto de Negócio e de Segurança

- **Vulnerabilidade a Password Spraying**: Facilita o comprometimento de contas com senhas fracas.
- **Risco de Faturamento Inesperado (FinOps)**: Escala desnecessária de instâncias Serverless e banco de dados devido a tráfego automatizado de varredura.

---

## 4. Plano de Remediação Recomendado

### Passo 1: Habilitar Throttling Nativo no API Gateway (Sem Custo Adicional)
Mesmo sem o WAF v2 (que possui custo de ~$5/mês por WebACL + regras), o API Gateway v2 possui mecanismo nativo e gratuito de **Throttling no Stage**:

```typescript
// Em fase_07_hairdule_infra_api/sst.config.ts
const apiStage = new aws.apigatewayv2.Stage("DefaultStage", {
  apiId: httpApi.id,
  name: "$default",
  autoDeploy: true,
  defaultRouteSettings: {
    throttlingBurstLimit: 100, // Limite de rajada
    throttlingRateLimit: 50,   // Máximo de 50 req/segundo
  },
  ...
});
```

### Passo 2: Ativar MFA Opcional/Obrigatório para Perfis de Gestão
No Cognito User Pool, configurar `MfaConfiguration: "OPTIONAL"` para permitir que proprietários e colaboradores ativem autenticação via aplicativo autenticador (TOTP como Google Authenticator ou Microsoft Authenticator).

### Passo 3: Ativar Advanced Security em Modo `AUDIT`
Ativar o `UserPoolAddOns` do Cognito no modo de auditoria para monitorar tentativas de login suspeitas e barrar o uso de senhas sabidamente comprometidas em violações de dados públicas.

---

## 5. Evidência da Correção Aplicada

- **Arquivos Modificados**:
  - [`fase_07_hairdule_infra_api/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/sst.config.ts)
  - [`fase_03_hairdule_infra_auth/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_03_hairdule_infra_auth/sst.config.ts)
  - [`fase_03_hairdule_infra_auth/config/environments.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_03_hairdule_infra_auth/config/environments.ts)
- **Implementação**:
  - No `apiStage` (`DefaultStage`) do API Gateway HTTP, foi configurado `defaultRouteSettings` com `throttlingBurstLimit: 100` e `throttlingRateLimit: 50`, fornecendo proteção nativa e gratuita contra força bruta e DoS de baixo custo mesmo sem provisionar instâncias de WAF em Staging.
  - No IaC da Fase 03 (`sst.config.ts`), o Cognito User Pool foi atualizado com suporte a `mfaConfiguration: "OPTIONAL"`, `softwareTokenMfaConfiguration: { enabled: true }` (TOTP habilitado) e `userPoolAddOns: { advancedSecurityMode: "AUDIT" }` (em Staging) / `"ENFORCED"` (em Produção).

