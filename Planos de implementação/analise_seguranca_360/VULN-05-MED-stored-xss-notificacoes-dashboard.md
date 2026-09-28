# 🟡 [VULN-05] [MÉDIO] Injeção de Conteúdo e Risco de Stored XSS via Nome de Cliente no Painel de Notificações

| Metadado | Detalhe |
|---|---|
| **ID da Vulnerabilidade** | `VULN-05` |
| **Status da Correção** | [x] ✅ **CORRIGIDO E VALIDADO** (2026-09-28) |
| **Severidade** | 🟡 **MÉDIA (CVSS 6.8)** |
| **CVSS v3.1 Vector** | `CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N` |
| **Classificação CWE** | [CWE-79: Improper Neutralization of Input During Web Page Generation ('Cross-site Scripting')](https://cwe.mitre.org/data/definitions/79.html) |
| **Componentes Afetados** | [`fase_08_hairdule_ui_web/src/app/core/models/notification.models.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_08_hairdule_ui_web/src/app/core/models/notification.models.ts#L164-L240)<br>[`fase_08_hairdule_ui_web/src/app/features/notifications/components/notification-dropdown/notification-dropdown.component.html`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_08_hairdule_ui_web/src/app/features/notifications/components/notification-dropdown/notification-dropdown.component.html#L86)<br>[`fase_08_hairdule_ui_web/src/app/features/notifications/components/notification-list-item/notification-list-item.component.html`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_08_hairdule_ui_web/src/app/features/notifications/components/notification-list-item/notification-list-item.component.html#L22) |

---

## 1. Descrição Técnica da Falha

No portal público de agendamentos (`POST /public/appointments`), qualquer cliente da internet pode preencher o campo `customer_name`.

Quando o agendamento é criado, o sistema despacha uma notificação in-app que é consumida pelos dashboards do proprietário e dos profissionais na SPA Angular.

No arquivo [`fase_08_hairdule_ui_web/src/app/core/models/notification.models.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_08_hairdule_ui_web/src/app/core/models/notification.models.ts#L164-L240), a função `formatNotificationMessage` formata a mensagem concatenando diretamente o nome do cliente dentro de tags HTML sem sanitização de entidades (`<`, `>`, `"`, `'`):

```typescript
// Trecho de notification.models.ts (Linha 206)
return `O atendimento de <strong>${customerName}</strong> começa às ${time}! Tudo pronto para recebê-lo?`;
```

Em seguida, o template Angular renderiza essa string utilizando o property binding `[innerHTML]`:

```html
<!-- notification-dropdown.component.html (Linha 86) -->
<p class="item-message" [innerHTML]="formatMessage(item)"></p>

<!-- notification-list-item.component.html (Linha 22) -->
<p class="message" [innerHTML]="formattedMessage"></p>
```

### O Risco de Injeção:
Embora o Angular aplique o sanitizador nativo (`DomSanitizer`) em bindings de `[innerHTML]`, a injeção de HTML arbitrário não escapado introduz riscos sérios:
1. **Defacement e Phishing Interno**: O atacante pode injetar elementos HTML estilizados (como links falsos para telas de login ou botões de pagamento simulando notificações do sistema).
2. **Potencial de XSS (Cross-Site Scripting)**: Se houver qualquer falha em sanitizadores customizados ou combinações com tags e atributos não filtrados (e.g. formulários embutidos ou bypasses de SVG).
3. **Agravamento pelo Armazenamento em LocalStorage**: Caso um script seja executado no contexto do dashboard, ele terá acesso direto aos tokens de autenticação armazenados no `localStorage` (vide `VULN-06`).

---

## 2. Cenário de Ataque e Exploração Teórica

### Vetor Teórico de Exploração:
1. O atacante acessa o portal público de agendamento de uma barbearia.
2. Ao realizar uma reserva de corte, informa no campo `customer_name`:
   `Carlos <a href="https://malicious-login.com" style="color:red;font-weight:bold">URGENTE: Confirme seu acesso</a>`
3. O backend aceita o agendamento e gera a notificação para a equipe do salão.
4. Quando o barbeiro ou o proprietário abre a central de notificações no topo da navbar, a mensagem renderiza um link clicável adulterado em vermelho com aparência de alerta do sistema.
5. O operador clica no link e é direcionado para uma página clonada do Hairdule onde entrega suas credenciais.

---

## 3. Impacto de Negócio e de Segurança

- **Engenharia Social contra Operadores e Donos de Salão**: Possibilidade de induzir usuários privilegiados a visitar links maliciosos ou executar ações enganosas dentro do próprio sistema.
- **Risco de Roubo de Sessão**: Se o vetor permitir execução de script, viabiliza o roubo de tokens de acesso.

---

## 4. Plano de Remediação Recomendado

### Passo 1: Escapar Caracteres HTML Antes da Interpolação
Na função `formatNotificationMessage`, criar uma função utilitária para sanitizar entidades HTML do `customerName`:

```typescript
function escapeHtml(unsafe: string): string {
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

// Ao interpolar no texto:
const safeCustomerName = escapeHtml(customerName);
return `O atendimento de <strong>${safeCustomerName}</strong> começa às ${time}!`;
```

### Passo 2: Sanitizar Campos de Entrada no Backend (Pydantic Validator)
No schema [`AppointmentCreateRequest`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_17_hairdule_appointment_service/src/schemas/appointment.py), aplicar um validator que remove tags HTML e scripts de campos de texto livre (`customer_name` e `notes`).

---

## 5. Evidência da Correção Aplicada

- **Arquivo Modificado**: [`fase_08_hairdule_ui_web/src/app/core/models/notification.models.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_08_hairdule_ui_web/src/app/core/models/notification.models.ts)
- **Implementação**:
  - Implementada função utilitária `escapeHtml()` com conversão estrita de entidades `&`, `<`, `>`, `"`, `'`.
  - A função `formatNotificationMessage()` agora escapa obrigatoriamente `customerName` e todos os parâmetros dinâmicos interpolados (`escapeHtml(customerName)`) antes de inseri-los no template de interpolação HTML com `<strong>`.
  - Previne qualquer injeção de HTML malicioso, tags estruturais forjadas ou links de phishing no painel de notificações do dashboard Angular.

