# VULN-13 — Enumeração e Scraping em Massa de PII no Endpoint de Consulta por Telefone

> **Status:** [x] ✅ **Corrigido e Validado em Homologação (PR #10 da fase_17)**  
> **Severidade:** 🔶 **ALTA**  
> **CVSS v3.1:** 8.2 (`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N`)  
> **Repositório Afetado:** [`fase_17_hairdule_appointment_service`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_17_hairdule_appointment_service)  
> **Arquivo Alvo:** [`src/routes/public_appointments.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_17_hairdule_appointment_service/src/routes/public_appointments.py)

---

## 1. Descrição da Vulnerabilidade

O endpoint `GET /public/appointments/by-phone` permite que qualquer visitante sem autenticação consulte os agendamentos futuros de um cliente na barbearia, fornecendo apenas o `barbershop_id` (que é público nas URLs e landing pages) e o número de telefone (`phone`).

### Vulnerabilidades Associadas:
1. **Ausência de Rate Limit por Telefone e IP:** Um atacante pode criar um script que itera números de telefone sequenciais de uma cidade/região (ex: `11980000000` a `11989999999`) a taxas elevadas (100 req/s), sem tomar nenhum bloqueio.
2. **Vazamento de PII (Personally Identifiable Information):** Quando o telefone possui agendamentos, o endpoint retorna o nome completo do cliente (`customer_name`), horário, serviço, profissional e o `booking_code`.
3. **Ausência de Desafio Anti-Bot:** Não há verificação se a consulta foi feita por um navegador humano real ou por ferramentas automatizadas (Insomnia, cURL, Python).

---

## 2. Cenário de Ataque

```
[ Script Automatizado de Raspagem / Crawler ]
       │
       ▼ (Itera telefones de 11980000000 a 11989999999)
[ GET /public/appointments/by-phone?barbershop_id=UUID&phone=1198xxxxxxx ]
       │
       ▼ (Sem rate limit, responde em 0.01s com 200 OK)
[ Identifica clientes da barbearia, serviços contratados e horários ]
       │
       ▼
[ Cria banco de dados de clientes para espionagem comercial ou engenharia social ]
```

---

## 3. Evidência no Código Atual

Arquivo: `fase_17_hairdule_appointment_service/src/routes/public_appointments.py` (linhas 86 a 105):
```python
@router.get(
    "/by-phone",
    response_model=list[AppointmentPublicResponse],
    summary="Consulta agendamentos futuros pelo telefone do cliente na barbearia",
)
def get_public_appointments_by_phone(
    barbershop_id: UUID = Query(...),
    phone: str = Query(..., min_length=8),
    db: Session = Depends(get_db),
):
    # ⚠️ Executa query direta no banco sem validação de taxa ou bot!
    appointments = AppointmentService.get_public_appointments_by_phone(
        db=db,
        barbershop_id=barbershop.id,
        phone=phone,
    )
```

---

## 4. Solução Técnica Proposta

1. **Target-Based Throttling (Rate Limit por Telefone):**
   - Máximo de **3 consultas a cada 5 minutos para o mesmo número de telefone na mesma barbearia**, independentemente do IP solicitante.
2. **Detecção Heurística de Scanners (Ban por 404):**
   - Se o mesmo IP realizar **3 consultas consecutivas de telefones que não possuem agendamentos (`404` / lista vazia)** em menos de 1 minuto, o IP é classificado como scanner e bloqueado temporariamente por 30 minutos (`HTTP 429`).
3. **Mascaramento Rigoroso de PII:**
   - O nome do cliente nunca deve ser retornado por extenso em rota pública desautenticada:
     - `Carlos Eduardo Silva` -> `Carlos S****`
     - Telefone: `(11) 9****-2606`

---

## 5. Checklist de Implementação & Validação

- [x] Implementar limitador de taxa por telefone e detecção de scanner em `src/rate_limiter.py` e `src/routes/public_appointments.py`.
- [x] Aplicar mascaramento de nome e telefone do cliente na resposta pública do DTO `AppointmentPublicResponse`.
- [x] Validar que consultas com o mesmo telefone ou tentativas sucessivas sem resultado disparam `429 Too Many Requests`.
- [x] Executar bateria de testes com 100% de aprovação e deploy via PR #10 na branch `release/v4`.
