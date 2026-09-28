# 🟠 [VULN-03] [ALTO] Endpoints Internos de Notificação e Purge Abertos na Internet sem Autenticação

| Metadado | Detalhe |
|---|---|
| **ID da Vulnerabilidade** | `VULN-03` |
| **Status da Correção** | [x] ✅ **CORRIGIDO E VALIDADO** (2026-09-28) |
| **Severidade** | 🔶 **ALTA (CVSS 8.6)** |
| **CVSS v3.1 Vector** | `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:H/A:H` |
| **Classificação CWE** | [CWE-306: Missing Authentication for Critical Function](https://cwe.mitre.org/data/definitions/306.html) / [CWE-668: Exposure of Resource to Wrong Lansing/Sphere](https://cwe.mitre.org/data/definitions/668.html) |
| **Componentes Afetados** | [`fase_24_hairdule_notification_service/src/dependencies.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_24_hairdule_notification_service/src/dependencies.py#L33-L46)<br>[`fase_24_hairdule_notification_service/src/routes/internal.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_24_hairdule_notification_service/src/routes/internal.py#L24-L74)<br>[`fase_07_hairdule_infra_api/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/sst.config.ts#L428) |
| **Endpoints Expostos** | `POST /internal/notify` e `POST /internal/purge` |

---

## 1. Descrição Técnica da Falha

No microsserviço de notificações ([`fase_24_hairdule_notification_service`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_24_hairdule_notification_service)), existem endpoints sob o prefixo `/internal` destinados à comunicação entre serviços (por exemplo, quando o serviço de agendamentos cria uma notificação para um profissional):
- `POST /internal/notify`: cria notificação in-app e despacha Web Push VAPID para os navegadores cadastrados.
- `POST /internal/purge`: expurga fisicamente do banco de dados registros de notificações antigas.

Ambos utilizam a dependência `verify_internal_key`:

```python
# Trecho de fase_24_hairdule_notification_service/src/dependencies.py (Linhas 33-46)
def verify_internal_key(
    x_internal_key: str | None = Header(None, alias="X-Internal-Key"),
) -> bool:
    """Valida a chave de autenticação interna entre microsserviços."""
    expected_key = os.getenv("INTERNAL_API_KEY")
    if os.getenv("ENVIRONMENT") == "test":
        return True
    if expected_key:
        if not x_internal_key or x_internal_key != expected_key:
            raise ForbiddenError(
                message="Chave de autenticação interna inválida ou ausente.",
                code="INVALID_INTERNAL_KEY",
            )
    return True
```

### O Defeito de Validação e Exposição:
1. **Lógica Falha se a Chave Estiver Ausente**: O código faz `if expected_key:`. Se a variável de ambiente `INTERNAL_API_KEY` for nula ou não estiver configurada no runtime Lambda, a condição `if expected_key` é avaliada como `False`, **e a função retorna `True` incondicionalmente**.
2. **Ausência da Variável no IaC e no AWS Staging**: Verificamos a configuração da Lambda no AWS Staging (`hairdule-notification-service-staging`) e no `sst.config.ts` da Fase 24: a variável `INTERNAL_API_KEY` **não está configurada**.
3. **Roteamento Público no API Gateway**: No arquivo [`fase_07_hairdule_infra_api/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/sst.config.ts#L428), a rota `POST /internal/notify` foi publicada diretamente na raiz pública da API sem autorizador JWT nem restrição de IP.

---

## 2. Cenário de Ataque e Exploração Teórica

### Vetor Teórico de Exploração:
1. **Reconhecimento**: Um atacante inspeciona os endpoints públicos do API Gateway ou o código do cliente e descobre a rota `POST /internal/notify`.
2. **Disparo de Mensagens Forjadas**:
   O atacante envia uma requisição HTTP `POST` para `https://<api-endpoint>/internal/notify` com um payload contendo:
   ```json
   {
     "barbershop_id": "<UUID_DA_BARBEARIA>",
     "user_id": "<UUID_DO_USUARIO_ALVO>",
     "type_code": "APPOINTMENT_CANCELLED",
     "title": "Aviso de Segurança Urgente",
     "message": "Sua assinatura foi bloqueada. Acesse https://phishing-site.com para regularizar.",
     "payload": {"link": "https://phishing-site.com"}
   }
   ```
3. **Execução sem Autenticação**:
   Como `INTERNAL_API_KEY` é nula no ambiente, o endpoint aceita a requisição com status `201 Created`.
4. **Disparo em Massa de Web Push**:
   A Lambda cria a notificação no PostgreSQL e aciona o motor Web Push VAPID RFC 8292, fazendo aparecer um alerta nativo no sistema operacional/dispositivo móvel do profissional ou proprietário.
5. **Expurgo de Evidências via `/internal/purge`**:
   O invasor pode chamar `POST /internal/purge?read_days=1&unread_days=1` para apagar notificações anteriores e ocultar rastros de adulteração.

---

## 3. Impacto de Negócio e de Segurança

- **Vetor de Phishing e Engenharia Social Crítico**: Mensagens oficiais e notificações push da própria plataforma Hairdule podem ser forjadas para induzir donos e colaboradores a clicarem em links maliciosos ou realizarem pagamentos falsos.
- **Poluição e Negação de Serviço**: Disparo massivo de notificações pode sobrecarregar o banco de dados Aurora ou exceder cotas do serviço Web Push (FCM / Mozilla Push).
- **Destruição de Dados**: Exclusão prematura de notificações e auditorias através da rota de purge.

---

## 4. Plano de Remediação Recomendado

### Passo 1: Bloqueio Padrão (Fail-Closed) na Validação da Chave
Modificar `verify_internal_key` para falhar obrigatoriamente se a chave interna não estiver configurada no ambiente:

```python
# Em fase_24_hairdule_notification_service/src/dependencies.py

def verify_internal_key(
    x_internal_key: str | None = Header(None, alias="X-Internal-Key"),
) -> bool:
    """Valida a chave de autenticação interna com bloqueio fail-closed."""
    if os.getenv("ENVIRONMENT") == "test":
        return True

    expected_key = os.getenv("INTERNAL_API_KEY")
    if not expected_key or len(expected_key) < 32:
        logger.error("internal_api_key_not_configured_or_insecure")
        raise ForbiddenError(
            message="Serviço interno não configurado adequadamente",
            code="INTERNAL_AUTH_MISCONFIGURED",
        )

    if not x_internal_key or not secrets.compare_digest(x_internal_key, expected_key):
        raise ForbiddenError(
            message="Chave de autenticação interna inválida ou ausente.",
            code="INVALID_INTERNAL_KEY",
        )
    return True
```

### Passo 2: Remover Rotas Internas do API Gateway Público
Rotas com prefixo `/internal/*` nunca devem ser acessíveis pela internet.
No arquivo [`fase_07_hairdule_infra_api/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/sst.config.ts):
- **Remover** `"POST /internal/notify"` do array `notificationRoutes`.
- Microsserviços backend devem se comunicar internamente via chamada direta Lambda-to-Lambda (`boto3.client('lambda').invoke(...)`) ou via mensageria desacoplada (Amazon SQS / EventBridge), sem transitar pelo API Gateway público.

---

## 5. Evidência da Correção Aplicada

- **Arquivos Modificados**:
  - [`fase_24_hairdule_notification_service/src/dependencies.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_24_hairdule_notification_service/src/dependencies.py)
  - [`fase_07_hairdule_infra_api/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/sst.config.ts)
- **Implementação**:
  - A função `verify_internal_key` foi reescrita com padrão fail-closed: se a variável de ambiente `INTERNAL_API_KEY` não estiver definida ou for vazia, a requisição é sumariamente rejeitada com erro `403 Forbidden` (`INTERNAL_AUTH_MISCONFIGURED`).
  - Comparação da chave de autenticação interna utiliza `secrets.compare_digest` contra timing attacks.
  - A rota `"POST /internal/notify"` foi definitivamente removida da tabela de roteamento público do API Gateway HTTP (`fase_07_hairdule_infra_api/sst.config.ts`).

