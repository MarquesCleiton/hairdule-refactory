# 🌐 Guia de Migração do Amazon SES para o Domínio Oficial (`hairdule.com.br`)

Este guia detalha o procedimento declarativo para migrar o serviço de envio de e-mails do modo de e-mail avulso provisório (`cleiton2210@gmail.com`) para o **domínio oficial da plataforma (`hairdule.com.br`)**, 100% via esteira GitFlow / GitHub Actions.

---

## 📌 Contexto Atual (Staging / Provisório)

- **Remetente Ativo**: `Hairdule Staging <cleiton2210@gmail.com>`
- **Infraestrutura**: Provisionada no repositório `fase_03_hairdule_infra_auth` via SST v4 (`aws.sesv2.EmailIdentity`).
- **Status AWS**: Identidade verificada e envio real ativado (`SES_ENABLED = true`).
- **Contrato SSM**:
  - `/sst/hairdule/staging/ses/enabled` = `"true"`
  - `/sst/hairdule/staging/ses/email-source` = `"Hairdule Staging <cleiton2210@gmail.com>"`

---

## 🚀 Passo a Passo: Migração para `hairdule.com.br`

Assim que o domínio `hairdule.com.br` for adquirido (ex: Registro.br, GoDaddy, Route 53), siga os passos abaixo:

### Passo 1 — Atualizar a Configuração no Repositório `fase_03_hairdule_infra_auth`

No arquivo [`config/environments.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_03_hairdule_infra_auth/config/environments.ts):

1. Altere o bloco `ses` do ambiente desejado (`staging` ou `production`):
   ```typescript
   ses: {
     enabled: true,
     customDomainProvisioned: true, // 👈 Alterne para true
     domain: "hairdule.com.br",
     mailFromSubdomain: "mail",
     emailSource: "Hairdule <noreply@hairdule.com.br>", // 👈 Remetente oficial
   },
   ```

2. Faça o commit e push na branch de feature:
   ```bash
   git add .
   git commit -m "feat(ses): ativar identidade de dominio oficial hairdule.com.br"
   git push origin HEAD
   ```

3. A esteira de CI/CD do GitHub Actions executará o deploy automaticamente no SST v4, criando os seguintes recursos na AWS:
   - `aws.ses.DomainIdentity` para `hairdule.com.br`
   - `aws.ses.DomainDkim` (gera 3 tokens CNAME EasyDKIM 2048-bit)
   - `aws.ses.MailFrom` para `mail.hairdule.com.br`

---

### Passo 2 — Apontar os Registros no DNS do Provedor de Domínio

No painel onde o domínio `hairdule.com.br` foi registrado (ex: Registro.br ou Route 53), adicione os seguintes registros:

#### 1. Registros DKIM (Autenticação CNAME — 3 registros)
| Tipo | Nome (Host) | Valor (Destino) |
|---|---|---|
| `CNAME` | `<token1>._domainkey.hairdule.com.br` | `<token1>.dkim.amazonses.com` |
| `CNAME` | `<token2>._domainkey.hairdule.com.br` | `<token2>.dkim.amazonses.com` |
| `CNAME` | `<token3>._domainkey.hairdule.com.br` | `<token3>.dkim.amazonses.com` |

*(Os tokens exatos são exibidos nos logs da esteira do GitHub Actions ou no console AWS SES).*

#### 2. Registros MAIL FROM & SPF (Subdomínio `mail.hairdule.com.br`)
| Tipo | Nome (Host) | Valor (Destino) | Prioridade |
|---|---|---|:---:|
| `MX` | `mail.hairdule.com.br` | `feedback-smtp.us-east-1.amazonses.com` | `10` |
| `TXT` | `mail.hairdule.com.br` | `v=spf1 include:amazonses.com ~all` | - |

#### 3. Registro DMARC (Proteção Antifraude / Anti-Spoofing)
| Tipo | Nome (Host) | Valor (Destino) |
|---|---|---|
| `TXT` | `_dmarc.hairdule.com.br` | `v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@hairdule.com.br; pct=100; sp=quarantine` |

---

### Passo 3 — Solicitar Saída do Sandbox da AWS (Produção)

Para enviar e-mails para **qualquer destinatário do mundo** sem precisar verificar e-mails individualmente:

1. Acesse o **Console AWS SES** (`us-east-1`).
2. No menu lateral, vá em **Account dashboard**.
3. Clique no botão **Request production access**.
4. Preencha o formulário informando:
   - **Mail type**: Transactional (convite de equipe, recuperação de senha, confirmação de agendamentos).
   - **Website URL**: `https://hairdule.com.br`
   - **Description**: Descreva brevemente que o sistema envia apenas e-mails transacionais mediante ação direta do usuário.
5. A aprovação da AWS costuma ocorrer em menos de 24 horas úteis.

---

### Passo 4 — Atualização Automática dos Microsserviços

Não é necessário alterar código nos microsserviços de Backend (`barbershop-service`, `staff-service`, `auth-service`):
- Como as Lambdas leem `/sst/hairdule/${stage}/ses/email-source` dinamicamente do **SSM Parameter Store**, ao executar o deploy do Passo 1, todos os microsserviços passam a usar automaticamente `noreply@hairdule.com.br`!
