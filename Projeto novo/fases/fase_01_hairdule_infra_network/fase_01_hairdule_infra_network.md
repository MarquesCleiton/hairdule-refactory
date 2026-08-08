# Fase 01 — `fase_01_hairdule_infra_network`

> **Localização do Repositório:** `./fase_01_hairdule_infra_network/`  
> **Arquivo de Documentação:** `./fase_01_hairdule_infra_network/fase_01_hairdule_infra_network.md`  
> **Tipo:** Infraestrutura como Código (SST v4 em TypeScript)  
> **Região AWS:** `us-east-1` (N. Virginia — Otimização Financeira & Menor Custo)  
> **Dependências:** Nenhuma (Primeira Fase de Fundação de Rede)  
> **Estratégia de Autenticação:** AWS OIDC (OpenID Connect — 100% Sem Chaves e Sem Senhas)  
> **ARN Role Homologação:** `arn:aws:iam::351083991126:role/GitHubActionsRole`  
> **Estratégia de Branching & Deploy:** GitOps Multi-Conta com Branches Versionadas (`feature/*` ➔ `release-vX.Y.Z` ➔ `main`)

---

## 🎨 Analogia do Mundo Real: O Condomínio Fechado de Alta Segurança

Para entender o que esta fase faz na AWS, pense em construir um **Condomínio Fechado de Luxo**:

1. **A VPC (`HairduleVpc`):** É o **terreno inteiro do condomínio**. Define os limites geográficos e a infraestrutura básica onde todas as casas (banco de dados, APIs, microsserviços) serão construídas.
2. **Subnets Públicas (A Portaria e Avenida Principal):** São as áreas de acesso controlado na entrada do condomínio. Aqui fica a portaria e o serviço de correios. Qualquer pessoa na rua pode chegar até a portaria, mas não entra nas casas.
3. **Subnets Privadas (As Alamedas Internas Reservadas):** São as ruas internas totalmente fechadas atrás dos portões de segurança. É exatamente aqui que o **Banco de Dados (Aurora)** e as **Lambdas** moram. Nenhuma pessoa ou carro da rua consegue entrar aqui sem autorização prévia.
4. **Internet Gateway (IGW):** É o portão principal de saída do condomínio para a rodovia pública.
5. **NAT Gateway:** É o **serviço de entregas particular do condomínio**. Quando uma casa (Lambda em subnet privada) precisa mandar uma carta para o mundo exterior (ex: falar com o Stripe ou mandar e-mail), ela entrega a carta para o NAT Gateway. O NAT Gateway vai na rua, entrega a carta e traz a resposta de volta para a casa — **sem nunca revelar o endereço nem a localização da casa para o mundo externo**.

---

## 🛡️ Autenticação Definitiva: AWS OIDC (100% Sem Chaves Estáticas e Sem Senhas)

Optamos pelo padrão recomendado da AWS e GitHub de **Autenticação OIDC (OpenID Connect)**. 

### Como Funciona:
- Não criamos nem salvamos nenhuma `AWS_ACCESS_KEY_ID` ou `AWS_SECRET_ACCESS_KEY` no GitHub.
- A AWS confia nativamente no provedor de tokens do GitHub Actions (`token.actions.githubusercontent.com`).
- A cada execução do pipeline, o GitHub emite um token assinado de curta duração e a AWS concede acesso temporário seguro à Role `GitHubActionsRole`.
- **É 100% automático, permanente e livre de senhas para sempre.**

---

## 🏷️ Fluxo GitFlow Versionado (`release-vX.Y.Z`) & Promoção de Ambientes

O projeto utiliza o padrão profissional de **Branching Versionado (SemVer)** com duas contas AWS isoladas:

```
                                  [ DESENVOLVIMENTO ]
                                 Branch: feature/*
                                        │
                         (1. Validações TypeScript & SST)
                                        │
           (Action gera versão e cria branch release-v1.0.YYYYMMDD-HHMM)
                                        │
                                        ▼
                                 [ HOMOLOGAÇÃO ]
                             Branch: release-vX.Y.Z
                                        │
                   (2. Deploy Automático na Conta AWS Homologação)
                                        │
                         (Criação de Tag Git Oficial vX.Y.Z)
                                        │
                         (PR Automático via GitHub Action)
                                        │
                                        ▼
                                  [ PRODUÇÃO ]
                                  Branch: main
                                        │
                     (3. Trava de Aprovação + Deploy na AWS Prod)
```

---

## 📊 Checklist Claro de Execução da Fase 01

### 1. Criar Provedor OIDC e Role IAM na AWS (Homologação & Produção)
- [x] Criar Identity Provider OIDC (`token.actions.githubusercontent.com`) na Conta AWS Homologação
- [x] Criar Role IAM `GitHubActionsRole` confiando no GitHub na Conta AWS Homologação
- [x] Anexar política `AdministratorAccess` à Role de Homologação
- [x] Copiar o Role ARN de Homologação (`arn:aws:iam::351083991126:role/GitHubActionsRole`)
- [ ] Criar Identity Provider OIDC na Conta AWS Produção
- [ ] Criar Role IAM `GitHubActionsRole` confiando no GitHub na Conta AWS Produção
- [ ] Anexar política `AdministratorAccess` à Role de Produção
- [ ] Copiar o Role ARN de Produção (`arn:aws:iam::<ID_CONTA_PROD>:role/GitHubActionsRole`)

### 2. Configuração de Secrets e Proteções no GitHub (Apenas 2 Roles)
- [ ] Cadastrar `AWS_ROLE_ARN_STAGING` = `arn:aws:iam::351083991126:role/GitHubActionsRole` no GitHub Secrets
- [ ] Cadastrar `AWS_ROLE_ARN_PROD` no GitHub Secrets
- [ ] Cadastrar `AWS_REGION` = `us-east-1` no GitHub Secrets
- [ ] Criar o Environment `production` no GitHub com a trava de **Required Reviewers** (Aprovação Manual)

### 3. Implementação do Repositório Local
- [ ] Criar estrutura do repositório em `./fase_01_hairdule_infra_network/`
- [ ] Configurar `package.json` com SST v4 e TypeScript
- [ ] Implementar `sst.config.ts` em `us-east-1` (VPC CIDR `10.0.0.0/16`, 2 AZs, Subnets Privadas e Públicas, NAT Gateway)
- [ ] Validar compilação TypeScript com `npx tsc --noEmit`

### 4. Workflows de CI/CD via OIDC (4 Actions Implementadas)
- [ ] `.github/workflows/feature-validation.yml` (Valida feature, gera versão e abre PR para `release-vX.Y.Z`)
- [ ] `.github/workflows/deploy-staging.yml` (Deploy OIDC na AWS Homologação, Tag Git e PR para `main`)
- [ ] `.github/workflows/deploy-production.yml` (Deploy OIDC na AWS Produção com aprovação)
- [ ] `.github/workflows/destroy.yml` (Teardown OIDC com frase de confirmação `CONFIRM_DESTROY_NETWORK`)

### 5. Validação e Testes na AWS
- [ ] Executar deploy de teste na AWS Homologação via push em `release-vX.Y.Z`
- [ ] Validar promoção automática e deploy na AWS Produção via merge em `main`
- [ ] Validar teardown/destruição com a chave de confirmação de segurança

---

## 🔑 Passo a Passo Detalhado: Como Configurar o AWS OIDC (Sem Chaves)

### PARTE 1: Configurar a Conta AWS de Homologação (Staging) — CONCLUÍDO ✅

1. Faça login no **Console da AWS** da sua **Conta de Homologação**: `https://console.aws.amazon.com/` (Região: `us-east-1`).
2. Acesse o serviço **IAM** ➔ no menu lateral esquerdo, clique em **Identity providers** (Provedores de identidade).
3. Clique no botão azul **Add provider** (Adicionar provedor).
4. Selecione a opção **OpenID Connect**.
5. Preencha os campos exatamente assim:
   - **Provider URL:** `https://token.actions.githubusercontent.com`
   - Clique no botão verde **Get thumbprint** ao lado da URL.
   - **Audience:** `sts.amazonaws.com`
6. Clique em **Add provider**.
7. Agora, no menu lateral esquerdo do IAM, clique em **Roles** (Funções) ➔ clique em **Create role** (Criar função).
8. Selecione o tipo de entidade confiável: **Web identity** (Identidade web).
9. No campo **Identity provider**, selecione `token.actions.githubusercontent.com`.
10. No campo **Audience**, selecione `sts.amazonaws.com`.
11. Em **GitHub organization/username**, informe o seu nome de usuário do GitHub.
12. Clique em **Next**.
13. Em **Permissions**, selecione a política **`AdministratorAccess`** ➔ clique em **Next**.
14. Em **Role name**, informe: `GitHubActionsRole` ➔ clique em **Create role**.
15. **ROLE ARN GERADO (HOMOLOGAÇÃO):**  
    `arn:aws:iam::351083991126:role/GitHubActionsRole`

---

### PARTE 2: Configurar a Conta AWS de Produção (Prod)

1. Faça login no **Console da AWS** da sua **Conta de Produção**.
2. Repita exatamente os **passos 1 ao 15 da Parte 1**.
3. Copie o Role ARN de Produção gerado:
   - Exemplo: `arn:aws:iam::<ID_CONTA_PROD>:role/GitHubActionsRole`

---

### PARTE 3: Cadastrar as Roles (Secrets) no GitHub (Zero Chaves/Zero Senhas!)

1. Acesse o seu repositório no **GitHub**.
2. Vá na aba superior **Settings** ➔ **Secrets and variables** ➔ **Actions**.
3. Clique em **New repository secret** e cadastre apenas os 3 valores abaixo:

| Nome Exato do Secret | Valor a Colar | Descrição |
|---|---|---|
| `AWS_ROLE_ARN_STAGING` | `arn:aws:iam::351083991126:role/GitHubActionsRole` | ARN da Role OIDC da Conta Homologação |
| `AWS_ROLE_ARN_PROD` | `arn:aws:iam::<ID_CONTA_PROD>:role/GitHubActionsRole` | ARN da Role OIDC da Conta Produção |
| `AWS_REGION` | `us-east-1` | Região N. Virginia |

---

### PARTE 4: Configurar a Trava de Aprovação Manual (Reviewer) para Produção no GitHub

1. No mesmo repositório do **GitHub**, acesse **Settings** ➔ no menu lateral esquerdo, clique em **Environments**.
2. Clique no botão verde **New environment**.
3. Informe o nome exatamente: `production` ➔ clique em **Configure environment**.
4. Marque a opção **Required reviewers** (Revisores obrigatórios).
5. Selecione o seu usuário do GitHub como revisor obrigatório ➔ clique em **Save protection rules**.

---

## 🛠️ Guia do Usuário: Como Fazer Alterações nesta Fase

1. **Crie uma branch de feature a partir da main:**
   ```bash
   git checkout main
   git checkout -b feature/ajuste-vpc-subnets
   ```
2. **Abra o arquivo de configuração SST:**
   [sst.config.ts](sst.config.ts)
3. **Faça as alterações desejadas** (ex: alterar `az: 2` para `az: 3`).
4. **Valide a compilação localmente:**
   ```bash
   npx tsc --noEmit
   ```
5. **Envie o commit:**
   ```bash
   git push origin feature/ajuste-vpc-subnets
   ```
   *A esteira executará as validações, criará a branch `release-vX.Y.Z` correspondente e abrirá o Pull Request automaticamente.*

---

## ⚠️ Guia de Destruição Total (Teardown) & Cuidados Críticos

> [!CAUTION]
> **ATENÇÃO MÁXIMA ANTES DE EXECUTAR O DESTROY DA REDE:**  
> A VPC é a **fundação física** de todo o ecossistema Hairdule. Se você destruir a VPC enquanto o Banco de Dados (Fase 04), os Security Groups (Fase 02) ou as Lambdas estiverem ativos, a exclusão **FALHARÁ** com erro de dependência na AWS (`DependencyViolation`).

> [!WARNING]
> **ORDEM CORRETA DE DESTRUIÇÃO DO PROJETO:**  
> A exclusão dos repositórios na AWS **DEVE ser feita na ordem INVERSA das fases**:  
> 1º Frontends/Lambdas ➔ 2º API Gateway/Storage ➔ 3º Banco de Dados ➔ 4º Cognito ➔ 5º Security Groups ➔ **6º VPC (Fase 01 por ÚLTIMO)**.

### Como Executar o Destroy na AWS (Via GitHub Actions UI):

1. Acesse o repositório no **GitHub** ➔ Aba **Actions**.
2. Selecione o workflow **`4. Teardown - Destruir Infraestrutura (AWS)`**.
3. Clique em **Run workflow**.
4. Selecione o **Ambiente** (`staging` para Homologação ou `production` para Produção).
5. Digite exatamente a frase de segurança: **`CONFIRM_DESTROY_NETWORK`**.
6. Clique em **Run workflow**. A pipeline fará a remoção do ambiente selecionado na AWS de forma segura.

---

## 💻 Código do Projeto SST v4 (`sst.config.ts`)

```typescript
/// <reference path="./.sst/platform/config.d.ts" />

export default $config({
  app(input) {
    return {
      name: "hairdule-infra-network",
      removal: input?.stage === "production" ? "retain" : "remove",
      home: "aws",
      providers: {
        aws: {
          region: "us-east-1"
        }
      }
    };
  },
  async run() {
    // Criação da VPC em N. Virginia (us-east-1) com 2 Zonas de Disponibilidade
    const vpc = new sst.aws.Vpc("HairduleVpc", {
      az: 2,
      nat: "managed",
    });

    return {
      vpcId: vpc.id,
      publicSubnets: vpc.publicSubnets,
      privateSubnets: vpc.privateSubnets,
    };
  },
});
```

---

## 🚀 Workflows de CI/CD Implementados via AWS OIDC (`.github/workflows/`)

### 1. `feature-validation.yml`
```yaml
name: 1. CI - Validar Feature & Criar Branch release-vX.Y.Z

on:
  push:
    branches:
      - 'feature/**'

jobs:
  validate-and-create-release-branch:
    name: Validar Código & Criar Branch de Release Versionada
    runs-on: ubuntu-latest
    steps:
      - name: Checkout do Código
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js 22
        uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: 'npm'

      - name: Instalar Dependências
        run: npm ci

      - name: Validar Sintaxe & Compilação TypeScript
        run: npx tsc --noEmit

      - name: Gerar Nome da Versão de Release (vX.Y.Z)
        id: versioning
        run: |
          TIMESTAMP=$(date +'%Y%m%d-%H%M')
          VERSION="release-v1.0.${TIMESTAMP}"
          echo "RELEASE_BRANCH=${VERSION}" >> $GITHUB_ENV
          echo "Versão gerada: ${VERSION}"

      - name: Criar/Atualizar Branch de Release e Abrir PR
        uses: peter-evans/create-pull-request@v6
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          branch: ${{ env.RELEASE_BRANCH }}
          commit-message: "ci: validações da feature concluídas - preparando release"
          title: "PR Automático de Release: Merge ${{ github.ref_name }} -> ${{ env.RELEASE_BRANCH }}"
          body: |
            ## 🚀 Pull Request Automático de Release Versionado
            
            - **Feature de Origem:** `${{ github.ref_name }}`
            - **Nova Branch de Release:** `${{ env.RELEASE_BRANCH }}`
            - **Validações:** ✅ Compilação TypeScript e sintaxe SST v4 validadas com sucesso.
            
            O merge nesta branch irá disparar o deploy automático na conta **AWS Homologação**.
          base: main
```

### 2. `deploy-staging.yml`
```yaml
name: 2. CD - Deploy Homologação (release-v*) & Abrir PR para Main

on:
  push:
    branches:
      - 'release-v*'

permissions:
  id-token: write  # Obrigatório para autenticação segura via OIDC (Sem Chaves)
  contents: write
  pull-requests: write

jobs:
  deploy-staging-and-pr-prod:
    name: Deploy na AWS Homologação & Criar PR para Main
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - name: Checkout do Código
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js 22
        uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: 'npm'

      - name: Instalar Dependências
        run: npm ci

      - name: Autenticar na AWS via OIDC (Sem Chaves/Senhas - Homologação)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_STAGING }}
          aws-region: us-east-1

      - name: Executar Deploy SST v4 na AWS Homologação
        run: npx sst deploy --stage staging

      - name: Extrair Tag da Versão
        id: get_tag
        run: |
          BRANCH_NAME="${{ github.ref_name }}"
          TAG_NAME=$(echo "$BRANCH_NAME" | sed 's/release-//')
          echo "TAG_NAME=$TAG_NAME" >> $GITHUB_ENV
          echo "Tag extraída: $TAG_NAME"

      - name: Criar Tag Git de Versão Oficial
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.git.createRef({
              owner: context.repo.owner,
              repo: context.repo.repo,
              ref: `refs/tags/${process.env.TAG_NAME}`,
              sha: context.sha
            })

      - name: Abrir PR Automático da Branch release-v* para Main (Produção)
        uses: peter-evans/create-pull-request@v6
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          branch: main-promotion-${{ env.TAG_NAME }}
          commit-message: "cd: deploy em homologação concluído para ${{ env.TAG_NAME }}"
          title: "PR Automático de Promoção para Produção: ${{ github.ref_name }} -> main (${{ env.TAG_NAME }})"
          body: |
            ## 🚀 Pull Request Automático de Promoção para Produção
            
            - **Branch de Release:** `${{ github.ref_name }}`
            - **Tag de Versão Oficial:** `${{ env.TAG_NAME }}`
            - **Status Homologação:** ✅ Deploy e testes na AWS Homologação concluídos com sucesso.
            
            ⚠️ **ATENÇÃO:** O merge para `main` disparará o deploy na **Conta AWS de Produção**.
          base: main
```

### 3. `deploy-production.yml`
```yaml
name: 3. CD - Deploy Produção (AWS Prod)

on:
  push:
    branches:
      - main

permissions:
  id-token: write  # Obrigatório para autenticação segura via OIDC (Sem Chaves)
  contents: read

jobs:
  deploy-production:
    name: Deploy na AWS Produção
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Checkout do Código
        uses: actions/checkout@v4

      - name: Setup Node.js 22
        uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: 'npm'

      - name: Instalar Dependências
        run: npm ci

      - name: Autenticar na AWS via OIDC (Sem Chaves/Senhas - Produção)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_PROD }}
          aws-region: us-east-1

      - name: Executar Deploy SST v4 na AWS Produção
        run: npx sst deploy --stage production
```

### 4. `destroy.yml`
```yaml
name: 4. Teardown - Destruir Infraestrutura (AWS)

on:
  workflow_dispatch:
    inputs:
      stage:
        description: 'Ambiente a ser destruído (staging | production)'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production
      confirm_destroy:
        description: 'Digite exatamente: CONFIRM_DESTROY_NETWORK'
        required: true
        type: string

permissions:
  id-token: write  # Obrigatório para autenticação segura via OIDC (Sem Chaves)
  contents: read

jobs:
  destroy-infrastructure:
    name: Excluir Infraestrutura na AWS
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.stage }}
    steps:
      - name: Validar Frase de Confirmação de Segurança
        run: |
          if [ "${{ github.event.inputs.confirm_destroy }}" != "CONFIRM_DESTROY_NETWORK" ]; then
            echo "❌ ERRO DE SEGURANÇA: Frase de confirmação incorreta. Destruição abortada!"
            exit 1
          fi
          echo "✅ Frase de segurança confirmada. Iniciando processo de destruição no estágio: ${{ github.event.inputs.stage }}"

      - name: Checkout do Código
        uses: actions/checkout@v4

      - name: Setup Node.js 22
        uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: 'npm'

      - name: Instalar Dependências
        run: npm ci

      - name: Autenticar na AWS Homologação via OIDC (Sem Chaves)
        if: ${{ github.event.inputs.stage == 'staging' }}
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_STAGING }}
          aws-region: us-east-1

      - name: Autenticar na AWS Produção via OIDC (Sem Chaves)
        if: ${{ github.event.inputs.stage == 'production' }}
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_PROD }}
          aws-region: us-east-1

      - name: Executar Remoção SST v4
        run: npx sst remove --stage ${{ github.event.inputs.stage }}
```
