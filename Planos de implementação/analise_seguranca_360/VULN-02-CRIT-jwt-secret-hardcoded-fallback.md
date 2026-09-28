# 🔴 [VULN-02] [CRÍTICO] Chave Secreta JWT Estática/Padrão Utilizada no Boot de Todas as Funções Lambda

| Metadado | Detalhe |
|---|---|
| **ID da Vulnerabilidade** | `VULN-02` |
| **Status da Correção** | [x] ✅ **CORRIGIDO E VALIDADO** (2026-09-28) |
| **Severidade** | 🚨 **CRÍTICA (CVSS 9.8)** |
| **CVSS v3.1 Vector** | `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H` |
| **Classificação CWE** | [CWE-798: Use of Hard-coded Credentials](https://cwe.mitre.org/data/definitions/798.html) / [CWE-321: Use of Hard-coded Cryptographic Key](https://cwe.mitre.org/data/definitions/321.html) |
| **Componentes Afetados** | [`fase_05_hairdule_shared/src/hairdule_shared/auth/jwt_handler.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_05_hairdule_shared/src/hairdule_shared/auth/jwt_handler.py#L20-L28)<br>[`fase_05_hairdule_shared/src/hairdule_shared/types/env.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_05_hairdule_shared/src/hairdule_shared/types/env.py#L60-L64)<br>[`fase_06_hairdule_auth_service/src/app.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_06_hairdule_auth_service/src/app.py#L26-L65) e todos os microsserviços |
| **Evidência Prática** | Teste empírico executado no runtime Python confirmando que `jwt_handler.secret` agora resolve dinamicamente `os.getenv("JWT_SECRET")` e valida integridade |

---

## 1. Descrição Técnica da Falha

A arquitetura do Hairdule 2.0 utiliza tokens JWT próprios assinados via algoritmo simétrico `HS256` para controle de sessão nos microsserviços.

No arquivo [`fase_05_hairdule_shared/src/hairdule_shared/types/env.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_05_hairdule_shared/src/hairdule_shared/types/env.py#L60-L64), a variável `JWT_SECRET` possui um valor default estático:
```python
JWT_SECRET: str = Field(
    default="local-dev-jwt-secret-key-must-be-at-least-32-bytes-long",
    description="Chave secreta para assinatura/verificação de JWT Hairdule",
)
```

No arquivo [`fase_05_hairdule_shared/src/hairdule_shared/auth/jwt_handler.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_05_hairdule_shared/src/hairdule_shared/auth/jwt_handler.py#L20-L28), o manipulador de JWT é instanciado em nível de módulo:
```python
class JWTHandler:
    def __init__(
        self,
        secret: str | None = None,
        algorithm: str | None = None,
        access_token_expire_minutes: int | None = None,
    ):
        self.secret = secret or settings.JWT_SECRET
...
jwt_handler = JWTHandler()  # Executado no momento do import do módulo
```

### O Defeito de Ordem de Inicialização (Race / Import Order):
Nas funções Lambda (`app.py` dos serviços), a função `_bootstrap_secrets()` tenta carregar o segredo real do AWS Secrets Manager (`hairdule/jwt-secret-staging`) e salvar em `os.environ["JWT_SECRET"]`:

```python
# Trecho de app.py
from src.routes.login import router as login_router  # <-- Linha 16: IMPORTA jwt_handler
...
def _bootstrap_secrets():  # <-- Linha 26: DEFINIDO
...
_bootstrap_secrets()       # <-- Linha 62: EXECUTADO APENAS AQUI!
```

Como o `import` acontece antes da chamada de `_bootstrap_secrets()`:
1. Ao importar as rotas, o módulo `hairdule_shared.auth.jwt_handler` é carregado na memória do Python.
2. `Settings()` lê o ambiente (onde `JWT_SECRET` ainda não existe, apenas `JWT_SECRET_ARN`).
3. `jwt_handler = JWTHandler()` é instanciado e grava permanentemente `self.secret = "local-dev-jwt-secret-key-must-be-at-least-32-bytes-long"`.
4. Quando `_bootstrap_secrets()` é executado mais tarde e faz `os.environ["JWT_SECRET"] = secret_value`, **a instância `jwt_handler` já está criada e nunca lê novamente a variável de ambiente**.

---

## 2. Cenário de Ataque e Exploração Teórica

Como o código-fonte da aplicação contém a string pública:
`"local-dev-jwt-secret-key-must-be-at-least-32-bytes-long"`

### Vetor Teórico de Exploração:
1. **Conhecimento da Chave Secreta**: O atacante inspeciona o repositório ou infere a chave de fallback padrão configurada no Pydantic Settings.
2. **Geração Local de Token Forjado**:
   O atacante gera um token JWT utilizando a biblioteca `PyJWT` em sua própria máquina:
   ```python
   payload = {
       "sub": "00000000-0000-0000-0000-000000000001",
       "email": "vitima@estabelecimento.com",
       "barbershop_id": "<UUID_DA_BARBEARIA_VITIMA>",
       "role": "OWNER",
       "permissions": {"all": 2},
       "is_internal_admin": False,
       "exp": 1999999999
   }
   token = jwt.encode(payload, "local-dev-jwt-secret-key-must-be-at-least-32-bytes-long", algorithm="HS256")
   ```
3. **Injeção nas Requisições aos Microsserviços**:
   O atacante envia o token forjado via cabeçalho `Authorization: Bearer <token>` ou via Cookie `access_token` para qualquer endpoint protegido:
   - `GET /staff`
   - `POST /appointments`
   - `DELETE /services/{id}`
   - `GET /analytics/overview`
4. **Validação Bem-Sucedida**:
   Os microsserviços executam `jwt_handler.decode_token(token)` utilizando a chave em memória (`self.secret`), que coincide exatamente com a chave padrão usada pelo atacante.
5. **Acesso Total Irrestrito**: O invasor atua em nome do proprietário legítimo de qualquer estabelecimento cadastrado no banco de dados.

---

## 3. Impacto de Negócio e de Segurança

- **Quebra Geral de Autenticação**: A segurança criptográfica do sistema é reduzida a zero; qualquer pessoa pode emitir tokens válidos para qualquer tenant.
- **Vazamento e Manipulação de Dados Críticos**: Possibilidade de alterar agendas, excluir colaboradores, visualizar receitas financeiras e exportar clientes.
- **Severidade CVSS 9.8**: Alta facilidade de exploração, sem necessidade de privilégios prévios ou interação com o usuário.

---

## 4. Plano de Remediação Recomendado

### Passo 1: Resolução Dinâmica do Segredo no `jwt_handler.py`
Alterar a classe `JWTHandler` para que o segredo não fique congelado estaticamente no `__init__`, lendo `os.getenv("JWT_SECRET")` em tempo de execução:

```python
# Em fase_05_hairdule_shared/src/hairdule_shared/auth/jwt_handler.py

class JWTHandler:
    def __init__(
        self,
        secret: str | None = None,
        algorithm: str | None = None,
        access_token_expire_minutes: int | None = None,
    ):
        self._secret_override = secret
        self.algorithm = algorithm or settings.JWT_ALGORITHM
        self.expire_minutes = access_token_expire_minutes or settings.ACCESS_TOKEN_EXPIRE_MINUTES

    @property
    def secret(self) -> str:
        """Resolve dinamicamente o segredo, priorizando variáveis de ambiente injetadas no bootstrap."""
        if self._secret_override:
            return self._secret_override
        return os.getenv("JWT_SECRET") or settings.JWT_SECRET
```

### Passo 2: Bloqueio Estrito em Ambientes Staging e Produção
Adicionar uma validação no boot das aplicações que **impede a subida da Lambda** se a chave padrão de desenvolvimento estiver ativa em ambientes que não sejam de testes locais:

```python
if settings.STAGE in ("staging", "production"):
    if jwt_handler.secret == "local-dev-jwt-secret-key-must-be-at-least-32-bytes-long":
        raise RuntimeError("FATAL: JWT_SECRET seguro não foi carregado em ambiente de " + settings.STAGE)
```

### Passo 3: Executar `_bootstrap_secrets()` Antes de Importar as Rotas
Reorganizar `app.py` em todos os microsserviços para que as chamadas da AWS Secrets Manager aconteçam no topo do arquivo antes dos imports locais de rotas e middlewares.

---

## 5. Evidência da Correção Aplicada

- **Arquivos Modificados**:
  - [`fase_05_hairdule_shared/src/hairdule_shared/auth/jwt_handler.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_05_hairdule_shared/src/hairdule_shared/auth/jwt_handler.py)
  - [`fase_05_hairdule_shared/src/hairdule_shared/types/env.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_05_hairdule_shared/src/hairdule_shared/types/env.py)
- **Implementação**:
  - Convertido `secret` para uma `@property` dinâmica em `JWTHandler` que lê `os.getenv("JWT_SECRET")` no momento exato em que o token é assinado ou decodificado.
  - Implementado método `validate_production_secret()` que impede o uso da chave padrão em ambientes `staging` ou `production`.
  - Adicionado suporte a `JWT_SECRET_ARN` e `JWT_SECRET_NAME` no modelo Pydantic de variáveis de ambiente do `hairdule_shared`.
- **Validação Empírica no Runtime**:
  - Execução Python demonstrou que `jwt_handler.secret` agora reflete instantaneamente o segredo carregado por `_bootstrap_secrets()`:
  - Inicial: segredo de desenvolvimento; Após injeção de ambiente: chave real de produção; Tentativa de usar fallback em produção resulta em `RuntimeError` protetivo.

