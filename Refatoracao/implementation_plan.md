# Validação de Buffer e Espaço Total (Atendimento + Pausa + Buffer) no Agendamento

Este plano aborda a correção do agendamento no passado e na timeline da agenda, garantindo que o buffer seja rigorosamente calculado e que agendamentos só sejam permitidos se houver espaço livre suficiente para acomodar a soma integral de **atendimento + pausa + buffer**.

## Análise do Problema e Causa Raiz

Conforme identificado no feedback e na captura de tela:
1. **Sobreposição com o Buffer de Atendimentos Anteriores**:
   - Um atendimento das 13:30 às 15:00 com 10 min de buffer pós-atendimento ocupa a agenda do colaborador até as 15:10.
   - O agendamento retroativo permitiu marcar um novo serviço às 15:00, colidindo diretamente com o bloco de buffer (15:00–15:10).
   - O `isStaffBusyWithAppointment` no frontend comparava apenas `app.start_time` e `app.end_time`, ignorando os minutos de buffer do serviço do agendamento existente (`buffer_min`).
   - No backend (`fase_17_hairdule_appointment_service/src/services/appointment_service.py`), `_get_appointment_busy_intervals` dependia exclusivamente de `app.service.buffer_min`. Caso o relacionamento `app.service` não estivesse carregado no ORM, `buffer_min` caía para 0 e a checagem de conflitos ignorava o buffer do agendamento anterior.

2. **Cálculo Incompleto do Espaço Livre Necessário**:
   - Para um novo serviço, o tempo total necessário na agenda é:
     $$\text{Espaço Total} = \text{Duração Ativa} + \text{Duração da Pausa} + \text{Buffer Pós-Atendimento}$$
   - No clique de slot da timeline (`calendar-day-view.component.ts` e `calendar.component.ts`):
     - Ao clicar em um horário (ex: 15:00), o loop de itens apenas verificava `it.startMinutes > startMin`. Não verificava se `startMin` já caía **dentro** de um item ocupado (`it.startMinutes <= startMin && it.endMinutes > startMin`). Logo, o buffer anterior era ignorado e o tempo livre era superestimado.
     - O filtro de serviços elegíveis somava apenas `duration + buffer`, ignorando completamente `pause_duration_min`.
   - No modal (`new-appointment-modal.component.ts`):
     - `enrichBackendSlots`: ao injetar horário fixo ou retroativo, não validava se o colaborador estava ocupado no intervalo total `[start, start + totalSpan]`.
     - `isSelectedStaffAvailable`: retornava `true` imediatamente em `effectiveIsFixedStaffMode()`, ignorando colisões e permitindo avançar mesmo se o colaborador estivesse ocupado.
     - `advanceToStep2`: não validava conflitos contra os agendamentos já salvos na agenda considerando o buffer e a pausa.

---

## Proposta de Alterações

### 1. Backend: Validação Estrita de Buffer e Conflitos
#### [MODIFY] [`appointment_service.py`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_17_hairdule_appointment_service/src/services/appointment_service.py)
- **`_get_appointment_busy_intervals(app: Appointment, db: Session | None = None)`**:
  - Se `app.service` for `None` ou não contiver `buffer_min`, consultar a tabela `Service` via `db` pelo `app.service_id` para recuperar o `buffer_min`.
  - Garantir que o `buffer_min` seja adicionado ao término do último bloco ativo (`STAGE_2` ou bloco contínuo).
- **`check_conflicts`**:
  - Adicionar parâmetro `new_buffer_min: int = 0`.
  - Expandir o último intervalo de `new_busy_intervals` para incluir `new_buffer_min`.
  - Atualizar a busca de agendamentos candidatos para `Appointment.start_time < (end_time + timedelta(minutes=new_buffer_min))` e passar `db=db` para `_get_appointment_busy_intervals`.
- **`create_session`, `create_appointment`, `reschedule_appointment`**:
  - Passar `new_buffer_min=service.buffer_min` nas chamadas a `check_conflicts`.

---

### 2. Frontend: Validação de Slots na Timeline e Filtro de Serviços
#### [MODIFY] [`calendar-day-view.component.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_08_hairdule_ui_web/src/app/features/calendar/components/calendar-day-view/calendar-day-view.component.ts)
- Em `onSlotClick`:
  - Verificar se `startMin` está dentro de algum item existente da coluna (`it.startMinutes <= startMin && it.endMinutes > startMin`). Se estiver, `freeMinutes = 0`.
  - Ao calcular o próximo compromisso, buscar o menor `it.startMinutes >= startMin`.
  - Ao filtrar serviços elegíveis, calcular:
    $$\text{total} = (\text{svc.duration\_min} \parallel 30) + (\text{svc.pause\_duration\_min} \parallel 0) + (\text{svc.buffer\_min} \parallel 0)$$
    Apenas serviços com $\text{total} \le \text{freeMinutes}$ entram na lista de elegíveis.
- Em `onQuickAddClick`:
  - Utilizar a mesma fórmula completa somando atendimento + pausa + buffer.

#### [MODIFY] [`calendar-week-view.component.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_08_hairdule_ui_web/src/app/features/calendar/components/calendar-week-view/calendar-week-view.component.ts)
- Em `onSlotClick` e `onQuickAddClick`:
  - Calcular e emitir `eligibleServiceIds` considerando `duration + pause + buffer` contra o tempo livre até o próximo compromisso.

#### [MODIFY] [`calendar.component.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_08_hairdule_ui_web/src/app/features/calendar/calendar.component.ts)
- Em `computeEligibleServicesForSlot`:
  - Verificar se `startMin` colide com qualquer item da coluna ou agendamento local (incluindo buffer pós-atendimento). Se colidir, retornar `[]`.
  - Filtrar serviços exigindo que $\text{duration} + \text{pause\_duration} + \text{buffer} \le \text{freeMinutes}$.

---

### 3. Frontend: Modal de Agendamento (`new-appointment-modal`)
#### [MODIFY] [`new-appointment-modal.component.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_08_hairdule_ui_web/src/app/shared/components/new-appointment-modal/new-appointment-modal.component.ts)
- **`isStaffBusyWithAppointment`**:
  - Para cada agendamento existente da lista, obter seu `buffer_min` (de `app.service?.buffer_min` ou fallback via `this.servicesList()`).
  - Se possuir `time_blocks`, verificar cada bloco ativo, estendendo o final do último bloco por `buffer_min`.
  - Se for contínuo, o intervalo ocupado é `[appStartMin, appEndMin + buffer_min]`.
  - Verificar sobreposição entre o intervalo solicitado e o intervalo ocupado do agendamento anterior.
- **Cálculo do Span Total do Novo Serviço**:
  - Criar helper `getRequiredServiceSpanMin()`:
    $$\text{totalSpan} = \text{customDurationMin}() + (\text{isPauseEnabled}() ? \text{pauseDurationMin}() : 0) + (\text{selectedServiceObj}()\text{.buffer\_min} \parallel 0)$$
- **`enrichBackendSlots`**:
  - No fallback de horário fixo / retroativo (`isFixedSlotMode && this.initialTime`), calcular o span total do serviço.
  - Filtrar `eligibleStaff` para incluir **apenas** colaboradores que **NÃO** estejam ocupados em `[fixedMin, fixedMin + totalSpan]`.
  - Se nenhum colaborador estiver livre nesse intervalo de span total, marcar o slot como indisponível/ocupado (`available_staff: []`, `visual_status: 'OCCUPIED'`).
- **`displayedStaffForSelectedSlot`**:
  - Garantir que colaboradores só sejam listados se estiverem livres durante todo o `totalSpan` (atendimento + pausa + buffer).
- **`isSelectedStaffAvailable`**:
  - Não retornar `true` cego em `effectiveIsFixedStaffMode()`. Verificar `!this.isStaffBusyWithAppointment(staffId, startMin, startMin + totalSpan)`.
- **`canAdvanceToStep2` & `advanceToStep2`**:
  - Bloquear o avanço se o colaborador estiver ocupado no intervalo total somando atendimento, pausa e buffer.
  - Exibir alerta via `notificationService.warning` caso haja colisão.
- **`displayedServices`**:
  - Se `isFixedSlotMode` estiver ativo com horário fixo, filtrar o dropdown de serviços para exibir apenas serviços cuja soma de atendimento + pausa + buffer caiba no tempo livre até o próximo compromisso do colaborador selecionado.

---

## Plano de Verificação

### Testes Automatizados
- Executar build de produção do frontend para verificar tipagem e integridade:
  ```powershell
  npm --prefix "fase_08_hairdule_ui_web" run build
  ```
- Executar testes do serviço de agendamentos no backend:
  ```powershell
  pytest "fase_17_hairdule_appointment_service/tests/test_appointment_service.py"
  ```

### Verificação Manual
1. **Cenário de Conflito com Buffer**:
   - Criar um agendamento das 13:30 às 15:00 com 10 min de buffer (ocupado até 15:10).
   - Tentar agendar às 15:00 no passado ou presente:
     - O sistema deve bloquear a seleção das 15:00 para esse profissional e não permitir avançar.
     - As 15:00 deve aparecer como indisponível/ocupado.
2. **Cenário de Espaço Livre Insuficiente**:
   - Havendo 20 minutos livres entre 15:10 e 15:30:
     - Clicar no slot das 15:10.
     - Apenas serviços cuja soma de atendimento + pausa + buffer seja $\le 20\text{m}$ devem aparecer disponíveis.
     - Serviços de 30m, 60m ou com etapas que somem mais de 20m não devem ser selecionáveis.
3. **Agendamento no Passado com Espaço Válido**:
   - Clicar em um horário no passado onde o profissional estava realmente livre (tempo livre $\ge$ atendimento + pausa + buffer).
   - Confirmar o alerta do Hairy.
   - O agendamento deve ser criado com sucesso com status `FINALIZADO`.
