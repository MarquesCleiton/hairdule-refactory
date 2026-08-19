# 🏪 Fase 09 — Barbershop & Onboarding Service Lambda (`fase_09_hairdule_barbershop_service`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_09_hairdule_barbershop_service`
> **Tecnologia:** Python 3.12 + FastAPI + Mangum | Porta local: `3002`
> **Dependências Diretas:** Fase 05 (hairdule-shared), Fase 06 (auth-service), Fase 07 (API Gateway)
> **Última verificação:** 2026-08-18

---

## 🎯 Objetivo da Fase

A Fase 09 implementa o **serviço de gestão do estabelecimento e onboarding**. Após fazer login (Fase 06/08), o dono precisa completar o cadastro da barbearia — nome, endereço, segmento, profissionais iniciais, serviços e horários. Tudo isso é responsabilidade desta Lambda.

Ela é o **Marco 2 de Entrega Testável**: cuida do perfil, executa o setup completo de onboarding e altera o status da barbearia de `Em Cadastro` para `Ativo`.

---

## ✅ Checklist Completo da Fase 09

### 🔗 1. Pré-requisitos

- [x] Fase 06 funcional (JWT gerado e válido para testes)
- [x] Fase 05 instalável (`pip install -e ../hairdule-shared`)
- [x] Tabelas `barbershops`, `services`, `staff`, `staff_services`, `business_hours`, `consents` existem (Fase 04)

---

### 🐍 2. Backend — Rotas FastAPI

- [x] **`GET /barbershop`** (JWT obrigatório) — dados completos do estabelecimento
- [x] **`PUT /barbershop`** (JWT owner) — atualiza nome, endereço, segmento, booking_mode, slot_interval
- [x] **`POST /barbershop/onboarding-complete`** (JWT owner) — **operação atômica** em transação única:
  1. Valida que barbearia está em `Em Cadastro` (409 se já `Ativo`)
  2. Atualiza perfil + endereço + segmento
  3. Cria profissionais (staff) informados
  4. Cria serviços
  5. Vincula `staff_services`
  6. Cria 7 `business_hours` (dom a sáb)
  7. Registra `consents` (LGPD)
  8. Altera `barbershop.status` → `"Ativo"`
  9. Retorna summary do que foi criado
- [x] **`POST /barbershop/photo-upload`** (JWT owner) — upload de logo
- [x] **`GET /public/barbershop`** (público) — dados públicos por `slug` ou `id`
- [x] **`GET /public/lookup`** (público) — busca por `slug` ou `CNPJ`

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
- A pasta dedicada **`docs/testes_manuais/`** está implementada neste repositório.
- **`TESTES_SUCESSO.md`**: Massas JSON no padrão API Gateway v2 HTTP Payload (Version 2.0) cobrindo os fluxos felizes.
- **`TESTES_ERROS.md`**: Massas JSON para validação de erros (400, 401, 403, 404, 409, 422).

---

### 🧪 3. Testes Unitários e Testes Manuais na AWS

- [x] `test_get_barbershop` → 200 com dados completos
- [x] `test_update_barbershop` → campos atualizados
- [x] `test_onboarding_complete_valid` → status muda para `Ativo`
- [x] `test_onboarding_already_active` → 409 `BARBERSHOP_ALREADY_ACTIVE`
- [x] `test_onboarding_without_consent` → 400 `CONSENT_REQUIRED`
- [x] `test_public_barbershop` → dados públicos sem campos sensíveis
- [x] Pasta `docs/testes_manuais/` criada com `TESTES_SUCESSO.md` e `TESTES_ERROS.md` (Massas JSON v2 2.0)

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| Pré-requisitos | 3 | 3 | **100%** 🟩 |
| Rotas FastAPI (6 rotas) | 6 | 6 | **100%** 🟩 |
| Testes pytest (19 testes) | 19 | 19 | **100%** 🟩 |
| **TOTAL** | **28** | **28** | **100%** 🟩 |

> **Status:** 🟩 Implementado e validado com 100% de sucesso (19/19 testes aprovados, cobertura 92%).
