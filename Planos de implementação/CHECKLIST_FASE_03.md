# 🔑 Fase 03 — Autenticação em Nuvem (`fase_03_hairdule_infra_auth`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_03_hairdule_infra_auth`
> **Tecnologia:** SST v4, TypeScript + AWS Cognito + Secrets Manager
> **Região AWS:** `us-east-1`
> **Dependências Diretas:** Fase 02 (consume `kmsSecretsKeyArn`)
> **Última verificação:** 2026-08-11

---

## 🎯 Objetivo da Fase

A Fase 03 provisiona o **sistema de identidade e autenticação** do Hairdule. É o "departamento de RH e controle de acesso" da plataforma — o lugar onde usuários são cadastrados, senhas são verificadas e tokens JWT são emitidos.

Ela é responsável por **exatamente dois recursos de autenticação:** o Cognito User Pool (identidades) e o JWT Secret (chave de assinatura dos tokens). Nada mais.

> ⚠️ **Separação de responsabilidades:** As credenciais do banco (usuário/senha do Aurora) são criadas pela **Fase 04**, que é quem provisiona o Aurora e conhece sua própria senha. A Fase 03 não tem por que saber nem criar segredos de banco.

---

## 🏢 Analogia — O Departamento de RH e Controle de Acesso

```
┌─────────────────────────────────────────────────────────────┐
│               🏢 SEDE DO HAIRDULE                            │
│                                                              │
│  ┌──────────────────────────────────────────┐               │
│  │  🧑‍💼 COGNITO USER POOL                    │               │
│  │  "O Arquivo de Funcionários"              │               │
│  │                                          │               │
│  │  • Cadastro de novos usuários            │               │
│  │  • Verificação de email                  │               │
│  │  • Reset de senha                        │               │
│  │  • Histórico de logins                   │               │
│  └──────────────────────────────────────────┘               │
│                                                              │
│  ┌──────────────────────────────────────────┐               │
│  │  🎫 APP CLIENT (hairdule-dashboard)       │               │
│  │  "O Crachá do Dashboard"                  │               │
│  │  ALLOW_USER_SRP_AUTH + REFRESH_TOKEN     │               │
│  └──────────────────────────────────────────┘               │
│                                                              │
│  ┌──────────────────────────────────────────┐               │
│  │  🔒 SECRETS MANAGER                       │               │
│  │  "O Cofre da Chave de Autenticação"      │               │
│  │  • JWT Secret (chave de assinatura) ✅   │               │
│  │                                          │               │
│  │  ← DB credentials: responsabilidade      │               │
│  │    da Fase 04 (o banco cria a própria)   │               │
│  │  ← Stripe keys: responsabilidade         │               │
│  │    da Fase 22 (subscriptions)            │               │
│  │  ← VAPID keys: responsabilidade          │               │
│  │    da Fase 24 (notifications)            │               │
│  └──────────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

| Recurso | Analogia | Função Real |
|---|---|---|
| **Cognito User Pool** | **O Arquivo Central de Funcionários** | Armazena identidades de usuários, gerencia senhas e tokens |
| **App Client** | **O Crachá de Acesso por Sistema** | Define quais fluxos de autenticação cada aplicação pode usar |
| **JWT Secret** | **O Sinete da Casa** | Chave usada para assinar e verificar os tokens JWT gerados pelo auth-service |

---

## ✅ Checklist Completo da Fase 03

### 🔗 1. Pré-requisitos

- [x] Fase 01 deployada (staging) — VPC e Subnets operacionais
- [x] Fase 02 deployada (staging) — `kmsSecretsKeyArn` (`arn:aws:kms:us-east-1:351083991126:key/b176fb77...`) disponível
- [x] `kmsSecretsKeyArn` copiado para `config/environments.ts` desta fase (staging)
- [ ] `kmsSecretsKeyArn` de produção disponível (após Fase 02 produção)
- [x] **Política IAM `HairdulePolicyAuthCognito` criada na AWS** com permissões para `cognito-idp:*` e `secretsmanager:*`

---

### 📁 2. Estrutura do Repositório e Código

- [x] **`config/environments.ts`** com:
  - `kms.secretsKeyArn` por ambiente (staging e production) — estrutura 100% agnóstica a fases
  - `googleAuth` opcional com `clientSecretSecretName` (mitigação contra texto puro no Git)
  - Configurações Cognito por ambiente (passwordMinLength, deletionProtection)
  - `destroy: false` como padrão
- [x] **`sst.config.ts`** com:
  - `aws:cognito:UserPool` — `HairduleUserPool`
  - Política de senha: mínimo 8 caracteres, letras + números
  - `accountRecovery: "EMAIL_ONLY"`
  - `autoVerifiedAttributes: ["email"]`
  - `aws:cognito:UserPoolClient` — `HairduledashboardClient` (SRP + REFRESH_TOKEN, sem Hosted UI)
  - `aws:cognito:IdentityProvider` — Estrutura pronta (comentada) para Google OAuth 2.0
  - `aws:secretsmanager:Secret` — `hairdule/jwt-secret-{stage}` (criptografado com KMS da Fase 02)
  - Contrato de Outputs documentado
  - > ⚠️ **NÃO criar** `hairdule/db-credentials` aqui — responsabilidade da Fase 04
- [x] **`package.json`** com `sst@^4.0.0`
- [x] **`tsconfig.json`** com `strict: true`
- [x] **`.gitignore`** completo
- [x] Validação TypeScript com 0 erros

---

### ⚙️ 3. Workflows de CI/CD (4 workflows)

- [ ] `feature-validation.yml` — SHA pinado + concurrency + TypeScript + PR automático
- [ ] `deploy-staging.yml` — SHA pinado + deploy/remove + tag + PR para `producao`
- [ ] `deploy-production.yml` — SHA pinado + `environment: production` + Reviewer obrigatório
- [ ] `hotfix-pipeline.yml` — SHA pinado + cache SST + zero credenciais AWS

---

### 🔐 4. Recursos AWS — Cognito User Pool

- [ ] **User Pool `HairduleUserPool` criado** em staging
  - Alias: `email` (login por email, não por username)
  - Auto-verify: `email`
  - Account recovery: `EMAIL_ONLY`
  - Política de senha configurada (8+ chars, letras + números)
- [ ] **App Client `hairdule-dashboard-client` criado**
  - Flows habilitados: `ALLOW_USER_SRP_AUTH`, `ALLOW_REFRESH_TOKEN_AUTH`
  - `generateSecret: false` (apps Angular não podem guardar client secret)
- [ ] **User Pool ID** visível no console AWS → Cognito → User Pools

---

### 🔒 5. Recursos AWS — Secrets Manager

- [ ] **Secret `hairdule/jwt-secret-{stage}`** criado:
  - Criptografado com `kmsSecretsKeyArn` da Fase 02
  - Valor inicial: string aleatória de 64 chars (gerada no provisionamento)
  - Rotação automática: opcional em staging, recomendada em produção
- [ ] Secret visível em AWS Console → Secrets Manager
- [ ] Alias KMS correto (`alias/hairdule-secrets-{stage}`) visível no secret

> 🔒 **Escopo desta fase:** Apenas `hairdule/jwt-secret`. As credenciais do Aurora (`hairdule/db-credentials`) são criadas e gerenciadas pela **Fase 04** — o banco é o único responsável pelos seus próprios segredos de acesso.

---

### 📤 6. Outputs do Contrato de Integração

| Output | Tipo | Consumido por |
|---|---|---|
| `userPoolId` | `string` | Fase 09 (auth-service — verifica tokens Cognito) |
| `userPoolClientId` | `string` | Fase 09 (auth-service — signup/login via SDK) |
| `jwtSecretArn` | `string` | Fase 09 (auth-service — lê segredo para assinar JWT próprio) |
| `appName` | `string` | Todas as fases |
| `stage` | `string` | Todas as fases |

> ℹ️ **`dbCredentialsArn` NÃO é output desta fase.** As credenciais do banco são exportadas pela **Fase 04** — que as cria no momento em que provisiona o Aurora.

---

### ✔️ 7. Verificação Pós-Deploy

- [ ] User Pool visível em AWS Console → Cognito → User Pools
- [ ] App Client `hairdule-dashboard-client` visível na aba "App integration"
- [ ] **Apenas 1 secret** visível em Secrets Manager: `hairdule/jwt-secret-staging`
- [ ] Secret criptografado com alias KMS correto (`alias/hairdule-secrets-staging`)
- [ ] `npx sst output --stage staging` exibindo **5 outputs** (sem `dbCredentialsArn`)

---

### ⏳ 8. Pendências
- [x] Criar repositório `fase_03_hairdule_infra_auth` e arquivos base
- [x] Implementar `sst.config.ts` completo
- [x] Configurar 4 workflows de CI/CD GitFlow
- [ ] Executar deploy em staging via GitFlow (aguarda deploy da Fase 02)
- [ ] Verificar recursos no console AWS
- [ ] Preencher outputs em `config/environments.ts` das fases dependentes (09)
- [ ] Executar deploy em produção

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Pré-requisitos | 0 | 4 | **0%** ⬜ |
| Código e Estrutura | 6 | 6 | **100%** ✅ |
| Workflows CI/CD | 4 | 4 | **100%** ✅ |
| Recursos Cognito | 0 | 3 | **0%** ⬜ |
| Recursos Secrets Manager (apenas JWT) | 0 | 3 | **0%** ⬜ |
| Outputs e Verificação | 0 | 5 | **0%** ⬜ |
| **TOTAL** | **10** | **25** | **40%** 🔶 |

> **Status:** 🔶 Código pronto e compilado! Aguardando deploy da Fase 02 em staging para liberar `kmsSecretsKeyArn`.

