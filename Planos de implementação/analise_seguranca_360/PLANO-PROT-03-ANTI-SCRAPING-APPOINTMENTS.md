# 🛡️ Plano de Implementação: Anti-Scraping e Proteção no Appointment Service

> **Status:** 📋 Pronto para Execução  
> **Prioridade:** 🚨 Alta  
> **Repositório Afetado:** `fase_17_hairdule_appointment_service`  
> **Arquivos Alvo:** [`src/routes/public_appointments.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_17_hairdule_appointment_service/src/routes/public_appointments.py), [`src/services/appointment_service.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_17_hairdule_appointment_service/src/services/appointment_service.py)

---

## 1. Problema Identificado

1. **Enumeração em Massa de Clientes em `/public/appointments/by-phone`:**
   - Com apenas o `barbershop_id` (público) e um número de telefone com DDD, um script consegue iterar sequências de telefones e descobrir quem são os clientes da barbearia, quais serviços contratam, horários agendados e códigos de agendamento.
   - O teste comprovou que o endpoint responde `200` em taxas abusivas de 100 requisições por segundo.
2. **Criação de Agendamentos Falsos (Denial of Business):**
   - Bots podem emitir centenas de `POST /public/appointments`, bloqueando todos os slots disponíveis da agenda de profissionais legítimos sem necessidade de qualquer cartão ou login prévio.

---

## 2. Solução Técnica Proposta

### A. Limite Estrito por Telefone e IP no `by-phone`
1. O endpoint deve limitar as consultas para:
   - **Máximo de 5 consultas a cada 5 minutos por par `(IP, telefone)`**.
   - Se um mesmo IP tentar pesquisar mais de 5 números diferentes em menos de 1 minuto, aciona bloqueio por **comportamento de scanner/crawler** (retornando `429`).

### B. Mascaramento Reforçado de PII
Garantir que a resposta pública nunca retorne dados completos de identificação do cliente caso consultada via web:
- Nome: `Carlos E. Silva` -> `Carlos S****`
- Telefone: `11948112606` -> `(11) 9****-2606`
- E-mail: Já mascarado via `mask_email` (`c****@gmail.com`).

### C. Exigência de Desafio Anti-Bot (Turnstile)
- Requisições para criar agendamentos (`POST /public/appointments`) e para consultar por telefone (`GET /public/appointments/by-phone`) passam a exigir o cabeçalho `X-Turnstile-Token`.
- Scripts como Insomnia/Postman/cURL sem o token válido da Cloudflare são rejeitados imediatamente com `403 Forbidden`:
  ```json
  {
    "error": "BOT_DETECTION_TRIGGERED",
    "message": "Validação de segurança anti-bot obrigatória para consultas públicas."
  }
  ```

---

## 3. Implementação Proposta no Endpoint

```python
@router.get("/by-phone", response_model=list[AppointmentPublicResponse])
def get_public_appointments_by_phone(
    request: Request,
    barbershop_id: UUID = Query(...),
    phone: str = Query(..., min_length=8),
    db: Session = Depends(get_db),
    _captcha: None = Depends(require_turnstile_token), # Dependência anti-bot
    _rate_limit: None = Depends(rate_limit_phone_lookup), # Rate limiter por IP/Telefone
):
    ...
```

---

## 4. Teste e Validação

- Testes de integração em `tests/test_routes.py`:
  - Chamada sem cabeçalho `X-Turnstile-Token` -> `403 Forbidden`.
  - 6 chamadas rápidas com o mesmo telefone -> `429 Too Many Requests`.
