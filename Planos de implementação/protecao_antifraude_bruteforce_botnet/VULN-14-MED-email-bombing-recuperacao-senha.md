# VULN-14 — Flooding de E-mails e Esgotamento de Cota SES via Recuperação de Senha

> **Status:** [ ] 🔴 **Pendente de Correção**  
> **Severidade:** 🟡 **MÉDIA**  
> **CVSS v3.1:** 6.5 (`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:L`)  
> **Repositório Afetado:** [`fase_06_hairdule_auth_service`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_06_hairdule_auth_service)  
> **Arquivo Alvo:** [`src/routes/forgot_password.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_06_hairdule_auth_service/src/routes/forgot_password.py)

---

## 1. Descrição da Vulnerabilidade

O endpoint `POST /auth/forgot-password` dispara e-mails transacionais utilizando o serviço de envio da AWS (**Amazon SES**).

Atualmente, não existe nenhum controle de taxa no endpoint:
- Qualquer script pode chamar a rota repetidamente especificando o e-mail de uma vítima.
- A vítima recebe centenas ou milhares de e-mails de recuperação de senha em sua caixa de entrada (*Email Bombing / Harassment*).
- O envio massivo consome a cota diária e a taxa de envio do Amazon SES, podendo levar a AWS a suspender temporariamente a conta de envio de e-mails do Hairdule por suspeita de spam.

---

## 2. Cenário de Ataque

```
[ Atacante / Bot com script de loop ]
       │
       ▼ (Envia 1.000 requisições: POST /auth/forgot-password {email: vitima@gmail.com})
[ Auth Service processa cada requisição ]
       │
       ▼
[ Dispara 1.000 chamadas para AWS SES enviar e-mails ]
       │
       ▼
[ Caixa de entrada da vítima lotada; Cota de envio do SES esgotada ]
```

---

## 3. Evidência no Código Atual

Arquivo: `fase_06_hairdule_auth_service/src/routes/forgot_password.py` (linhas 17 a 44):
```python
@router.post("/forgot-password", status_code=status.HTTP_200_OK)
def forgot_password(payload: ForgotPasswordRequest):
    provider = get_auth_provider()
    provider.forgot_password(email=payload.email)
    
    # ⚠️ Dispara envio imediato no SES para toda requisição recebida!
    email_service = EmailService()
    email_service.send_password_reset_email(to_email=payload.email, ...)
```

---

## 4. Solução Técnica Proposta

1. **Rate Limiting por E-mail de Destino:**
   - Máximo de **1 solicitação de recuperação de senha a cada 15 minutos por e-mail**.
   - Se uma nova solicitação for recebida antes do prazo, o endpoint responde silenciosamente com mensagem de sucesso (idempotente), mas **não dispara um novo e-mail pelo SES**, evitando sobrecarga e vazamento de informação.
2. **Rate Limiting por IP:**
   - Máximo de **3 solicitações a cada 15 minutos por endereço IP**.
   - Se estourar o limite, retorna `HTTP 429 Too Many Requests`.

---

## 5. Checklist de Implementação & Validação

- [ ] Implementar trava de resfriamento em memória / cache (janela de 15 minutos) por e-mail em `forgot_password.py`.
- [ ] Aplicar rate limit de IP (máx 3 requisições por 15 min).
- [ ] Criar teste unitário em `tests/test_routes.py` garantindo que chamadas subsequentes para o mesmo e-mail não invocam `EmailService.send_password_reset_email`.
- [ ] Validar que após 15 minutos o e-mail pode ser disparado novamente.
