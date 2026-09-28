# 🛡️ Plano Estratégico de Proteção: Brute-Force, Anti-Scraping e Defesa Anti-Bot (CAPTCHA)

> **Status:** 📋 Proposto para Implementação  
> **Data:** 28 de Setembro de 2026  
> **Classificação:** Defesa em Profundidade / Segurança de Aplicação & Borda  
> **Escopo:** `fase_07_hairdule_infra_api`, `fase_06_hairdule_auth_service`, `fase_17_hairdule_appointment_service`, `fase_08_hairdule_ui_web`, `fase_20_hairdule_infra_cdn`

---

## 1. Diagnóstico do Cenário Atual (Vulnerabilidades Confirmadas)

Durante testes de validação em homologação (`staging`), foi comprovado que **a proteção contra abusos de taxa e força bruta não está atuando a nível de rota**:

1. **Rotas Públicas Sem Restrição por IP ou Rota Específica:**
   - O endpoint `GET /public/appointments/by-phone` respondeu com `HTTP 200` em rajadas a cada `0,01s` (100 req/s), permitindo enumeração sequencial de números de telefone e raspagem de dados pessoais (PII) de clientes.
   - O `defaultRouteSettings` do stage `$default` do API Gateway estava com `throttlingBurstLimit: 100` e `throttlingRateLimit: 50`. Por ser um limite de stage agregado, pequenas rajadas automatizadas (ex: 20 a 50 requisições rápidas) nunca esvaziam o balde e passam livremente.
2. **Rotas de Autenticação (`/auth/login`) Desprotegidas:**
   - O endpoint `POST /auth/login` repassa cada tentativa diretamente ao AWS Cognito e ao banco de dados Aurora PostgreSQL.
   - Embora o Cognito possua um bloqueio exponencial para senhas erradas no mesmo usuário, ele **não impede ataques distribuídos de credential stuffing** (testar senhas fracas comuns contra milhares de emails diferentes) nem ataques de negação de serviço econômico (consumo de concorrência Lambda e pool de conexões do banco).
3. **Abuso de Serviços Transacionais (`/auth/forgot-password` e `/public/appointments/...`):**
   - Endpoints que disparam e-mails (AWS SES) não possuem limitação nem comprovação de humanidade (CAPTCHA), permitindo *email bombing* e consumo indevido da cota de envio da AWS.
4. **Criação de Agendamentos Falsos (`POST /public/appointments`):**
   - Bots podem criar dezenas de agendamentos em segundos, bloqueando horários legítimos de barbearias (*Denial of Business*).

---

## 2. Avaliação de Soluções Anti-Bot: Vale a pena CAPTCHA?

### **Resposta Técnica: SIM, É ESSENCIAL.**
No entanto, **não se deve utilizar CAPTCHAs intrusivos** (como caixas de seleção de semáforos/hidrantes do reCAPTCHA v2), pois destroem a taxa de conversão do agendamento dos clientes da barbearia.

### 🏆 Solução Selecionada: **Cloudflare Turnstile (Invisível)**

| Critério | Cloudflare Turnstile | Google reCAPTCHA v3 | AWS WAF CAPTCHA |
| :--- | :---: | :---: | :---: |
| **Custo** | **100% Gratuito (ilimitado)** | Gratuito até 1M/mês | $0.40 por 1.000 desafios |
| **Atrito com o Usuário** | **Zero (Invisível)** | Zero (Baseado em Score) | Alto (Desafio Interativo) |
| **Privacidade** | **Não rastreia navegação** | Coleta telemetria Google | Focado em infraestrutura AWS |
| **Integração Frontend** | Script leve + Angular Component | Script Google | Injeção no CloudFront |
| **Validação Backend** | 1 chamada HTTP simples (`POST`) | 1 chamada HTTP (`POST`) | Validado no Application Load Balancer / Edge |

> **Decisão de Arquitetura:** Adotar **Cloudflare Turnstile em modo Invisível**. O cliente legítimo realiza o agendamento ou login sem clicar em nada, enquanto ferramentas automatizadas (Insomnia, cURL, scripts Python) são bloqueadas instantaneamente no backend por ausência do token criptográfico de desafio.

---

## 3. Arquitetura de Defesa em Profundidade (4 Camadas)

Para garantir proteção completa e resiliente, o sistema implementará 4 camadas defensivas:

```
[ REQUISIÇÃO CLIENTE ]
        │
        ▼
┌────────────────────────────────────────────────────────────────────────┐
│ CAMADA 1: Borda & API Gateway (fase_07_hairdule_infra_api)             │
│ • Throttling granular por Rota (RouteSettings) no AWS API Gateway      │
│ • Bloqueio imediato em HTTP 429 para rajadas rápidas                   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ CAMADA 2: Desafio Anti-Bot / CAPTCHA Invisível (Cloudflare Turnstile)  │
│ • Frontend (fase_08) gera Turnstile Response Token invisivelmente     │
│ • Backend valida token no endpoint da Cloudflare em milissegundos     │
│ • Bots e scripts sem navegador tomam HTTP 403 Forbidden                │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ CAMADA 3: Rate Limiting de Aplicação por IP / Chave Composta (FastAPI) │
│ • Limite por IP de origem (X-Forwarded-For)                            │
│ • Limite por chave de negócio (ex: max 5 consultas por telefone/min)   │
│ • Resposta HTTP 429 com cabeçalho Retry-After                          │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ CAMADA 4: Provedor de Identidade & Contas (AWS Cognito)                │
│ • Bloqueio de conta após falhas consecutivas de senha                  │
│ • Respostas com timing constante para evitar enumeração de usuários    │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Matriz de Proteção por Rota Sensível

| Rota | Método | Riscos Mitigados | Limite API Gateway | CAPTCHA Turnstile? | Limite de Aplicação (IP / Negócio) |
| :--- | :---: | :--- | :---: | :---: | :--- |
| `/auth/login` | `POST` | Brute-force, Credential Stuffing | Burst: 5, Rate: 2 | ✅ Opcional/Invisível | 5 tentativas erradas / 5 min por IP |
| `/auth/signup` | `POST` | Criação de barbearias falsas, bot spam | Burst: 3, Rate: 1 | ✅ **Obrigatório** | 3 cadastros / hora por IP |
| `/auth/forgot-password` | `POST` | Email Bombing via AWS SES, Enumeração | Burst: 3, Rate: 1 | ✅ **Obrigatório** | 3 envios / 15 min por IP e por e-mail |
| `/public/appointments/by-phone` | `GET` | Scraping de clientes e PII, Enumeração | Burst: 3, Rate: 1 | ✅ **Obrigatório** | 5 consultas / 5 min por IP e por telefone |
| `/public/appointments` | `POST` | Bloqueio artificial de agenda (DoS) | Burst: 5, Rate: 2 | ✅ **Obrigatório** | 3 agendamentos / 10 min por IP |
| `/public/appointments/{code}/request-cancel` | `POST` | Spam de e-mails de cancelamento | Burst: 3, Rate: 1 | ✅ **Obrigatório** | 3 solicitações / 10 min por IP |
| `/public/appointments/{code}/request-reschedule` | `POST` | Spam de e-mails de reagendamento | Burst: 3, Rate: 1 | ✅ **Obrigatório** | 3 solicitações / 10 min por IP |

---

## 5. Estrutura dos Planos de Implementação Específicos

Para execução modular e segura, este plano desdobra-se em 4 documentos detalhados:

1. 📄 [PLANO-PROT-01-RATE-LIMITING-API-GATEWAY.md](./PLANO-PROT-01-RATE-LIMITING-API-GATEWAY.md)
   - Configuração do `routeSettings` no `aws.apigatewayv2.Stage` da `fase_07_hairdule_infra_api`.
2. 📄 [PLANO-PROT-02-PROTECAO-BRUTE-FORCE-AUTH.md](./PLANO-PROT-02-PROTECAO-BRUTE-FORCE-AUTH.md)
   - Rate limiting por IP e bloqueio de tentativas sucessivas no `fase_06_hairdule_auth_service`.
3. 📄 [PLANO-PROT-03-ANTI-SCRAPING-APPOINTMENTS.md](./PLANO-PROT-03-ANTI-SCRAPING-APPOINTMENTS.md)
   - Proteção de enumeração por telefone e criação massiva de agendamentos no `fase_17_hairdule_appointment_service`.
4. 📄 [PLANO-PROT-04-INTEGRACAO-CAPTCHA-CLOUDFLARE-TURNSTILE.md](./PLANO-PROT-04-INTEGRACAO-CAPTCHA-CLOUDFLARE-TURNSTILE.md)
   - Implementação do widget invisível no Angular 19 (`fase_08_hairdule_ui_web`) e validador compartilhado no `fase_05_hairdule_shared`.
