# VULN-12 — Ausência de Rate Limiting por IP e Alvo (E-mail) no Endpoint de Login

> **Status:** [ ] 🔴 **Pendente de Correção**  
> **Severidade:** 🔶 **ALTA**  
> **CVSS v3.1:** 8.1 (`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N`)  
> **Repositório Afetado:** [`fase_06_hairdule_auth_service`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_06_hairdule_auth_service)  
> **Arquivo Alvo:** [`src/routes/login.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_06_hairdule_auth_service/src/routes/login.py)

---

## 1. Descrição da Vulnerabilidade

O endpoint `POST /auth/login` é responsável por autenticar usuários (donos de barbearia e equipe) via e-mail e senha. 

Atualmente, não existe nenhum controle de taxa na camada da aplicação FastAPI:
- Não há limite no número de tentativas vindas do mesmo IP.
- Não há controle de bloqueio se o invasor usar uma rede de **IPs dinâmicos / proxies residenciais rotativos** para atacar o mesmo e-mail (Target-based Brute Force).
- Não há proteção contra ataques de **Password Spraying** (testar senhas comuns contra múltiplos e-mails conhecidos).

Embora o AWS Cognito aplique um bloqueio temporário após falhas sucessivas em um único usuário, ele não protege contra ataques distribuídos nem impede a sobrecarga dos recursos de banco e Lambda.

---

## 2. Cenário de Ataque

```
[ Atacante com Pool de Proxies / Botnet ]
       │
       ▼ (1.000 requisições/minuto, cada uma com um IP residencial diferente)
[ POST /auth/login (email=alvo@barbearia.com, password=dicionario) ]
       │
       ▼ (Backend não possui rate limiter por alvo)
[ Invoca Cognito InitiateAuth + consulta no Aurora PostgreSQL para cada request ]
       │
       ▼
[ Esgota pool de conexões do banco de dados ou compromete a conta da vítima ]
```

---

## 3. Evidência no Código Atual

Arquivo: `fase_06_hairdule_auth_service/src/routes/login.py`:
- Nenhuma dependência ou middleware de rate limiting é invocado na assinatura da rota `def login(payload: LoginRequest, ...):`.
- Cada requisição processa a autenticação imediatamente.

---

## 4. Solução Técnica Proposta

Implementar uma estratégia de **Defesa Multidimensional contra IP Dinâmico**:

1. **Rate Limiting por IP (`X-Forwarded-For`):**
   - Máximo de **10 tentativas a cada 5 minutos por IP**.
2. **Target-Based Throttling (Rate Limit por E-mail):**
   - Máximo de **5 falhas de senha em 5 minutos para o mesmo e-mail**, independentemente de terem sido disparadas por IPs diferentes.
   - Após a 5ª falha, o e-mail entra em período de resfriamento (*cooldown*) de 15 minutos, retornando `HTTP 429 Too Many Requests`.
3. **Cabeçalho de Resposta:**
   ```http
   HTTP/1.1 429 Too Many Requests
   Retry-After: 300

   {
     "error": "TOO_MANY_ATTEMPTS",
     "message": "Muitas tentativas de acesso incorretas. Aguarde 5 minutos antes de tentar novamente."
   }
   ```

---

## 5. Checklist de Implementação & Validação

- [ ] Criar middleware ou dependência de rate limit em memória / cache no `fase_06_hairdule_auth_service`.
- [ ] Aplicar no endpoint `POST /auth/login`.
- [ ] Validar que 6 tentativas consecutivas com senha errada resultam em `429 Too Many Requests` com cabeçalho `Retry-After`.
- [ ] Validar que após o período de cooldown o login legítimo funciona perfeitamente.
