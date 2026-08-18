# 🛡️ Fase 04.2 — Bastion Host Seguro com AWS SSM, RDS IAM Auth e Auto-Stop (`fase_04_2_hairdule_bastion`)
## Checklist de Execução — Status Completo

> **Repositório:** `https://github.com/MarquesCleitonOrg/fase_04_2_hairdule_bastion`  
> **Tecnologia:** SST v4 (`sst@4.17.1`), TypeScript + AWS EC2 (`t4g.nano` ARM64) + AWS Systems Manager (SSM) + EventBridge Scheduler + RDS IAM Auth  
> **Região AWS:** `us-east-1` (N. Virginia)  
> **Dependências Diretas:** Fase 01 (`vpcId`, `publicSubnets`, `privateSubnets`) + Fase 02 (`sgLambdaId`) + Fase 04 (`clusterEndpoint`)  
> **Última verificação:** 2026-08-16  

---

## 🎯 Objetivo da Fase

A **Fase 04.2** provisiona um **ponto de acesso administrativo seguro e privado (Bastion Host)** para o banco de dados Aurora PostgreSQL em homologação (Staging) e produção (Production). 

Ela permite que desenvolvedores e administradores conectem ferramentas visuais como **DBeaver, TablePlus ou pgAdmin** ao banco de dados rodando em `localhost:5432` através de um **túnel criptografado AWS SSM**, sem que o banco de dados precise ser exposto à internet pública.

### 🛡️ Princípios Fundamentais de Segurança:
1. **Zero Portas Abertas na Internet:** O Security Group possui `ingress: []` (zero regras de entrada, nem mesmo a porta SSH 22).
2. **Subnet Pública com Zero Ingress ($0 de Custo):** A instância reside na Subnet Pública para falar com a AWS via Internet Gateway gratuito da Fase 01, economizando ~$250/ano em VPC Endpoints.
3. **Autenticação Nativa AWS RDS IAM (Zero Senhas Fixas):** Ninguém usa senha estática. O acesso é autenticado via tokens temporários assinados digitalmente pelo AWS CLI com validade de 15 minutos para o handshake inicial.
4. **Permissões Granulares por Ambiente:**
   - **Homologação (Staging):** Conecta como `hairdule_developer` (permissão DML: `SELECT, INSERT, UPDATE, DELETE` — **ZERO DDL**, proibido alterar/criar tabelas).
   - **Produção (Production):** Conecta como `hairdule_readonly` via **Reader Endpoint (`cluster-ro-*`)** (permissão 100% `SELECT` apenas).
5. **Auto-Stop Diário à Meia-Noite:** Regra EventBridge (`cron(0 3 * * ? *)` = 00:00 BRT) aciona uma Lambda que desliga a instância automaticamente se estiver ligada, garantindo **custo próximo a zero ($0/mês)**.

---

## 🏛️ Diagrama de Arquitetura

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 💻 SEU COMPUTADOR (DBeaver / localhost:5432)                                │
│    1. aws configure (Credenciais IAM do Desenvolvedor)                      │
│    2. .\scripts\connect_dbeaver.ps1 (Gera Token IAM + Abre Túnel SSM)       │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ 🔒 Túnel TLS Criptografado (AWS SSM)
                                       │ (Zero portas de entrada / Sem SSH)
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 🔒 VPC PRIVADA HAIRDULE (10.0.0.0/16)                                       │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ 🛡️ BASTION HOST EC2 (t4g.nano - Amazon Linux 2023 ARM64)            │   │
│   │    • Subnet Pública (Fase 01 - Rota IGW para saída SSM $0)          │   │
│   │    • Security Group: sg-lambda-services (Fase 02)                   │   │
│   │    • Role: AmazonSSMManagedInstanceCore                             │   │
│   │    • Ingress: ZERO (Nenhuma porta de entrada aberta)                │   │
│   └──────────────────────────────────┬──────────────────────────────────┘   │
│                                      │ TCP 5432 (Interno na VPC)            │
│                                      ▼                                      │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ 🐘 AURORA POSTGRESQL SERVERLESS v2 (Fase 04)                        │   │
│   │    • Subnet Privada | publiclyAccessible: false                     │   │
│   │    • Staging: hairdule_developer (DML sem DDL)                      │   │
│   │    • Produção: hairdule_readonly (Reader Endpoint cluster-ro-*)     │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ ⏰ AUTO-STOP SCHEDULER (00:00 BRT / 03:00 UTC)                      │   │
│   │    • EventBridge Rule ──► Lambda Auto-Stop ──► ec2:StopInstances    │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📖 Guia de Conexão Passo a Passo (Desde o AWS Configure)

### 1. Autenticação no Terminal (`aws configure`):
```powershell
aws configure
# Preencha suas credenciais:
# AWS Access Key ID: AKIA...
# AWS Secret Access Key: wJalr...
# Default region name: us-east-1
# Default output format: json
```

### 2. Abrir o Túnel e Gerar Token IAM:
```powershell
cd "d:\Documentos\Projetos\Hairdule\Hairdule Reborn\fase_04_2_hairdule_bastion"
.\scripts\connect_dbeaver.ps1 -Stage staging
```

### 3. Configurar Conexão no DBeaver:
* **Host:** `localhost` | **Porta:** `5432` | **Database:** `hairdule`
* **Username:** `hairdule_developer` (Staging) ou `hairdule_readonly` (Produção)
* **Password:** Pressione `Ctrl + V` (cola o token IAM gerado)
* **Aba SSL:** Marcar `[X] Use SSL` com modo `require`.

---

## ✅ Checklist Completo da Fase 04.2

### 🔗 1. Pré-requisitos e Contratos
- [x] Fase 01 staging deployada (`vpcId`, `publicSubnets`, `privateSubnets` disponíveis)
- [x] Fase 02 staging deployada (`sgLambdaId` disponível)
- [x] Fase 04 staging deployada (`clusterEndpoint`, `readerEndpoint` disponíveis)
- [x] Configuração centralizada em `config/environments.ts`

---

### 🏗️ 2. Infraestrutura SST (`sst.config.ts`)
- [x] AMI oficial Amazon Linux 2023 ARM64 recuperada via SSM Parameter
- [x] Instância `t4g.nano` alocada na `publicSubnets[0]` com `associatePublicIpAddress: true`
- [x] Security Group `sgLambdaId` associado (ingress vazio, egress liberado)
- [x] Sem par de chaves SSH (`keyName: undefined`)
- [x] IAM Instance Profile com `AmazonSSMManagedInstanceCore`
- [x] Lambda inline de Auto-Stop (`nodejs20.x`) para `ec2:StopInstances`
- [x] Regra EventBridge Schedule às 00:00 BRT
- [x] Outputs exportados: `bastionInstanceId`, `bastionPrivateIp`, `clusterEndpoint`, `ssmConnectCommand`

---

### 🛠️ 3. Scripts de Conexão Rápida (`scripts/`)
- [x] `scripts/connect_dbeaver.ps1` — Script PowerShell para Windows (compatível com PS 5.1 e PS 7)
- [x] `scripts/connect_dbeaver.sh` — Script Bash para Linux/macOS
- [x] Geração automatizada de token temporário AWS RDS IAM (`aws rds generate-db-auth-token`)
- [x] Cópia automática do token para o Clipboard

---

### ⚙️ 4. Workflows de CI/CD (GitHub Actions)
- [x] `feature-validation.yml` — Validação TypeScript e criação dinâmica de release branch
- [x] `deploy-staging.yml` — Deploy SST em Staging com tags versionadas e abertura de PR para `producao`
- [x] `deploy-production.yml` — Deploy em Produção (100% Read-Only) e sincronização para `main`

---

## 📈 Resumo de Progresso

| Categoria | Total | Concluídos | % |
|---|---|---|---|
| Pré-requisitos e Contratos | 4 | 4 | **100%** ✅ |
| Infraestrutura SST (Bastion + SSM + AutoStop) | 8 | 8 | **100%** ✅ |
| Scripts Utilitários de Conexão | 4 | 4 | **100%** ✅ |
| Workflows CI/CD | 3 | 3 | **100%** ✅ |
| **TOTAL** | **19** | **19** | **100%** ✅ |
