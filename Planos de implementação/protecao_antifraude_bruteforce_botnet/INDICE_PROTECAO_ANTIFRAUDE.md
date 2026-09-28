# 🛡️ Relatório de Proteção Avançada: Anti-Fraude, Brute-Force e Botnets — Hairdule 2.0

> **Status:** 📋 Mapeado e Pronto para Execução  
> **Data:** 28 de Setembro de 2026  
> **Responsável:** Especialista em Cibersegurança & Engenharia de Segurança Serverless  
> **Escopo:** `fase_20_hairdule_infra_cdn`, `fase_07_hairdule_infra_api`, `fase_06_hairdule_auth_service`, `fase_17_hairdule_appointment_service`, `fase_08_hairdule_ui_web`, `fase_05_hairdule_shared`  
> **Referência:** [Índice Mestre de Planos](../INDICE_MESTRE.md) | [Auditoria 360 Anterior (VULN-01 a 09)](../analise_seguranca_360/INDICE_ANALISE_SEGURANCA.md)

---

## 1. Resumo Executivo da Nova Análise

Após a conclusão e validação em homologação das 9 vulnerabilidades estruturais (VULN-01 a VULN-09), foi realizado um teste prático de estresse e força bruta nas rotas públicas e de autenticação. 

Identificou-se que **a aplicação responde 200 OK mesmo sob rajadas extremas de 100 requisições por segundo**, evidenciando ausência de:
1. **Geo-blocking internacional** (CloudFront aceitando tráfego do mundo inteiro).
2. **Throttling granular por rota** (Token bucket global muito permissivo no API Gateway).
3. **Controle de força bruta e credential stuffing** por IP e por alvo no Auth Service.
4. **Proteção anti-scraping e mascaramento** de clientes no endpoint `/by-phone`.
5. **Proteção contra Email Bombing** no fluxo de recuperação de senha.
6. **Desafio anti-bot (CAPTCHA invisível / Cloudflare Turnstile)** contra criação automatizada de agendamentos falsos.

---

## 2. Matriz de Vulnerabilidades & Status de Correção

| ID | Status | Vulnerabilidade | Severidade | CVSS v3.1 | Repositório Afetado | Arquivo Detalhado |
| :---: | :---: | :--- | :---: | :---: | :--- | :--- |
| **VULN-10** | [ ] 🔴 Pendente | **Ausência de Geo-blocking no CloudFront (Exposição a Scanners Internacionais)** | 🔶 **ALTA** | **7.5** | `fase_20_hairdule_infra_cdn` | [VULN-10-HIGH-geoblocking-ausente-exposicao-internacional.md](./VULN-10-HIGH-geoblocking-ausente-exposicao-internacional.md) |
| **VULN-11** | [ ] 🔴 Pendente | **Throttling Permissivo no API Gateway Permitindo Rajadas Rápidas e DoS L7** | 🔶 **ALTA** | **7.8** | `fase_07_hairdule_infra_api` | [VULN-11-HIGH-throttling-permissivo-api-gateway.md](./VULN-11-HIGH-throttling-permissivo-api-gateway.md) |
| **VULN-12** | [ ] 🔴 Pendente | **Ausência de Rate Limiting por IP e Alvo (E-mail) no Endpoint de Login** | 🔶 **ALTA** | **8.1** | `fase_06_hairdule_auth_service` | [VULN-12-HIGH-bruteforce-credential-stuffing-login.md](./VULN-12-HIGH-bruteforce-credential-stuffing-login.md) |
| **VULN-13** | [ ] 🔴 Pendente | **Enumeração e Scraping em Massa de PII no Endpoint de Consulta por Telefone** | 🔶 **ALTA** | **8.2** | `fase_17_hairdule_appointment_service` | [VULN-13-HIGH-scraping-pii-clientes-by-phone.md](./VULN-13-HIGH-scraping-pii-clientes-by-phone.md) |
| **VULN-14** | [ ] 🔴 Pendente | **Flooding de E-mails e Esgotamento de Cota SES via Recuperação de Senha** | 🟡 **MÉDIA** | **6.5** | `fase_06_hairdule_auth_service` | [VULN-14-MED-email-bombing-recuperacao-senha.md](./VULN-14-MED-email-bombing-recuperacao-senha.md) |
| **VULN-15** | [ ] 🔴 Pendente | **Criação de Agendamentos Falsos (Denial of Business) por Falta de Desafio Anti-Bot** | 🔶 **ALTA** | **7.6** | `fase_08_hairdule_ui_web` / `fase_05_hairdule_shared` | [VULN-15-HIGH-fake-bookings-ausencia-captcha-turnstile.md](./VULN-15-HIGH-fake-bookings-ausencia-captcha-turnstile.md) |

---

## 3. Roteiro de Implementação em 3 Blocos Táticos

### 🚀 Bloco 1: Infraestrutura de Borda e Gateway (Mitigação Imediata)
- [ ] **VULN-10:** Ativar Whitelist `BR` no CloudFront (`fase_20`) para descarte imediato de tráfego fora do Brasil.
- [ ] **VULN-11:** Implementar `routeSettings` granular no API Gateway (`fase_07`) para responder `429 Too Many Requests` em rajadas a partir de 3 requisições.

### 🛡️ Bloco 2: Rate Limiting de Aplicação & Proteção por Alvo (Anti IP Dinâmico)
- [ ] **VULN-12:** Adicionar rate limit por IP e por e-mail no `/auth/login` (`fase_06`).
- [ ] **VULN-13:** Adicionar rate limit por telefone + IP e detecção de scanner no `/public/appointments/by-phone` (`fase_17`).
- [ ] **VULN-14:** Adicionar trava de 1 email/15 min por destinatário em `/auth/forgot-password` (`fase_06`).

### 🤖 Bloco 3: Desafio Anti-Bot Criptográfico Invisível
- [ ] **VULN-15:** Integrar widget invisível do Cloudflare Turnstile no Angular 19 (`fase_08`) e validador serverless no Shared Layer (`fase_05`).
