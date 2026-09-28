# VULN-15 — Criação Automatizada de Agendamentos Falsos por Falta de Desafio Anti-Bot

> **Status:** [x] ✅ **Corrigido e Validado em Homologação (PR #47 da fase_05, PR #10 da fase_17 e PR #55 da fase_08)**  
> **Severidade:** 🔶 **ALTA**  
> **CVSS v3.1:** 7.6 (`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:H/A:H`)  
> **Repositórios Afetados:** [`fase_08_hairdule_ui_web`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_08_hairdule_ui_web) (Frontend Angular 19) e [`fase_05_hairdule_shared`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_05_hairdule_shared) (Validador Backend)  
> **Arquivos Alvo:** `fase_08_hairdule_ui_web/src/index.html`, `fase_05_hairdule_shared/src/hairdule_shared/security/turnstile.py`

---

## 1. Descrição da Vulnerabilidade

O fluxo de agendamento online público (`POST /public/appointments`) é aberto a qualquer visitante sem necessidade de login prévio ou verificação de cartão de crédito.

### Vulnerabilidades Associadas:
1. **Negação de Negócio (Denial of Business / Agenda Flooding):** Um script simples de automação consegue criar dezenas de agendamentos falsos em minutos, preenchendo todos os horários livres dos barbeiros para os próximos dias. Clientes reais encontram a agenda cheia e não conseguem agendar.
2. **Criação de Barbearias Falsas (`POST /auth/signup`):** Bots podem criar dezenas de cadastros falsos na plataforma, poluindo as tabelas de barbearias, usuários e gerando custos desnecessários no banco Aurora.
3. **Ausência de Desafio Criptográfico:** Ferramentas como cURL, Insomnia e scripts em Python/Node conseguem invocar os endpoints diretamente sem rodar um navegador legítimo.

---

## 2. Cenário de Ataque

```
[ Concorrente / Script Automatizado ]
       │
       ▼ (Dispara 50 requisições: POST /public/appointments para todos os horários da semana)
[ Backend processa e grava na tabela Appointment ]
       │
       ▼
[ Todos os horários de sexta e sábado ficam marcados como BOOKED ]
       │
       ▼
[ Clientes legítimos não conseguem agendar; Barbeiros ficam sem atendimento real ]
```

---

## 3. Solução Técnica Proposta

Integrar o **Cloudflare Turnstile** no modo **Invisível (Zero Friction)**:

1. **Frontend Angular 19 (`fase_08`):**
   - O SDK do Turnstile executa em segundo plano no momento em que o cliente abre o formulário de agendamento ou cadastro.
   - Gera silenciosamente um token criptográfico (`cf_turnstile_token`).
   - O cliente humano **não precisa clicar em nada nem resolver quebra-cabeças**.
2. **Backend Serverless Compartilhado (`fase_05`):**
   - As rotas públicas sensíveis exigem o cabeçalho `X-Turnstile-Token`.
   - O backend valida o token junto ao endpoint oficial da Cloudflare (`POST https://challenges.cloudflare.com/turnstile/v0/siteverify`).
   - Se o token estiver ausente ou for inválido, a requisição é descartada com `HTTP 403 Forbidden` (`CAPTCHA_VALIDATION_FAILED`).
3. **Suporte a CI/CD e Testes:**
   - Uso das chaves oficiais de teste da Cloudflare (`1x00000000000000000000AA`), garantindo que todos os testes automatizados da esteira continuem passando 100% verdes.

---

## 4. Checklist de Implementação & Validação

- [x] Criar o módulo validador `hairdule_shared.security.turnstile` na `fase_05_hairdule_shared`.
- [x] Adicionar o script do Cloudflare Turnstile no `index.html` da `fase_08_hairdule_ui_web`.
- [x] Injetar o serviço `TurnstileService` e cabeçalho `X-Turnstile-Token` no envio de agendamento público (`ClientPortalService`).
- [x] Proteger o endpoint `POST /public/appointments` com a dependência `require_turnstile` na `fase_17_hairdule_appointment_service`.
- [x] Testes unitários frontend e backend 100% aprovados e deploy realizado em Homologação.
