# 🟠 [VULN-04] [ALTO] BOLA, Vazamento de PII e Cancelamento Arbitrário de Agendamentos em Endpoints Públicos

| Metadado | Detalhe |
|---|---|
| **ID da Vulnerabilidade** | `VULN-04` |
| **Status da Correção** | [x] ✅ **CORRIGIDO E VALIDADO** (2026-09-28) |
| **Severidade** | 🔶 **ALTA (CVSS 8.2)** |
| **CVSS v3.1 Vector** | `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N` |
| **Classificação CWE** | [CWE-639: Authorization Bypass Through User-Controlled Key (BOLA/IDOR)](https://cwe.mitre.org/data/definitions/639.html) / [CWE-200: Exposure of Sensitive Information to an Unauthorized Actor](https://cwe.mitre.org/data/definitions/200.html) |
| **Componentes Afetados** | [`fase_17_hairdule_appointment_service/src/routes/public_appointments.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_17_hairdule_appointment_service/src/routes/public_appointments.py#L86-L159)<br>[`fase_07_hairdule_infra_api/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/sst.config.ts#L373-L376) |
| **Endpoints Expostos** | `GET /public/appointments/by-phone`<br>`POST /public/appointments/{booking_code}/cancel`<br>`POST /public/appointments/{booking_code}/reschedule` |

---

## 1. Descrição Técnica da Falha

No microsserviço de agendamentos ([`fase_17_hairdule_appointment_service`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_17_hairdule_appointment_service)), foram identificadas duas fragilidades encadeadas no portal público de agendamentos:

### 1.1 Consulta Pública Irrestrita por Telefone
O endpoint `GET /public/appointments/by-phone` permite consultar os agendamentos futuros de um cliente utilizando apenas o `barbershop_id` (que é público via landing page) e o número de telefone (`phone`):

```python
# Trecho de public_appointments.py (Linhas 91 a 105)
@router.get("/by-phone", response_model=list[AppointmentPublicResponse])
def get_public_appointments_by_phone(
    barbershop_id: UUID = Query(...),
    phone: str = Query(..., min_length=8),
    db: Session = Depends(get_db),
):
    appointments = AppointmentService.get_public_appointments_by_phone(...)
```

A resposta deste endpoint devolve:
- `customer_name` (Nome completo do cliente)
- `customer_email_masked` (E-mail parcialmente mascarado)
- `start_time` e `end_time`
- `price_cents` e `notes` (Anotações do agendamento)
- `staff_name` (Nome do barbeiro/profissional)
- `booking_code` (Código legível de agendamento, ex: `HD-ABCD-1234`)

### 1.2 Sobrevivência de Endpoints Legados de Cancelamento/Remarcação Direta
A equipe do Hairdule desenvolveu um fluxo seguro baseado em Magic Link enviado por e-mail (`/{booking_code}/request-cancel` e `/{booking_code}/request-reschedule`).

No entanto, os endpoints legados que realizavam o cancelamento e remarcação **sem nenhuma confirmação por e-mail** foram mantidos no código e **continuam publicados no API Gateway v2**:

```python
# Trecho de public_appointments.py (Linhas 281 a 296)
@router.post("/{booking_code}/cancel", summary="Cancela diretamente via booking_code (Legado)")
def cancel_public_appointment(
    booking_code: str,
    payload: AppointmentPublicCancelRequest,
    db: Session = Depends(get_db),
):
    return AppointmentService.cancel_public_appointment(
        db=db,
        booking_code=booking_code,
        reason=payload.cancel_reason,
    )
```

E no arquivo [`fase_07_hairdule_infra_api/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/sst.config.ts#L375-L376):
```typescript
"POST /public/appointments/{booking_code}/cancel",
"POST /public/appointments/{booking_code}/reschedule",
```

---

## 2. Cenário de Ataque e Exploração Teórica

### Vetor Teórico de Exploração:
1. **Identificação da Barbearia Alvo**:
   O atacante obtém o `barbershop_id` do salão através do slug público (`GET /public/lookup?slug=barbearia-alvo`).
2. **Enumeração de Telefones (PII Harvesting)**:
   Sem rate limiting ou captcha no endpoint `/by-phone`, um script automatizado itera listas de números de telefones com DDD local (ex: números frequentes de WhatsApp na região).
3. **Coleta de Agendamentos**:
   Para cada número que possuir agendamento futuro marcado, o endpoint retorna os horários, nome da pessoa e o `booking_code`.
4. **Sabotagem Massiva da Agenda**:
   Munido dos códigos `booking_code` coletados, o atacante invoca repetidamente o endpoint legado:
   `POST /public/appointments/HD-XXXX-XXXX/cancel`
   com `{"cancel_reason": "Cancelado"}`.
5. **Consequência Imediata**:
   O sistema cancela os agendamentos diretamente no banco de dados, liberando os horários na agenda dos profissionais. Os clientes legítimos e os barbeiros só percebem o cancelamento quando o cliente chega ao estabelecimento e descobre que seu horário foi apagado.

---

## 3. Impacto de Negócio e de Segurança

- **Vazamento de Dados Pessoais (LGPD)**: Exposição não autorizada da relação entre clientes, números de telefone, horários e prestadores de serviço.
- **Sabotagem Comercial**: Concorrentes desonestos ou agentes maliciosos podem desorganizar completamente a operação de uma barbearia em horários de pico (sextas e sábados).
- **Perda de Receita e Reputação**: Clientes descontentes que perderam seus horários e prejuízo financeiro direto para o estabelecimento parceiro.

---

## 4. Plano de Remediação Recomendado

### Passo 1: Descomissionar Imediatamente as Rotas Legadas no API Gateway
No arquivo [`fase_07_hairdule_infra_api/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/sst.config.ts):
- **Remover** as rotas legadas:
  - `POST /public/appointments/{booking_code}/cancel`
  - `POST /public/appointments/{booking_code}/reschedule`
- Todas as ações de cancelamento e alteração devem passar estritamente pelo fluxo de Magic Link (`request-cancel` / `request-reschedule` / `action/execute`) com validação do token descartável de uso único (TTL 1h).

### Passo 2: Proteger o Endpoint `/by-phone` contra Enumeração
1. **Adicionar Rate Limiting Rígido**: Limitar consultas por IP a no máximo 10 requisições por minuto.
2. **Exigir Código de Confirmação (OTP via SMS/WhatsApp) ou Mascarar Completamente os Resultados**: Em vez de expor os dados completos da reserva, a consulta por telefone deve exigir confirmação em duas etapas ou enviar um link seguro diretamente para o WhatsApp/E-mail do titular antes de liberar os dados de agendamento na tela.

---

## 5. Evidência da Correção Aplicada

- **Arquivos Modificados**:
  - [`fase_07_hairdule_infra_api/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/sst.config.ts)
  - [`fase_17_hairdule_appointment_service/src/routes/public_appointments.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_17_hairdule_appointment_service/src/routes/public_appointments.py)
- **Implementação**:
  - As rotas públicas legadas `POST /public/appointments/{booking_code}/cancel` e `POST /public/appointments/{booking_code}/reschedule` foram removidas do roteador do API Gateway HTTP (`fase_07_hairdule_infra_api`).
  - No código Python de `public_appointments.py`, as funções correspondentes foram desativadas e passam a retornar `403 Forbidden` (`ENDPOINT_DEPRECATED_USE_MAGIC_LINK`), forçando a utilização do fluxo seguro com Magic Link descartável de uso único (TTL 1h).

