# 🔴 [VULN-01] [CRÍTICO] Bypass Total de Assinatura Criptográfica JWT em Rotas Administrativas e Impersonate

| Metadado | Detalhe |
|---|---|
| **ID da Vulnerabilidade** | `VULN-01` |
| **Status da Correção** | [x] ✅ **CORRIGIDO E VALIDADO** (2026-09-28) |
| **Severidade** | 🚨 **CRÍTICA (CVSS 10.0)** |
| **CVSS v3.1 Vector** | `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H` |
| **Classificação CWE** | [CWE-347: Improper Verification of Cryptographic Signature](https://cwe.mitre.org/data/definitions/347.html) / [CWE-287: Improper Authentication](https://cwe.mitre.org/data/definitions/287.html) |
| **Componentes Afetados** | [`fase_09_hairdule_barbershop_service/src/routes/admin.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_09_hairdule_barbershop_service/src/routes/admin.py#L38-L93) |
| **Endpoints Expostos** | `POST /admin/impersonate`, `GET /admin/barbershops`, `PUT /admin/barbershops/{id}/status`, `GET /admin/analytics/overview`, `GET /admin/analytics/risk-radar`, `GET /admin/appointments/lookup`, `GET /admin/audit-logs`, `GET /admin/barbershops/{id}` |

---

## 1. Descrição Técnica da Falha

No arquivo [`fase_09_hairdule_barbershop_service/src/routes/admin.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_09_hairdule_barbershop_service/src/routes/admin.py#L38-L93), a função `verify_admin_token` é responsável por autenticar e autorizar requisições que chegam aos endpoints administrativos de governança e suporte da plataforma.

A implementação atual realiza a extração do token JWT do cabeçalho `Authorization: Bearer <token>` e processa o payload da seguinte forma:

```python
# Trecho de admin.py (Linhas 47 a 56)
token = auth_header.split(" ", 1)[1].strip()
try:
    parts = token.split(".")
    if len(parts) < 2:
        raise ValueError("Token JWT malformado")

    payload_b64 = parts[1]
    padded = payload_b64 + "=" * (-len(payload_b64) % 4)
    claims = json.loads(base64.urlsafe_b64decode(padded.encode()).decode())
    
    # Valida apenas o conteúdo do JSON decodificado:
    raw_groups = claims.get("cognito:groups", [])
    ...
    role = str(claims.get("role", "")).upper()
    is_internal = bool(claims.get("is_internal_admin", False))
```

### O Defeito Crítico:
A função **nunca chama `jwt.decode`**, **nunca valida a assinatura criptográfica** (nem contra a chave simétrica do `jwt_handler`, nem contra as chaves públicas JWKS do Cognito User Pool), e **não valida a expiração do token (`exp`)**. Ela simplesmente divide a string no ponto (`.`) e faz a decodificação em Base64 do bloco central (payload).

---

## 2. Cenário de Ataque e Exploração Teórica

Como os tokens JWT são compostos por `Header.Payload.Signature` codificados em Base64URL, qualquer pessoa no mundo pode criar um JSON com valores arbitrários e utilizá-lo contra o sistema.

### Vetor Teórico de Exploração:
1. **Montagem do Payload Forjado**:
   O atacante cria um payload JSON com privilégios máximos:
   ```json
   {
     "sub": "attacker-id",
     "email": "attacker@evil.com",
     "role": "SUPER_ADMIN",
     "is_internal_admin": true,
     "cognito:groups": ["SUPER_ADMIN"]
   }
   ```
2. **Codificação**:
   O atacante gera uma string com um header qualquer, o payload acima codificado em base64url e qualquer assinatura falsa:
   `eyJhbGciOiJub25lIn0.<payload_base64>.fake_signature`
3. **Disparo contra `POST /admin/impersonate`**:
   O atacante envia uma requisição HTTP para a rota de impersonate:
   - Header: `Authorization: Bearer <token_forjado>`
   - Body: `{"barbershop_id": "<UUID_DA_BARBEARIA_ALVO>"}`
4. **Execução do Impersonate**:
   - `verify_admin_token` aceita o token forjado, acreditando que o remetente é um `SUPER_ADMIN`.
   - A função `create_impersonate_session` busca o proprietário da barbearia alvo no banco de dados e invoca `jwt_handler.create_access_token(...)`.
   - O backend responde com um **JWT 100% legítimo, com assinatura válida do sistema**, concedendo cargo de `OWNER` sobre a barbearia alvo.
5. **Comprometimento Total**:
   Com esse token legítimo retornado pelo próprio backend, o invasor tem acesso total aos dados financeiros, catálogo de clientes, agendamentos, equipe, serviços e faturamento do estabelecimento.

---

## 3. Impacto de Negócio e de Segurança

- **Quebra Total de Isolamento Multi-tenant**: Qualquer barbearia da base pode ter seus dados roubados ou manipulados.
- **Risco de Conformidade e LGPD**: Exfiltração em massa de dados cadastrais de clientes e profissionais (telefones, e-mails, históricos de atendimento).
- **Sabotagem Operacional**: Possibilidade de suspender estabelecimentos legítimos via `PUT /admin/barbershops/{barbershop_id}/status`.
- **CVSS 10.0**: Impacto máximo em Confidencialidade, Integridade e Disponibilidade sem exigir privilégios prévios.

---

## 4. Plano de Remediação Recomendado

### Passo 1: Utilizar Validação Criptográfica Rigorosa
Modificar `verify_admin_token` para validar tokens via Cognito JWKS oficial ou através do `jwt_handler.decode_token(token)` quando for token interno.

Exemplo de implementação defensiva recomendada:

```python
from hairdule_shared.auth.jwt_handler import jwt_handler
from hairdule_shared.errors.app_error import UnauthorizedError, ForbiddenError
import jwt

def verify_admin_token(request: Request, min_role: str = "SUPPORT_ADMIN") -> dict[str, Any]:
    auth_header = request.headers.get("Authorization") or request.headers.get("authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise UnauthorizedError(
            message="Credencial de autenticação administrativa ausente",
            code="MISSING_TOKEN",
        )

    token = auth_header.split(" ", 1)[1].strip()

    try:
        # 1. Validação Criptográfica Obrigatória da Assinatura e Expiração
        # Se os tokens vierem do Cognito Admin Client (RS256): validar via Cognito JWKS
        # Se os tokens vierem do JWT Handler interno (HS256): validar via jwt_handler.decode_token
        claims = jwt_handler.decode_token(token)
    except Exception as exc:
        # Se falhar no handler interno, tentar validar como Cognito JWT com chaves públicas da AWS
        claims = _verify_cognito_admin_jwt(token)

    # 2. Validação estrita de permissões de RBAC
    role = str(claims.get("role", "")).upper()
    is_internal = bool(claims.get("is_internal_admin", False))
    groups = set(claims.get("cognito:groups", []))

    if not (is_internal or any(g in ADMIN_ROLES for g in groups) or role in ADMIN_ROLES):
        raise ForbiddenError("Acesso restrito a administradores", code="FORBIDDEN_ADMIN_ONLY")

    if min_role == "SUPER_ADMIN" and not (is_internal or "SUPER_ADMIN" in groups or role == "SUPER_ADMIN"):
        raise ForbiddenError("Privilégio SUPER_ADMIN obrigatório", code="FORBIDDEN_SUPER_ADMIN_REQUIRED")

    return claims
```

### Passo 2: Implementar Autenticação no API Gateway
Adicionar um Cognito Authorizer específico na rota `/admin/*` no SST v4 (`fase_07_hairdule_infra_api`), impedindo que requisições com tokens forjados sequer alcancem a função Lambda.

---

## 5. Evidência da Correção Aplicada

- **Arquivo Modificado**: [`fase_09_hairdule_barbershop_service/src/routes/admin.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_09_hairdule_barbershop_service/src/routes/admin.py)
- **Implementação**:
  - A rotina insegura `parts[1]` e Base64 decodificada foi completamente erradicada.
  - O método `verify_admin_token` agora exige obrigatoriamente validação criptográfica via `jwt_handler.decode_token(token)` (com suporte a fallback em RS256 com `jwks_client` do AWS Cognito).
  - Adicionado suporte a chaves públicas JWKS em cache para o User Pool Cognito.
  - Testes unitários atualizados em `tests/unit/test_admin.py` gerando tokens assinados criptograficamente com sucesso total.
- **Resultado dos Testes**: `17 passed` em `test_admin.py`.

