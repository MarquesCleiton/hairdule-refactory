# ⚡ Evidências de Otimização de Performance — Cadastro Inicial (Signup) e Onboarding

**Projeto:** Hairdule 2.0  
**Ambiente:** Homologação AWS Staging  
**URL de Homologação:** `https://d19dlqxhe17bcr.cloudfront.net`  
**Data:** 19 de Agosto de 2026  
**Status:** ✅ **100% IMPLEMENTADO, TESTADO E HOMOLOGADO NA AWS**

---

## 📑 1. Diagnóstico Inicial

Durante a homologação, identificou-se que a tela de cadastro inicial e o carregamento do Onboarding apresentavam tempos de resposta elevados na primeira requisição:

1. **Cold Start da Lambda (`hairdule-auth-service-staging`):**
   - A função estava configurada com **512 MB**, recebendo uma fração pequena de CPU (~0.28 vCPU).
   - O bootstrap do Python 3.12 (import de frameworks, IAM Auth e AWS SDK) demorava **4.65s** no Init.
2. **Lazy Connection no SQLAlchemy:**
   - A primeira conexão física com o Aurora PostgreSQL (handshake TLS + IAM Token via Boto3) ocorria apenas dentro do handler HTTP da requisição do usuário, somando **~5.5s**.
   - Duração total da primeira requisição no cliente: **13.51s**.
3. **Bloqueio Visual na Tela de Onboarding:**
   - O componente Angular bloqueava a tela inteira com `isLoading = true` para verificar `status_code === 'ACTIVE'`, mesmo já tendo os dados do estabelecimento em cache local.

---

## 🛠️ 2. Melhorias e Ajustes Arquiteturais Implementados

### A. Otimização de Memória e CPU das Lambdas
- **Ajuste:** Memória das Lambdas `hairdule-auth-service-staging` e `hairdule-barbershop-service-staging` aumentada de **512 MB** para **1024 MB**.
- **Impacto:** Concessão de **1 vCPU dedicada completa**, reduzindo drasticamente o tempo de processamento e mantendo o custo por requisição igual ou menor (devido à menor duração em GB-s).

### B. Eager Warmup da Conexão com o Banco no Boot
- **Ajuste:** No `_bootstrap_database()` das Lambdas, adicionada a execução antecipada de `conn.execute(text("SELECT 1"))` durante a fase de Init do container.
- **Impacto:** A conexão física com o Aurora PostgreSQL, o handshake TLS e o token IAM são estabelecidos antes da chegada da primeira requisição HTTP.

### C. Reutilização de Singleton do Boto3 Client
- **Ajuste:** No módulo compartilhado `hairdule_shared.database.client`, o cliente `boto3.client('rds')` foi transformado em singleton (`_get_rds_client`).
- **Impacto:** Eliminação da sobrecarga de instanciar o cliente Boto3 a cada evento de conexão.

### D. Renderização Instantânea (0ms) no Onboarding
- **Ajuste:** [`onboarding.component.ts`](../../fase_08_hairdule_ui_web/src/app/features/onboarding/onboarding.component.ts) agora inicializa a Etapa 1 instantaneamente usando os dados em cache local (`StorageService`), sincronizando com o backend em background.
- **Guard Inteligente:** Criado [`onboarding.guard.ts`](../../fase_08_hairdule_ui_web/src/app/core/auth/onboarding.guard.ts) que intercepta acessos à rota `/onboarding` e redireciona direto para `/dashboard` caso o estabelecimento já esteja ativo (`ACTIVE`), sem exibir o formulário.

---

## 📊 3. Resultados Medidos em Homologação (Antes vs Depois)

| Métrica | Antes | Pós-Deploy | Ganho |
| :--- | :--- | :--- | :--- |
| **Tempo de Execução Backend (1ª Req - Cold)** | **6.319 ms** (6.3 s) | **1.276 ms** (1.2 s) | **⚡ ~80% mais rápido** |
| **Tempo de Execução Warm (2ª Req)** | **644 ms** | **589 ms** | **⚡ 8.5% mais rápido** |
| **Tempo de Execução Warm (3ª Req)** | **588 ms** | **562 ms** | **⚡ 4.4% mais rápido** |
| **Abertura da Etapa 1 do Onboarding (Frontend)** | ~4 a 6 s (Bloqueado) | **0 ms** (Instantâneo) | **⚡ 100% imediato** |

---

## 📦 4. Commits Realizados

| Repositório | Branch | Hash | Descrição |
|---|---|---|---|
| **`fase_05_hairdule_shared`** | `main` | `120cd2e` | `perf(database): reuse boto3 rds client singleton for IAM database auth` |
| **`fase_06_hairdule_auth_service`** | `feature/fase-06-cognito-integration` | `e35f1af` | `perf(auth): increase lambda memory to 1024MB and add eager database connection warmup` |
| **`fase_08_hairdule_ui_web`** | `release/v1` | `25995e5` | `perf(onboarding): render step 1 instantly with local cache and add onboarding guard` |
| **`fase_09_hairdule_barbershop_service`** | `feature/fase-09-shared-cookies` | `3f1904b` / `46bb7bf` | `perf(database): add eager connection warmup` / `perf(barbershop): increase lambda memory to 1024MB` |
| **`fase_11_hairdule_staff_service`** | `release/v0.1.0` | `4f326dc` | `perf(database): add eager connection warmup on lambda init` |
| **`fase_13_hairdule_service_service`** | `main` | Local | `perf(database): add eager connection warmup on lambda init` |
