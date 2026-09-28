# 🛡️ Plano de Implementação: Integração com Cloudflare Turnstile (CAPTCHA Invisível)

> **Status:** 📋 Pronto para Execução  
> **Prioridade:** 🔶 Média-Alta (Defesa Zero Friction para o Usuário)  
> **Repositórios Afetados:** `fase_08_hairdule_ui_web` (Frontend Angular 19) e `fase_05_hairdule_shared` (Validador Python)

---

## 1. Por que Cloudflare Turnstile?

O **Cloudflare Turnstile** é a alternativa moderna da indústria ao Google reCAPTCHA. 
- **Invisível por padrão:** O cliente legítimo não resolve quebra-cabeças nem clica em imagens; o navegador valida desafios criptográficos silenciosos em milissegundos.
- **100% Gratuito:** Sem limites de requisições ou cobranças por mil chamadas.
- **Privacidade total:** Não monitora cookies de terceiros nem histórico de navegação como o Google.
- **Suporte Oficial a Ambientes de Teste / CI/CD:** A Cloudflare disponibiliza chaves de teste oficiais que sempre aprovam ou reprovam, permitindo que a esteira de CI/CD continue 100% verde sem gambiarras.

---

## 2. Arquitetura da Solução

```
[ Usuário no Angular 19 ]
       │
       ├─► Turnstile SDK executa desafio invisível em background
       │   Gera: cf_turnstile_token
       │
       ▼
[ Requisição HTTP para API Gateway ]
       │   Headers: { "X-Turnstile-Token": "0.xxxxxxx" }
       │
       ▼
[ FastAPI / Lambda do Microsserviço ]
       │
       ├─► Chama POST https://challenges.cloudflare.com/turnstile/v0/siteverify
       │   com: { secret: TURNSTILE_SECRET_KEY, response: token, remoteip: ip }
       │
       ├── Se sucesso (success: true) ──► Processa requisição normalmente (200/201)
       └── Se falha ou ausente        ──► Rejeita imediatamente com 403 Forbidden
```

---

## 3. Implementação no Backend Compartilhado (`fase_05_hairdule_shared`)

Criar o helper em `hairdule_shared/security/turnstile.py`:

```python
import os
import httpx
import structlog
from fastapi import Header, HTTPException, Request, status

logger = structlog.get_logger(__name__)

TURNSTILE_SECRET_KEY = os.getenv(
    "TURNSTILE_SECRET_KEY",
    "1x0000000000000000000000000000000AA"  # Chave oficial Cloudflare Always Pass para dev/test
)
TURNSTILE_VERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

async def verify_turnstile_token(
    request: Request,
    x_turnstile_token: str | None = Header(None, alias="X-Turnstile-Token")
) -> bool:
    """Valida o token do Cloudflare Turnstile recebido no header."""
    # Em ambiente de teste automatizado local, se desabilitado explicitamente, ignora
    if os.getenv("DISABLE_CAPTCHA_CHECK", "false").lower() == "true":
        return True

    if not x_turnstile_token:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Validação de segurança anti-bot (CAPTCHA) obrigatória.",
        )

    client_ip = request.headers.get("x-forwarded-for", "").split(",")[0].strip() or request.client.host

    try:
        async with httpx.AsyncClient(timeout=4.0) as client:
            resp = await client.post(
                TURNSTILE_VERIFY_URL,
                data={
                    "secret": TURNSTILE_SECRET_KEY,
                    "response": x_turnstile_token,
                    "remoteip": client_ip,
                },
            )
            result = resp.json()

        if not result.get("success", False):
            logger.warning("Falha na validação do Turnstile", ip=client_ip, error_codes=result.get("error-codes"))
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Desafio de segurança anti-bot falhou. Tente novamente.",
            )

        return True
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("Erro ao contatar API do Turnstile", error=str(exc))
        # Fail-closed ou tolerante de acordo com a política
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Erro ao validar desafio de segurança.",
        )
```

---

## 4. Implementação no Frontend (`fase_08_hairdule_ui_web`)

1. **Adicionar o script no `index.html`:**
   ```html
   <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit" async defer></script>
   ```

2. **Criar Componente Angular Standalone (`turnstile.component.ts`):**
   - Renderiza o widget invisível (`render(..., { sitekey: '...', callback: (t) => ... })`).
   - Emite o token obtido para o formulário pai.

3. **Injetar o Token no Interceptor HTTP:**
   - Adiciona o cabeçalho `X-Turnstile-Token` nas chamadas aos endpoints protegidos (`/public/appointments`, `/public/appointments/by-phone`, `/auth/forgot-password`).

---

## 5. Testes e Ambientes

- **Testes Unitários e CI:** Uso das chaves oficiais de teste da Cloudflare (`1x00000000000000000000AA` / `1x0000000000000000000000000000000AA`), que respondem `success: true` sem necessitar de navegador real.
- **Produção / Staging:** Criação da conta gratuita na Cloudflare e cadastro dos domínios `hairdule.com` e `d19dlqxhe17bcr.cloudfront.net`.
