# 🛡️ Plano de Implementação: Proteção contra Brute-Force e Abuso no Auth Service

> **Status:** 📋 Pronto para Execução  
> **Prioridade:** 🔶 Alta  
> **Repositório Afetado:** `fase_06_hairdule_auth_service`  
> **Arquivos Alvo:** [`src/routes/login.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_06_hairdule_auth_service/src/routes/login.py), [`src/routes/forgot_password.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_06_hairdule_auth_service/src/routes/forgot_password.py), [`src/routes/signup.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_06_hairdule_auth_service/src/routes/signup.py)

---

## 1. Problema Identificado

1. **Ataques de Força Bruta e Credential Stuffing em `/auth/login`:**
   - O endpoint aceita requisições ilimitadas por IP. Atacantes com botnets ou proxies rotativos podem testar senhas comuns contra múltiplos e-mails simultaneamente (Password Spraying), contornando o bloqueio por usuário único do Cognito.
2. **Abuso de Disparo em `/auth/forgot-password` (Email Bombing):**
   - Não há limite no número de solicitações de recuperação para o mesmo e-mail ou originadas do mesmo IP, possibilitando sobrecarga do AWS SES e flood na caixa de entrada da vítima.
3. **Criação de Contas em Massa em `/auth/signup`:**
   - Bots podem inflar a base com cadastros fraudulentos de barbearias e usuários.

---

## 2. Solução Técnica Proposta

Implementar uma estratégia de controle de taxa na camada da aplicação (FastAPI), atuando sobre o **IP do cliente** (extraído com segurança de `X-Forwarded-For`) e sobre o **identificador de negócio** (e-mail):

### Regras de Taxa na Aplicação

1. **Login (`POST /auth/login`):**
   - Limite por IP: Máximo de **10 tentativas a cada 5 minutos**.
   - Limite por e-mail: Máximo de **5 falhas consecutivas a cada 5 minutos**.
   - Resposta em caso de violação:
     ```http
     HTTP/1.1 429 Too Many Requests
     Retry-After: 300

     {
       "error": "TOO_MANY_ATTEMPTS",
       "message": "Muitas tentativas de login incorretas. Por favor, tente novamente em 5 minutos."
     }
     ```
2. **Recuperação de Senha (`POST /auth/forgot-password`):**
   - Máximo de **3 solicitações a cada 15 minutos** por IP e por e-mail.
3. **Validação do Token Anti-Bot (Cloudflare Turnstile):**
   - `POST /auth/signup` e `POST /auth/forgot-password` passam a exigir o cabeçalho `X-Turnstile-Token`.
   - Se ausente ou inválido junto à API da Cloudflare, retorna `403 Forbidden` (`CAPTCHA_VALIDATION_FAILED`).

---

## 3. Implementação Proposta (Middleware / Dependency)

Criar em `fase_05_hairdule_shared` ou localmente em `src/dependencies.py`:

```python
# rate_limiter.py (Memória local efêmera da Lambda + DynamoDB/Redis para estado distribuído)
from collections import defaultdict
import time
from fastapi import Request, HTTPException, status

_IP_ATTEMPTS = defaultdict(list)

def rate_limit_ip(max_requests: int, window_seconds: int):
    def dependency(request: Request):
        client_ip = request.headers.get("x-forwarded-for", "").split(",")[0].strip() or request.client.host
        now = time.time()
        
        # Limpa histórico antigo
        _IP_ATTEMPTS[client_ip] = [t for t in _IP_ATTEMPTS[client_ip] if now - t < window_seconds]
        
        if len(_IP_ATTEMPTS[client_ip]) >= max_requests:
            retry_after = int(window_seconds - (now - _IP_ATTEMPTS[client_ip][0]))
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Muitas tentativas a partir deste IP. Aguarde antes de tentar novamente.",
                headers={"Retry-After": str(max(1, retry_after))}
            )
        
        _IP_ATTEMPTS[client_ip].append(now)
    return dependency
```

---

## 4. Teste e Validação

- Teste unitário simulando 6 tentativas consecutivas com credenciais incorretas e garantindo o retorno `429 Too Many Requests`.
- Validação de que usuários com credenciais válidas após o período de cooldown logam normalmente.
