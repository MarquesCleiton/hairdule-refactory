# 🖥️ Fase 08 — Dashboard Auth UI (Angular) (`fase_08_hairdule_ui_auth`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_08_hairdule_ui_auth`
> **Tecnologia:** Angular 19 + Angular Material — Telas de Autenticação do Dashboard
> **Porta Local:** `4300`
> **Dependências Diretas:** Fase 06 (auth-service rodando em `localhost:3001` ou via API Gateway Fase 07)
> **Última verificação:** 2026-08-16

---

## 🎯 Objetivo da Fase

A Fase 08 implementa **toda a camada de autenticação visual** do painel de gestão. É a interface do usuário para o dono da barbearia: a primeira tela que ele vê ao acessar `app.hairdule.com.br` ou `localhost:4300`.

Ela fecha o **Marco 1 de Entrega Testável E2E**: com as Fases 05 (Layer), 06 (Auth Service), 07 (API Gateway) e 08 (Auth UI) concluídas, o sistema possui um ciclo completo e funcional de cadastro, login, JWT e recuperação de conta.

---

## 🎨 Analogia — A Recepção e o Crachá

```
Usuário acessa app.hairdule.com.br (ou localhost:4300)
        │
        ▼
┌─────────────────────────────────────────────────────────────┐
│  Tela de Login   │  Tela de Cadastro  │  Recuperar Senha    │
│  (card central)  │  (formulário)      │  (email input)      │
│                  │                    │                      │
│  email + senha   │  nome + email +    │  "enviamos o link"  │
│  [Entrar]        │  senha + [Criar]   │                      │
└─────────────────────────────────────────────────────────────┘
        │ Sucesso
        ▼
  JWT armazenado no localStorage
  AuthInterceptor injeta Bearer em todas as requisições
  AuthGuard protege todas as rotas do dashboard
        │
        ▼
  Redirect para /onboarding (Fase 10) ou /dashboard (Fase 12+)
```

---

## ✅ Checklist Completo da Fase 08

### 🔗 1. Pré-requisitos

- [ ] Fase 06 funcional localmente (`http://localhost:3001/docs` acessível)
- [ ] Angular CLI 19 instalado (`ng version`)
- [ ] Node.js 22 LTS instalado

---

### 📁 2. Estrutura do Projeto Angular

- [ ] **`ng new hairdule-ui-auth --standalone --routing --style=scss`** executado
- [ ] **`@angular/material`** instalado (`ng add @angular/material`)
- [ ] **Tema customizado** configurado em `styles.scss`:
  - Cor primária: Aqua `#22BEF5`
  - Typography: `Outfit` (Google Fonts)
- [ ] **`proxy.conf.json`** configurado:
  ```json
  { "/api/auth": { "target": "http://localhost:3001", "pathRewrite": {"^/api": ""} } }
  ```
- [ ] **`angular.json`** com `proxyConfig: "proxy.conf.json"` em `serve`

---

### 🧱 3. Core — Infraestrutura de Auth

- [ ] **`core/auth/auth.service.ts`** — `AuthService`:
  - `login(email, password): Observable<TokenResponse>`
  - `signup(data): Observable<SignupResponse>`
  - `forgotPassword(email): Observable<void>`
  - `logout(): void` — limpa localStorage, redireciona para `/login`
  - `isAuthenticated(): boolean` — verifica token + expiração
  - `currentUser$: BehaviorSubject<CurrentUser | null>`
- [ ] **`core/auth/auth.guard.ts`** — `AuthGuard`:
  - `canActivate()` → redireciona para `/login` se não autenticado
  - `canActivateChild()` → protege rotas filhas
- [ ] **`core/auth/auth.interceptor.ts`** — `AuthInterceptor`:
  - Injeta `Authorization: Bearer <token>` em todas as requisições para `/api/`
  - Se 401 recebido → tenta refresh token → se falhar, faz logout
- [ ] **`core/http/api.service.ts`** — wrapper do `HttpClient` com base URL

---

### 🖼️ 4. Passo A — Página de Teste Simples

- [ ] **`features/auth-test/auth-test.component.ts`** — Página técnica de teste:
  - Formulário simples: email + senha + nome
  - Botões para cada endpoint: Signup, Login, Forgot Password, Refresh, Change Password
  - Exibe response bruta em `<pre>` (JSON formatado)
  - Exibe erros com código e mensagem
  - Testa 100% dos endpoints da Fase 06

---

### 🎨 5. Passo B — Telas Polidas Angular Material

- [ ] **`features/auth/login/login.component.ts`** — Tela de Login:
  - Card centralizado com glassmorphism
  - `mat-form-field` para email e senha
  - Validação em tempo real (email inválido, senha vazia)
  - Estado de loading no botão [Entrar]
  - Link "Esqueci minha senha" e "Criar conta"
- [ ] **`features/auth/signup/signup.component.ts`** — Tela de Cadastro:
  - Campos: Nome do Estabelecimento, Email, Senha, Confirmar Senha
  - Validação: email válido, senha mínimo 6 chars, senhas coincidem
  - Mensagem de erro tipada (409 email duplicado, etc.)
- [ ] **`features/auth/forgot-password/forgot-password.component.ts`**:
  - Input de email + botão "Enviar"
- [ ] **`features/auth/reset-password/reset-password.component.ts`**:
  - Lê token da URL query string e altera a senha

---

### 🧪 6. Validação Manual (Fluxo Completo E2E Marco 1)

- [ ] `ng serve --port 4300` → app roda em `http://localhost:4300`
- [ ] Signup → cria conta no DB + Cognito → gera JWT → redireciona
- [ ] Login → autentica → salva JWT no localStorage
- [ ] Rota protegida sem JWT → bloqueada pelo `AuthGuard`
- [ ] Logout limpa estado e volta para `/login`

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Pré-requisitos | 0 | 3 | **0%** ⬜ |
| Estrutura do Projeto Angular | 0 | 5 | **0%** ⬜ |
| Core Infra de Auth | 0 | 4 | **0%** ⬜ |
| Página de Testes Simples | 0 | 1 | **0%** ⬜ |
| Telas Angular Material (4 telas) | 0 | 4 | **0%** ⬜ |
| Validação E2E Marco 1 | 0 | 5 | **0%** ⬜ |
| **TOTAL** | **0** | **22** | **0%** ⬜ |

> **Status:** ⬜ Aguarda conclusão da Fase 07 (API Gateway).
