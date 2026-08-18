# 🔒 Fase 02 — Camada de Segurança (`fase_02_hairdule_infra_security`)
## Checklist de Execução — Status Completo

> **Repositório:** `https://github.com/MarquesCleiton/fase_02_hairdule_infra_security`
> **Branch Atual:** `release/v2` ✅ (Checkout realizado)
> **Tecnologia:** SST v4, TypeScript + Pulumi (AWS Provider)
> **Região AWS:** `us-east-1` (N. Virginia)
> **Node.js Requerido:** `>= 22`
> **Dependência Direta:** ✅ Fase 01 (`fase_01_hairdule_infra_network`) — staging operacional
> **Última verificação:** 2026-08-11

---

## 🎯 Objetivo da Fase

Se a **Fase 01 construiu o condomínio** (a VPC, as ruas, o terreno), a **Fase 02 instala o sistema de segurança** desse condomínio.

Ela não serve a nenhuma funcionalidade de negócio diretamente, mas é **pré-requisito obrigatório** para tudo que vem depois:

- **Fase 03 (Cognito):** consome `kmsSecretsKeyArn` para criptografar credenciais
- **Fase 04 (Aurora):** consome `sgAuroraId`, `dbSubnetGroupName` e `kmsAuroraKeyArn` para provisionar o banco
- **Fase 09+ (Lambdas):** consomem `sgLambdaId` para colocar cada Lambda dentro da VPC com segurança

---

## 🔐 Analogia Completa — O Sistema de Segurança do Condomínio

```
A Fase 01 construiu o condomínio (VPC, subnets, NAT Gateway).
A Fase 02 instala o sistema de segurança:

┌─────────────────────────────────────────────────────────────┐
│  SUBNET PRIVADA (Alameda Reservada — herdada da Fase 01)    │
│                                                              │
│  ┌──────────────────────────┐                               │
│  │  🛡️  sg-lambda-services  │  ← Crachá dos Funcionários   │
│  │  ─────────────────────── │    Saem livremente (via NAT)  │
│  │  Egress: 0.0.0.0/0 ✅   │    Ninguém entra de fora ❌   │
│  │  Ingress: nenhum ❌      │                               │
│  └──────────┬───────────────┘                               │
│             │ TCP 5432 (única regra autorizada)              │
│             ▼                                                │
│  ┌──────────────────────────┐                               │
│  │  🔐  sg-aurora-db        │  ← Cofre-Forte do Banco       │
│  │  ─────────────────────── │    Só abre para os Lambdas    │
│  │  Ingress: sg-lambda ✅   │    Nunca abre para internet ❌ │
│  │  Egress: nenhum ❌       │                               │
│  └──────────────────────────┘                               │
│                                                              │
│  🗄️  hairdule-db-subnet-group ← Endereço registrado do banco │
└─────────────────────────────────────────────────────────────┘

🔑 hairdule-kms-aurora   → Cofre dos Dados (criptografia em disco do Aurora)
🔑 hairdule-kms-secrets  → Cofre dos Segredos (credenciais no Secrets Manager)
```

| Recurso AWS | Analogia | Por que existe |
|---|---|---|
| **`sg-lambda-services`** | **Crachá dos Funcionários** — saem livremente, ninguém entra | Lambdas precisam chamar Stripe, Cognito, SendGrid via NAT, mas não devem receber conexões diretas da internet |
| **`sg-aurora-db`** | **Cofre-Forte do Banco** — só abre com a chave certa | Aurora deve aceitar conexões apenas das Lambdas. Nem mesmo um EC2 comprometido dentro da VPC consegue conectar |
| **`SecurityGroupRule` TCP 5432** | **A Chave Mestra** que conecta o crachá ao cofre | Regra de ingress cruzada por SG ID (não por CIDR) — granularidade por identidade, não por faixa de IP |
| **`hairdule-db-subnet-group`** | **Endereço Oficial de Entrega** registrado nos Correios | O Aurora só pode ser "instalado" em endereços (subnets) que estejam neste grupo |
| **`kmsAurora`** | **Sistema de Criptografia do Cofre-Forte** | Todos os dados gravados no disco do Aurora são criptografados. Se alguém roubar o HD, não lê nada sem a chave |
| **`kmsSecrets`** | **Cofre de Chaves-Mestre** | Senhas de banco, chaves de API, tokens de integração — tudo no Secrets Manager é criptografado com esta chave |

---

## 📦 Os 8 Recursos AWS Provisionados

| # | Recurso | Nome no AWS | Deploy Staging | Deploy Produção |
|---|---|---|---|---|
| 1 | Security Group Lambdas | `hairdule-lambda-services-staging` (`sg-0a129a6becf446af9`) | ✅ | ⬜ |
| 2 | Security Group Aurora | `hairdule-aurora-db-staging` (`sg-0bad8c38c1c045209`) | ✅ | ⬜ |
| 3 | Regra de Ingress Cruzada | SG Rule TCP 5432 (sgLambda → sgAurora) | ✅ | ⬜ |
| 4 | DB Subnet Group | `hairdule-db-subnet-group-staging` | ✅ | ⬜ |
| 5 | KMS Key — Aurora | `hairdule-kms-aurora-staging` (`arn:aws:kms:us-east-1:351083991126:key/ccf8bbb4...`) | ✅ | ⬜ |
| 6 | KMS Alias — Aurora | `alias/hairdule-aurora-staging` | ✅ | ⬜ |
| 7 | KMS Key — Secrets | `hairdule-kms-secrets-staging` (`arn:aws:kms:us-east-1:351083991126:key/b176fb77...`) | ✅ | ⬜ |
| 8 | KMS Alias — Secrets | `alias/hairdule-secrets-staging` | ✅ | ⬜ |

---

## ✅ Checklist Completo da Fase 02

### 🔗 1. Pré-requisitos (Fase 01)

> Analogia: Antes de instalar o sistema de alarme, o condomínio precisa estar construído. Não dá pra instalar câmera em paredes que não existem.

- [x] **Fase 01 deployada em staging com sucesso**
  - *Status:* ✅ **Concluído** → Retorna `vpcId` (`vpc-010df10405f0570fc`) e `privateSubnets` (`subnet-06a9b8a3c40626395`, `subnet-086518ec7b1e8e754`)
- [ ] **Fase 01 deployada em produção com sucesso**
- [x] **`vpcId` de staging preenchido em `config/environments.ts`**
  - *Status atual:* ✅ **Pronto** → `"vpc-010df10405f0570fc"`
- [x] **`privateSubnets` de staging preenchidos em `config/environments.ts`**
  - *Status atual:* ✅ **Pronto** → `["subnet-06a9b8a3c40626395", "subnet-086518ec7b1e8e754"]`
- [ ] **`vpcId` de produção preenchido em `config/environments.ts`**
  - *Status atual:* ⚠️ **Pendente** — contém `"PREENCHER_APOS_DEPLOY_FASE01"`
- [ ] **`privateSubnets` de produção preenchidos em `config/environments.ts`**
  - *Status atual:* ⚠️ **Pendente** — contém `["PREENCHER_APOS_DEPLOY_FASE01"]`

---

### 🔐 2. Autenticação e Credenciais AWS

> Analogia: A empresa de segurança precisa de autorização formal para entrar no condomínio e instalar os sistemas — mas com crachá limitado, não com a chave de todos os apartamentos.

- [ ] **Política `HairduleGitHubActionsPolicy` atualizada** com permissões adicionais para EC2, RDS e KMS
  - *Por que importa:* A Fase 01 criou a política com permissões de VPC. A Fase 02 precisa de permissões extras para criar Security Groups (`ec2:CreateSecurityGroup`, `ec2:AuthorizeSecurityGroupIngress`), DB Subnet Groups (`rds:CreateDBSubnetGroup`) e KMS Keys (`kms:CreateKey`, `kms:CreateAlias`).
- [ ] **Secret `AWS_ACCESS_KEY_ID_STAGING` disponível no GitHub** (herdado da Fase 01 — verificar se ainda é válido)
- [ ] **Secret `AWS_SECRET_ACCESS_KEY_STAGING` disponível no GitHub** (herdado da Fase 01)
- [ ] **Secret `AWS_ACCESS_KEY_ID_PROD` disponível no GitHub** (herdado da Fase 01)
- [ ] **Secret `AWS_SECRET_ACCESS_KEY_PROD` disponível no GitHub** (herdado da Fase 01)

---

### 📁 3. Estrutura do Repositório e Código

> Analogia: O manual técnico de instalação do sistema de segurança. Cada componente, cada fio, cada câmera deve estar documentado antes da instalação começar.

- [ ] **`config/environments.ts` completo e preenchido** com:
  - `commonConfig` — `appName: "hairdule-infra-security"`, `region: "us-east-1"`
  - ⚠️ **Atenção:** Na branch `release/v2`, `destroy` em `commonConfig` está setado como `true` (devido a teste de teardown na branch `feature/destry`). Para o deploy normal de homologação, deve ser alterado para `destroy: false`.
  - Staging: `vpcId` e 2 `privateSubnets` com valores reais da Fase 01 ✅
  - Staging: `kmsKeyDeletionWindowDays: 7`, `enableKmsRotation: false`
  - Production: `vpcId` e `privateSubnets` ⚠️ (pendentes após deploy da Fase 01 em produção)
  - Production: `kmsKeyDeletionWindowDays: 30`, `enableKmsRotation: true`
  - Interfaces TypeScript exportadas: `CommonConfig`, `EnvironmentSpecificConfig`, `FullConfig`
  - Função `getFullConfig(stage): FullConfig`
- [ ] **`sst.config.ts` implementado** com todos os 8 recursos:
  - Trava declarativa de destruição (`if (config.destroy) return { destroyMode: true, ... }`)
  - `SgLambdaServices` — egress irrestrito, zero ingress
  - `SgAuroraDb` — zero egress, zero ingress inicial
  - `SgRuleLambdaToAurora` — regra cruzada TCP 5432 por SG ID (não CIDR)
  - `HairduleDbSubnetGroup` — subnets privadas da Fase 01
  - `KmsKeyAurora` — CMK com `deletionWindowInDays` e `enableKeyRotation` por ambiente
  - `KmsAliasAurora` — `alias/hairdule-aurora-{stage}`
  - `KmsKeySecrets` — CMK separada da Aurora (princípio de menor privilégio)
  - `KmsAliasSecrets` — `alias/hairdule-secrets-{stage}`
  - **Contrato de Outputs documentado** em tabela no código (8 outputs)
- [ ] **`package.json` configurado** com `sst@^4.0.0`, `typescript@^5.5`, `tsx@^4.19`
- [ ] **`tsconfig.json` configurado** com `strict: true` e target `ESNext`
- [ ] **`.gitignore` completo** — `node_modules/`, `.sst/`, `.env`, `.DS_Store`, `*.pem`
- [ ] **Validação TypeScript passando** — `npx tsc --noEmit` com 0 erros

---

### ⚙️ 4. Workflows de CI/CD (GitHub Actions)

> Analogia: O protocolo de instalação. Primeiro testa no apartamento modelo (staging), depois instala nos apartamentos reais (produção), com aprovação do síndico em cada etapa.

#### `feature-validation.yml` — CI de Features
- [ ] **Trigger:** `push: feature/**` + `workflow_dispatch`
- [ ] **Concurrency:** `cancel-in-progress: true`
- [ ] **SHA pinado:** `checkout@...`, `setup-node@...`, `configure-aws-credentials@...` com hashes de 40 chars
- [ ] **Etapas:** Valida TypeScript → calcula versão `vN` → cria `release-vN` → abre PR
- [ ] **Notificação de status:** Step `if: always()`

#### `deploy-staging.yml` — CD de Homologação
- [ ] **Trigger:** `push: release-v*`
- [ ] **Concurrency:** `cancel-in-progress: false`
- [ ] **Trava de segurança:** Verifica `destroy: false` antes de qualquer ação
- [ ] **Etapas:** Deploy/Remove staging → cria Tag `vN` → abre PR para `producao`
- [ ] **Notificação de status:** Step `if: always()`

#### `deploy-production.yml` — CD de Produção
- [ ] **Trigger:** `push: producao`
- [ ] **Concurrency:** `cancel-in-progress: false`
- [ ] **Proteção extra:** `environment: production` (Reviewer obrigatório no GitHub)
- [ ] **Etapas:** Trava segurança → Deploy/Remove produção → abre PR de sync para `main`
- [ ] **Notificação de status:** Step `if: always()`

#### `hotfix-pipeline.yml` — CI de Emergência
- [ ] **Trigger:** `push: hotfix/**`
- [ ] **Concurrency:** `cancel-in-progress: true`
- [ ] **Diferencial:** Zero credenciais AWS — usa cache `.sst/platform` para validação de tipos
- [ ] **Etapas:** Restaura cache SST → valida TypeScript → PR direto para `producao`
- [ ] **Notificação de status:** Step `if: always()`

---

### 🛡️ 5. Segurança — Decisões Arquiteturais Críticas

> Analogia: O projeto de segurança revisado por especialistas. Cada decisão aqui tem uma justificativa técnica que não pode ser simplificada.

- [ ] **Source Security Group ID (não CIDR)** na regra de ingress do `sg-aurora-db`
  - *O que é:* A regra `SgRuleLambdaToAurora` referencia o `sgLambda.id` como `sourceSecurityGroupId`, não um bloco de IP como `10.0.0.0/8`
  - *Por que importa:* Com CIDR, qualquer EC2 comprometido dentro da VPC poderia conectar ao Aurora. Com Source SG ID, apenas ENIs com `sg-lambda-services` associado podem conectar — granularidade por **identidade**, não por **localização**
- [ ] **2 KMS CMKs separadas** (Aurora + Secrets) — princípio de menor privilégio
  - *O que é:* `KmsKeyAurora` para dados em repouso do Aurora; `KmsKeySecrets` para credenciais no Secrets Manager
  - *Por que importa:* Comprometimento da chave Aurora afeta apenas dados do banco. Comprometimento da chave Secrets afeta apenas credenciais. Políticas IAM separadas por chave → acesso granular
- [ ] **GitHub Actions com SHA pinado** — proteção de supply chain
  - *Hashes utilizados:* `checkout@11bd719...`, `setup-node@49933ea...`, `configure-aws-credentials@ececac6...`
- [ ] **`environment: production`** no GitHub com Reviewer obrigatório
- [ ] **`destroy: false`** como padrão hardcoded em `config/environments.ts`
  - *Por que importa:* Impede teardown acidental. Para destruir, é necessário editar o arquivo explicitamente via feature branch → pipeline

---

### ✔️ 6. Verificação Pós-Deploy

> Analogia: O laudo de vistoria do sistema de segurança. Cada câmera, cada sensor, cada fechadura precisa ser testada individualmente antes de assinar o contrato.

- [ ] **`sg-lambda-services-staging`** visível em AWS Console → EC2 → Security Groups
  - *O que verificar:* Egress com `0.0.0.0/0`, **zero regras de ingress**
- [ ] **`sg-aurora-db-staging`** visível em AWS Console → EC2 → Security Groups
  - *O que verificar:* Regra de ingress TCP 5432 com source = `sg-lambda-services-staging`. **Zero regras de egress**
- [ ] **Regra TCP 5432 configurada** com source SG ID (não CIDR) em `sg-aurora-db`
- [ ] **`hairdule-db-subnet-group-staging`** visível em AWS Console → RDS → Subnet Groups
  - *O que verificar:* Contém as subnets privadas da Fase 01
- [ ] **2 KMS CMKs visíveis** em AWS Console → KMS → Customer managed keys
- [ ] **Alias `alias/hairdule-aurora-staging`** criado e apontando para a KMS Aurora
- [ ] **Alias `alias/hairdule-secrets-staging`** criado e apontando para a KMS Secrets
- [ ] **`npx sst output --stage staging`** exibindo todos os 8 outputs corretamente sem erros

---

### 📤 7. Outputs do Contrato de Integração

> Analogia: Os certificados de segurança emitidos após a instalação — entregues às fases seguintes como prova de que o sistema está ativo e pronto para uso.

| Output | Tipo | Quem consume | O que é |
|---|---|---|---|
| `sgLambdaId` | `string` | Fase 04 (Aurora), Fase 09+ (Lambdas) | ID do Security Group das Lambdas — necessário para colocar cada Lambda dentro da VPC |
| `sgAuroraId` | `string` | Fase 04 (Aurora Cluster) | ID do Security Group do Aurora — necessário para associar ao cluster no provisionamento |
| `dbSubnetGroupName` | `string` | Fase 04 (Aurora Cluster) | Nome do DB Subnet Group — Aurora não pode ser criado sem este grupo |
| `kmsAuroraKeyArn` | `string` | Fase 04 (Aurora Cluster) | ARN da KMS Key — Aurora usa para criptografar dados em repouso |
| `kmsSecretsKeyArn` | `string` | Fase 03 (Cognito), Fase 04 (credenciais RDS) | ARN da KMS Key — Secrets Manager usa para criptografar senhas e chaves de API |
| `appName` | `string` | Todas as fases | Convenção de nomenclatura de recursos |
| `stage` | `string` | Todas as fases | Identificação do ambiente (staging/production) |
| `destroyMode` | `boolean` | Todas as fases | Controle declarativo de teardown |

---

### ⏳ 8. Estado Atual e Pendências da Fase 02 (Branch `release/v2`)

> Lista consolidada de o que já está **PRONTO** e o que está **FALTANDO** na branch `release/v2`.

#### ✅ O QUE JÁ ESTÁ PRONTO (Código & Configuração):
1. **Branch checkout:** Alternado para `release/v2`
2. **Infraestrutura declarativa SST (`sst.config.ts`):** 100% dos 8 recursos implementados (SgLambdaServices, SgAuroraDb, SgRuleLambdaToAurora, HairduleDbSubnetGroup, KmsKeyAurora, KmsAliasAurora, KmsKeySecrets, KmsAliasSecrets)
3. **Outputs da Fase 01 em Staging:** `vpcId` (`vpc-0e59aad0cb6ae1c13`) e 2 `privateSubnets` (`subnet-0108f23f950da88c5`, `subnet-0088565acd5c20d9d`) preenchidos em `config/environments.ts`
4. **Workflows CI/CD GitHub Actions:** 4 pipelines configurados (`feature-validation.yml`, `deploy-staging.yml`, `deploy-production.yml`, `hotfix-pipeline.yml`) com SHA-pinning (40 chars)
5. **Tipagem e Configurações:** `package.json`, `tsconfig.json`, `.gitignore` configurados e limpos

#### ⚠️ O QUE FALTA FAZER:
1. **Ajustar flag `destroy` em `config/environments.ts`:**
   - Atualmente na branch `release/v2` o flag está `destroy: true` (resultado do merge do PR `#8`). Alterar para `destroy: false` via feature branch para autorizar o deploy normal em staging.
2. **Disparar o deploy em Staging via GitFlow:**
   - Criar `feature/enable-deploy` → `destroy: false` → commit/push → merge em `release/v2` para disparar a pipeline `deploy-staging.yml`.
3. **Validar os 8 recursos deployados no AWS Console:**
   - Verificar SGs, DB Subnet Group, KMS Keys e Aliases na conta de staging da AWS.
4. **Executar `npx sst output --stage staging`:**
   - Confirmar os 8 outputs de staging para disponibilizar para as Fases 03 e 04.
5. **Preencher outputs de Produção da Fase 01:**
   - Substituir os placeholders `"PREENCHER_APOS_DEPLOY_FASE01"` em `production` em `config/environments.ts` assim que a Fase 01 estiver em produção.
6. **Disparar deploy em Produção:**
   - Aprovar PR de promoção `release/v2` → `producao` no GitHub.
7. **Governança:**
   - Configurar Branch Protection Rules (`release-v*`, `producao`, `main`) e adicionar `.github/CODEOWNERS`.

---

## 🏗️ Estrutura de Arquivos do Repositório

```text
fase_02_hairdule_infra_security/
├── .github/
│   └── workflows/
│       ├── feature-validation.yml   ⬜ SHA pinado + concurrency + workflow_dispatch
│       ├── deploy-staging.yml       ⬜ SHA pinado + deploy/remove + tag + notificação
│       ├── deploy-production.yml    ⬜ SHA pinado + environment:production + notificação
│       └── hotfix-pipeline.yml      ⬜ SHA pinado + cache SST + sem AWS + notificação
├── config/
│   └── environments.ts              ✅ Interfaces + commonConfig + envConfigs (staging preenchido)
│                                       ⚠️ Production VPC outputs ainda com placeholder
├── sst.config.ts                    ✅ 8 recursos implementados + contrato de outputs documentado
├── package.json                     ✅ sst@^4.0.0, typescript@^5.5, tsx@^4.19
├── tsconfig.json                    ✅ strict: true, ESNext, bundler resolution
├── .gitignore                       ✅ node_modules, .sst, .env, .DS_Store, *.pem
├── README.md                        ✅ Manual de uso + comandos locais
└── fase_02_hairdule_infra_security.md ✅ Documentação técnica completa
```

---

## 💥 Teardown Declarativo — Como Destruir Esta Fase

> ⚠️ **ATENÇÃO:** KMS Keys com `removalPolicy: retain` (produção) **não são deletadas** pelo `sst remove`. Para deletar uma KMS Key de produção, é necessário fazê-lo manualmente no console AWS e aguardar os 30 dias de `deletionWindowInDays`.

**Passo 1:** Em uma branch `feature/*`, edite `config/environments.ts`:
```typescript
export const commonConfig: CommonConfig = {
  // ...
  destroy: true, // 👈 Ativa o teardown declarativo
};
```

**Passo 2:** Commit + push → A pipeline detecta `destroy: true` e executa `sst remove --stage staging` → abre PR para `producao`

**Passo 3:** Após o teardown, volte `destroy: false` antes do próximo deploy.

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Pré-requisitos (Fase 01) | 2 | 6 | **33%** ⚠️ |
| Autenticação e Credenciais | 0 | 5 | **0%** ⬜ |
| Estrutura do Repositório e Código | 3 | 6 | **50%** 🔶 |
| Workflows de CI/CD | 0 | 16 | **0%** ⬜ |
| Segurança — Decisões Arquiteturais | 0 | 5 | **0%** ⬜ |
| Verificação Pós-Deploy | 0 | 8 | **0%** ⬜ |
| Outputs do Contrato | 0 | 8 | **0%** ⬜ |
| Pendências Específicas | 0 | 8 | **0%** ⬜ |
| **TOTAL** | **5** | **62** | **~8%** |

> **Status geral:** 🔶 **Código implementado e pronto para deploy.** O `sst.config.ts` está completo com todos os 8 recursos. Os outputs de staging da Fase 01 já estão preenchidos. O bloqueador principal é **executar o deploy via pipeline GitFlow** e preencher os outputs de produção da Fase 01.

---

## 🚀 Comandos de Referência Rápida

```bash
# Pré-requisito: Node >= 22
node --version

# Instalar dependências
npm install

# Gerar tipos TypeScript do SST (obrigatório antes do tsc)
npx sst install

# Validar TypeScript (mesmo que o CI — rodar antes de commitar)
npm run build

# Deploy em staging (requer credenciais AWS locais)
npx sst deploy --stage staging

# Ver outputs após o deploy (copiar para config/environments.ts das fases seguintes)
npx sst output --stage staging
npx sst output --stage production

# Remover infraestrutura de staging
npx sst remove --stage staging
```

> ⚠️ **Regra de Ouro:** Nunca faça deploy manual em produção. Use sempre a pipeline GitFlow para garantir rastreabilidade, versionamento e aprovação humana.

---

## 🔗 Dependência Visual — Posição no Ecossistema

```
Fase 01: VPC + Subnets + NAT ✅
    └─→ Fase 02: Security Groups + KMS ← VOCÊ ESTÁ AQUI ⬜
            ├─→ Fase 03: Cognito (consume kmsSecretsKeyArn)
            └─→ Fase 04: Aurora (consume sgAuroraId, dbSubnetGroupName, kmsAuroraKeyArn)
                    └─→ Fase 05: hairdule-shared (Lambda Layer Python)
                            └─→ Fase 06: API Gateway + WAF
                                    └─→ Fases 09+: Microsserviços Lambda
```
