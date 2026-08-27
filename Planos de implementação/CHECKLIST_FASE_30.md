# 💻 Fase 30 — Frontend: Telas de Redefinição de Senha & Primeiro Acesso com Termos LGPD (`fase_30_hairdule_ui_auth_email_flows`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_08_hairdule_ui_web`  
> **Tecnologia:** Angular 19 Standalone + Reactive Forms + Lucide Icons + Signals  
> **Dependências Diretas:** Fase 08 (Auth UI Base), Fase 29 (Backend Auth & Staff Flows)  
> **Última atualização:** 2026-08-26  

---

## 🎯 Objetivo da Fase

A Fase 30 implementa as **interfaces de usuário (UI/UX) responsivas** no Web Dashboard Angular 19 para os dois fluxos originados por e-mail:
1. **Redesign da Tela de Redefinição de Senha (`/auth/reset-password`)**: Atualizada para coincidir perfeitamente com [image-1.png](../Refatoracao/Recuperar-senha/image-1.png), com leitura automática de tokens via URL e validação em tempo real de requisitos de senha.
2. **Nova Tela de Primeiro Acesso (`/auth/first-access`)**: Interface dedicada conforme [image-3.png](../Refatoracao/Recuperar-senha/image-3.png) para alteração de senha temporária recebida por e-mail e aceite obrigatório dos Termos de Uso e Política de Privacidade (LGPD).

---

## 🎨 Especificação das Telas e Componentes

### 1. Tela de Redefinição de Senha (`/auth/reset-password`)
- Rota: `/auth/reset-password`
- Coincide com o layout de [image-1.png](../Refatoracao/Recuperar-senha/image-1.png):
  - **Título:** *Crie sua nova senha*
  - **Subtítulo:** *Digite uma nova senha segura para sua conta*
  - **Campo Nova senha:** input com botão de alternar visibilidade (olho).
  - **Checklist dinâmico de regras:**
    - `× / ✓` Mínimo de 8 caracteres
    - `× / ✓` Uma letra maiúscula
    - `× / ✓` Uma letra minúscula
    - `× / ✓` Um número
  - **Campo Confirmar nova senha:** input com botão de alternar visibilidade e indicador visual de correspondência.
  - **Botão:** *Redefinir senha* (habilita apenas quando todos os critérios forem atendidos).
  - **Link:** *← Voltar ao login*.

---

### 2. Tela de Primeiro Acesso (`/auth/first-access`)
- Rota: `/auth/first-access`
- Coincide com o layout de [image-3.png](../Refatoracao/Recuperar-senha/image-3.png):
  - **Banner Superior:** Faixa Aqua do Hairdule com tag *Alterar Senha*.
  - **Card de Instrução:**
    - `🛡️ Primeiro acesso`
    - *Por segurança, altere sua senha temporária para uma senha pessoal.*
  - **Campo Senha Temporária:** com máscara/toggle de visibilidade.
  - **Campo Nova Senha:** com regras de força e toggle de visibilidade.
  - **Campo Confirmar Nova Senha:** com toggle de visibilidade.
  - **Card de Consentimento LGPD:**
    - *📄 Antes de continuar, leia nossos termos:* Links interativos para **Termos de Uso** e **Política de Privacidade** (abre o modal `app-legal-dialog` existente).
    - Checkbox de seleção obrigatória: *Li e aceito os **Termos de Uso** e a **Política de Privacidade**.*
  - **Botão:** *Alterar Senha*.
  - **Link:** *🚪 Sair e voltar ao login*.

---

## ✅ Checklist Completo da Fase 30

### 🔄 1. Atualização do `AuthService` Angular

- [ ] Adicionar método `firstAccess(payload: FirstAccessRequest): Observable<AuthResponse>`
- [ ] Atualizar método `resetPassword(payload: ResetPasswordRequest): Observable<MessageResponse>`
- [ ] Atualizar interceptor / handler de login para detectar resposta `NEW_PASSWORD_REQUIRED` ou `must_change_password` e redirecionar automaticamente para `/auth/first-access`

---

### 🔐 2. Componente de Redefinição de Senha (`/auth/reset-password`)

- [ ] Atualizar `reset-password.component.html` e `.scss` para refletir o design limpo de `image-1.png`
- [ ] Capturar automaticamente `token` e `email` dos `queryParams` da URL
- [ ] Validações reativas com checklist interativo de requisitos de senha
- [ ] Integração com serviço de notificações toast para feedback de sucesso e erro

---

### 🛡️ 3. Novo Componente de Primeiro Acesso (`/auth/first-access`)

- [ ] Criar pasta `src/app/features/auth/first-access/` com:
  - `first-access.component.ts` (Standalone)
  - `first-access.component.html`
  - `first-access.component.scss`
  - `first-access.component.spec.ts`
- [ ] Implementar layout responsivo mobile-first idêntico a `image-3.png`
- [ ] Integrar com `LegalDialogComponent` para visualização dos textos completos de Termos e Privacidade
- [ ] Registrar rota `auth/first-access` no `app.routes.ts` com `guestGuard`

---

### 🧪 4. Testes e Validação Frontend

- [ ] Testes unitários Jasmine/Karma para `ResetPasswordComponent`
- [ ] Testes unitários Jasmine/Karma para `FirstAccessComponent`
- [ ] `npm run build` executado com sucesso e 0 erros de compilação
- [ ] Validação visual e de acessibilidade em resoluções Desktop e Mobile

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| AuthService & Rotas | 0 | 3 | 0% |
| Tela Reset Password | 0 | 4 | 0% |
| Tela Primeiro Acesso | 0 | 4 | 0% |
| Testes e Build | 0 | 4 | 0% |
| **TOTAL** | **0** | **15** | **0%** |
