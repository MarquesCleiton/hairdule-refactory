# Regras de Negócio e Automações Mantidas nos Serviços (Sem Triggers / Views no Banco)

> **Diretriz de Arquitetura:** O banco de dados (`hairdule-db`) é exclusivamente um repositório puro de armazenamento persistente (Tabelas, Chaves Estrangeiras e Índices). Nenhuma regra de negócio, automação, trigger, stored procedure ou view reside no banco de dados. Todas as regras são processadas e garantidas na camada de aplicação (Microsserviços FastAPI / SQLAlchemy / Pydantic).

---

## 📌 Relação de Regras e Implementação nos Microsserviços

### 1. Geração do Código de Agendamento (`booking_code`)
* **Descrição:** Geração de código único e legível por agendamento no formato `BKG-YYYYMMDD-NNNN` (ex: `BKG-20260808-0001`).
* **Como era (banco antigo):** Trigger `set_booking_code` que contava agendamentos do dia via PL/pgSQL antes do `INSERT`.
* **Como será implementado (Serviço):**
  - **Serviço Responsável:** `hairdule-appointments-service`
  - **Local da Lógica:** `src/services/appointment_service.py`
  - **Fluxo:** Durante a criação do agendamento, o serviço consulta em transação a contagem de agendamentos da barbearia no dia (`date`), formata a string `BKG-YYYYMMDD-` com pad zerado de 4 dígitos (`LPAD(count + 1, 4, '0')`) e atribui ao campo `booking_code` do modelo antes de commitar.

---

### 2. Atualização Automática de Data de Modificação (`updated_at`)
* **Descrição:** Atualizar a coluna `updated_at` com o timestamp corrente (`NOW()`) sempre que um registro for alterado.
* **Como era (banco antigo):** Trigger `update_updated_at_column` associado a todas as tabelas em evento `BEFORE UPDATE`.
* **Como será implementado (Serviço):**
  - **Serviço Responsável:** `hairdule-shared` (SDK ORM) + Todos os microsserviços.
  - **Local da Lógica:** `hairdule_shared.database.base.Base` + SQLAlchemy.
  - **Fluxo:** Os modelos SQLAlchemy utilizam a propriedade `onupdate=func.now()` no atributo `updated_at` da classe base (`Base`). Toda alteração de objeto realizada pelo ORM atualiza automaticamente a data na aplicação antes de enviar a instrução de `UPDATE`.

---

### 3. Filtro de Profissionais Ativos Públicos (Anteriormente View `staff_public`)
* **Descrição:** Exibição de profissionais para o portal público de agendamento sem expor dados sensíveis/PII (como e-mail e telefone pessoal).
* **Como era (banco antigo):** View SQL `CREATE VIEW staff_public AS SELECT id, barbershop_id, name, avatar_url, bio, role_code, is_active FROM staff WHERE is_active = TRUE;`.
* **Como será implementado (Serviço):**
  - **Serviço Responsável:** `hairdule-staff-service`
  - **Local da Lógica:** Endpoint `GET /public/staff`
  - **Fluxo:** O endpoint executa uma consulta filtrada `select(Staff).where(Staff.barbershop_id == id, Staff.is_active == True)` e mapeia o resultado para o DTO Pydantic `StaffPublicResponse`, expondo apenas `id`, `name`, `avatar_url`, `bio`, `role_code`.

---

### 4. Mascaramento de Dados PII de Clientes (Anteriormente View `appointments_safe`)
* **Descrição:** Mascarar dados pessoais de clientes (nome "Primeiro ***", telefone "(XX) *****-XXXX") para barbeiros sem permissão de visualização total da agenda da equipe (`TEAM_READ_ONLY` / `OWN_ONLY`).
* **Como era (banco antigo):** View SQL `CREATE VIEW appointments_safe` usando `SUBSTRING` e `REGEXP_REPLACE`.
* **Como será implementado (Serviço):**
  - **Serviço Responsável:** `hairdule-appointments-service`
  - **Local da Lógica:** `src/dependencies/auth.py` + Pydantic Response Serializer
  - **Fluxo:** O serviço de agendamentos verifica a role e permissão do usuário autenticado no token JWT (`CurrentUser`). Se o usuário não tiver privilégio de `OWNER` ou `ALL_FULL`, a resposta da API passa por uma função de sanitização em Python que mascara o nome e o telefone do cliente no Pydantic DTO antes de enviar ao cliente HTTP.

---

### 5. Validação de Unicidade e Regras de Conflito de Horário
* **Descrição:** Impedir agendamento em horário ocupado, fora do horário de funcionamento ou durante pausas/bloqueios.
* **Como era (banco antigo):** Parcialmente verificado por constraints ou regras no Supabase.
* **Como será implementado (Serviço):**
  - **Serviço Responsável:** `hairdule-availability-service` + `hairdule-appointments-service`
  - **Local da Lógica:** Algoritmo de cálculo de disponibilidade em 6 camadas em Python (verificação de funcionamento, horário do profissional, bloqueios, buffers, pausas e agendamentos existentes).
