# 🏪 Fase 11 — Barbershop Service Lambda (`fase_11_hairdule_barbershop_service`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_11_hairdule_barbershop_service`
> **Tecnologia:** Python 3.12 + FastAPI + Mangum | Porta local: `3002`
> **Dependências Diretas:** Fase 05 (hairdule-shared), Fase 06 (API Gateway), Fase 09 (auth funcional)
> **Última verificação:** 2026-08-11

---

## 🎯 Objetivo da Fase

A Fase 11 implementa o **serviço de gestão do estabelecimento**. Após fazer login (Fase 09), o dono precisa completar o cadastro da barbearia — nome, endereço, tipo de negócio, profissionais iniciais, serviços e horários. Tudo isso é responsabilidade desta Lambda.

É o **gerente administrativo** da barbearia no sistema: cuida do perfil, configura tudo no onboarding e garante que o status mude de `Em Cadastro` para `Ativo` quando o setup estiver completo.

---

## ✅ Checklist Completo da Fase 11

### 🔗 1. Pré-requisitos

- [ ] Fase 09 funcional (JWT gerado e válido para testes)
- [ ] Fase 05 instalável (`pip install -e ../hairdule-shared`)
- [ ] Tabelas `barbershops`, `services`, `staff`, `staff_services`, `business_hours`, `consents` existem (Fase 04)

---

### 🐍 2. Backend — Rotas FastAPI

- [ ] **`GET /barbershop`** (JWT obrigatório) — dados completos do estabelecimento
- [ ] **`PUT /barbershop`** (JWT owner) — atualiza nome, endereço, segmento, booking_mode, slot_interval
- [ ] **`POST /barbershop/onboarding-complete`** (JWT owner) — **operação atômica** em transação única:
  1. Valida que barbearia está em `Em Cadastro` (409 se já `Ativo`)
  2. Atualiza perfil + endereço + segmento
  3. Cria profissionais (staff) informados
  4. Cria serviços
  5. Vincula `staff_services`
  6. Cria 7 `business_hours` (dom a sáb)
  7. Registra `consents` (LGPD)
  8. Altera `barbershop.status` → `"Ativo"`
  9. Retorna summary do que foi criado
- [ ] **`POST /barbershop/photo-upload`** (JWT owner) — upload de logo:
  - Valida tipo (jpeg, png, webp) e tamanho (max 5MB) via `python-magic`
  - Faz upload para S3 (Fase 07) via `boto3`
  - Atualiza `barbershop.photo_url` com URL do CloudFront
- [ ] **`GET /public/barbershop`** (público) — dados públicos por `slug` ou `id`
- [ ] **`GET /public/lookup`** (público) — busca por `slug` ou `CNPJ`

---

## 🔑 CI/CD, Autenticação de Código Compartilhado (`GH_PAT`) & Suíte de Testes Manuais

### 1. Checkout de Dependência Compartilhada Privada (`GH_PAT`)
- Este repositório consome a biblioteca privada [`hairdule_shared`](https://github.com/MarquesCleitonOrg/fase_05_hairdule_shared).
- No **GitHub Actions**, o checkout do pacote compartilhado utiliza o secret **`GH_PAT`** (Personal Access Token clássico):
  ```bash
  git clone https://x-access-token:${{ secrets.GH_PAT }}@github.com/MarquesCleitonOrg/fase_05_hairdule_shared.git ../fase_05_hairdule_shared
  pip install -e ../fase_05_hairdule_shared
  ```
- O SST v4 utiliza a action **`astral-sh/setup-uv@v5`** no runner para realizar o empacotamento ultrarrápido da Lambda Python antes do deploy.

### 2. Suíte Obrigatória de Testes Manuais Diretos na AWS Lambda
- A pasta dedicada **`docs/testes_manuais/`** é obrigatória neste repositório.
- **`TESTES_SUCESSO.md`**: Massas JSON no padrão API Gateway v2 HTTP Payload (Version 2.0) cobrindo os fluxos felizes.
- **`TESTES_ERROS.md`**: Massas JSON para validação de erros (400, 401, 409, 422).

---

### 🧪 3. Testes Unitários e Testes Manuais na AWS

- [ ] `test_get_barbershop` → 200 com dados completos
- [ ] `test_update_barbershop` → campos atualizados
- [ ] `test_onboarding_complete_valid` → status muda para `Ativo`, 3 profissionais, 2 serviços, 7 business_hours
- [ ] `test_onboarding_already_active` → 409 `BARBERSHOP_ALREADY_ACTIVE`
- [ ] `test_onboarding_without_consent` → 400 `CONSENT_REQUIRED`
- [ ] `test_public_barbershop` → dados públicos sem campos sensíveis
- [ ] `test_photo_upload_invalid_type` → 400 `INVALID_FILE_TYPE`
- [ ] Pasta `docs/testes_manuais/` criada com `TESTES_SUCESSO.md` e `TESTES_ERROS.md` (Massas JSON v2 2.0)
- [ ] `test_photo_upload_too_large` → 400 `FILE_TOO_LARGE`

---

### ⏳ 4. A Fazer — Pendências

- [ ] Criar repositório `fase_11_hairdule_barbershop_service`
- [ ] Implementar todas as rotas FastAPI
- [ ] Implementar transação atômica do onboarding
- [ ] Integrar `boto3` para upload S3
- [ ] Escrever todos os testes
- [ ] `pytest` → todos passando
- [ ] Deploy via SST em staging

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Pré-requisitos | 0 | 3 | **0%** ⬜ |
| Rotas FastAPI (6 rotas) | 0 | 6 | **0%** ⬜ |
| Testes pytest (8 testes) | 0 | 8 | **0%** ⬜ |
| Deploy e Integração | 0 | 3 | **0%** ⬜ |
| **TOTAL** | **0** | **20** | **0%** ⬜ |

> **Status:** ⬜ Aguardando Fases 05, 06 e 09 concluídas.
