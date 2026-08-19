# 🔐 Fase 06 — Auth Service Lambda (`fase_06_hairdule_auth_service`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_06_hairdule_auth_service`  
> **Tecnologia:** Python 3.12 + FastAPI + Mangum (Lambda) + SST v4 + `uv`  
> **Porta Local:** `3001`  
> **Dependências Diretas:** Fase 01 (VPC), Fase 02 (Security Groups & KMS), Fase 03 (Cognito & JWT Secret), Fase 04 (Aurora DB), Fase 05 (`hairdule_shared`)  
> **Última atualização:** 2026-08-17 (Release `v0.2.1` — 512 MB + IAM Database Auth)  

---

## 🎯 Objetivo da Fase

A Fase 06 implementa o **microsserviço de autenticação** — a primeira Lambda Python de negócio do Hairdule 2.0. É a porteira do sistema: ninguém entra sem passar por aqui primeiro.

Esta fase fornece os endpoints de login, cadastro com transação atômica DB (`barbershop`, `user_role`, `staff`), refresh token e recuperação de senha.

---

## 🔑 CI/CD, Autenticação de Código Compartilhado (`GH_PAT`) & Suíte de Testes

### 1. Checkout de Dependência Compartilhada Privada (`GH_PAT`)
- Todos os repositórios backend de microsserviços consomem a biblioteca privada [`hairdule_shared`](https://github.com/MarquesCleitonOrg/fase_05_hairdule_shared).
- No **GitHub Actions**, o checkout do pacote compartilhado utiliza o secret **`GH_PAT`** (Personal Access Token clássico):
  ```bash
  git clone https://x-access-token:${{ secrets.GH_PAT }}@github.com/MarquesCleitonOrg/fase_05_hairdule_shared.git ../fase_05_hairdule_shared
  pip install -e ../fase_05_hairdule_shared
  ```
- O SST v4 realiza o empacotamento da Lambda Python antes do deploy.
- Na AWS, a função Lambda anexa a **Lambda Layer ARN** vinculada via SSM Parameter Store (`/sst/hairdule/staging/shared/layer-arn`).

### 2. Autenticação Nativa AWS IAM Database Authentication (Zero Senhas Estáticas)
- A Lambda se conecta ao Aurora PostgreSQL utilizando tokens temporários pré-assinados via SigV4 (`rds-db:connect`) gerados pelo `boto3.generate_db_auth_token`.
- O SQLAlchemy registra um hook dinâmico `do_connect` que injeta o token a cada nova conexão física do pool com `sslmode=require`.
- Permissões IAM concedidas via role `hairdule-auth-service-role-staging`.

### 3. Suíte de Testes Automatizados e Manuais
- A partir da Fase 06, **todos os microsserviços backend possuem relatórios e testes dedicados**:
- **`docs/TEST_REPORT.md`**: Relatório da bateria de 11 cenários de testes executados diretamente na AWS Lambda em staging (100% de aprovação).
- **`docs/testes_manuais/TESTES_SUCESSO.md`**: Massas de dados JSON no padrão API Gateway v2 HTTP Payload cobrindo 100% dos cenários felizes (200 OK / 201 Created).
- **`docs/testes_manuais/TESTES_ERROS.md`**: Massas de dados JSON cobrindo validações de erro, exceções de negócio e códigos HTTP (400, 401, 409, 422).

---

## ✅ Checklist Completo da Fase 06

### 🔗 1. Pré-requisitos

- [x] Fase 01 deployada (VPC ID `vpc-010df10405f0570fc`, Subnets Privadas `subnet-06a9b8a3c40626395`, `subnet-086518ec7b1e8e754`)
- [x] Fase 02 deployada (Security Group `sg-0a129a6becf446af9`, KMS Secrets Key)
- [x] Fase 03 deployada (`userPoolId`, `userPoolClientId`, `jwtSecretArn` disponíveis)
- [x] Fase 04 deployada + schema aplicado (tabelas `barbershops`, `user_roles`, `staff` existem no PostgreSQL)
- [x] Fase 04.1 executada com concessão `GRANT rds_iam TO hairdule_app;`
- [x] Fase 05 concluída (`hairdule-shared` com suporte a IAM Database Authentication e pool otimizado)
- [x] `.env.local` configurado com `DATABASE_URL`, `ENVIRONMENT=development`

---

### 📁 2. Estrutura do Repositório

- [x] **`pyproject.toml`** com deps: `fastapi`, `mangum`, `uvicorn`, `hairdule-shared`
- [x] **`src/handler.py`** — `handler = Mangum(app, lifespan="off")`
- [x] **`src/app.py`** — FastAPI app com CORS, LoggingMiddleware, AppError handler, Eager Warmup DB e Bootstrap Secrets Manager
- [x] **`src/local_server.py`** — `uvicorn.run("src.app:app", port=3001, reload=True)`
- [x] **`config/environments.ts`** — Configurações estritamente tipadas sem lookups (`network`, `security`, `kms`, `database`, `execution`)
- [x] **`sst.config.ts`** — IaC Pulumi nativo com VPC config, policy `rds-db:connect`, Secrets Manager, KMS e 512 MB RAM
- [x] **`.github/workflows/`** — 4 workflows oficiais GitFlow (feature, staging, production, hotfix) com suporte a `GH_PAT`

---

### 🐍 3. Backend — Rotas FastAPI & Emissão de Cookies HttpOnly

- [x] **`src/routes/signup.py`** — `POST /auth/signup`: Transação atômica criando `barbershop` (ONBOARDING), `user_role` (OWNER) e `staff` (OWNER) via IAM Auth + emissão de cookies `access_token` e `refresh_token` (`HttpOnly; Secure; SameSite=Lax`)
- [x] **`src/routes/login.py`** — `POST /auth/login`: Autentica credenciais, gera JWT com claims tipadas e emite cookies `HttpOnly`
- [x] **`src/routes/forgot_password.py`** — `POST /auth/forgot-password`: Solicitação de código de recuperação por e-mail
- [x] **`src/routes/reset_password.py`** — `POST /auth/reset-password`: Confirmação de redefinição de senha com código
- [x] **`src/routes/change_password.py`** — `POST /auth/change-password`: Troca de senha autenticada via Cookie `HttpOnly` ou Bearer Token
- [x] **`src/routes/refresh.py`** — `POST /auth/refresh`: Renovação de access token lendo cookie `refresh_token` de 30 dias e emitindo novo cookie
- [x] **`src/routes/logout.py`** — `POST /auth/logout`: Revogação e limpeza dos cookies `access_token` e `refresh_token` (`Max-Age=0`)
- [x] **`src/routes/me.py`** — `GET /auth/me`: Retorna dados do usuário autenticado e barbearia para hidratação de sessão no frontend

---

### 🔑 4. Auth Adapter Pattern

- [x] **`LocalAuthProvider`** ativo em `ENVIRONMENT=development`: bcrypt hash + PyJWT
- [x] **`CognitoAuthProvider`** ativo em `ENVIRONMENT=production`: AWS Cognito via boto3
- [x] Troca transparente de provider via `ENVIRONMENT` env var

---

### 🧪 5. Testes Unitários e Bateria em Staging

- [x] Testes unitários locais passando
- [x] Pasta de testes manuais criada em [`docs/testes_manuais/`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_06_hairdule_auth_service/docs/testes_manuais/README.md)
- [x] Relatório consolidado em [`docs/TEST_REPORT.md`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_06_hairdule_auth_service/docs/TEST_REPORT.md) com 11/11 cenários aprovados
- [x] Latência de login otimizada para ~1.0s (Bcrypt) e rotas em memória entre 0.6ms e 20ms

---

### 🚀 6. Deploy e Integração AWS

- [x] Servidor local executando na porta 3001 (`http://localhost:3001/docs`)
- [x] Lambda deployada na AWS via SST v4 (`hairdule-auth-service-staging`) com 512 MB de RAM
- [x] Conexão com o Aurora PostgreSQL Serverless v2 validada via IAM Auth
- [x] Pipeline GitFlow 100% verde no GitHub Actions com deploy automatizado em Staging

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Pré-requisitos | 7 | 7 | **100%** 🟩 |
| Estrutura do Repositório | 7 | 7 | **100%** 🟩 |
| Rotas FastAPI (6 rotas) | 6 | 6 | **100%** 🟩 |
| Auth Adapter Pattern | 3 | 3 | **100%** 🟩 |
| Testes Unitários & AWS Staging | 4 | 4 | **100%** 🟩 |
| Deploy e Integração AWS | 4 | 4 | **100%** 🟩 |
| **TOTAL** | **31** | **31** | **100%** 🟩 |

> **Status:** ✅ **Fase 06 Concluída, Otimizada e Homologada em Staging na AWS com Sucesso!**
