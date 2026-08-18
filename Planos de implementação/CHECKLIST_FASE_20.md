# 📸 Fase 20 — Storage + CDN (`fase_20_hairdule_infra_cdn`)
## Checklist de Execução — Status Completo

> **Repositório:** `fase_20_hairdule_infra_cdn`
> **Tecnologia:** SST v4 — AWS S3 + CloudFront CDN + Origin Access Control (OAC)
> **Dependências Diretas:** Fases 08, 10, 19 (Frontends Angular para hospedagem)
> **Última verificação:** 2026-08-16

---

## 🎯 Objetivo da Fase

A Fase 20 provisiona a **infraestrutura de armazenamento e distribuição global**:
1. **Bucket S3** para upload de mídias (logos de barbearias, avatares de profissionais)
2. **CloudFront CDN** para servir os dois frontends Angular (Dashboard e Portal Público) com alta performance global e HTTPS.

Ela faz parte do **Marco 5 de Entrega**: colocar os frontends construídos em produção com CDN global e baixíssima latência.

---

## ✅ Checklist Completo da Fase 20

### 📦 1. Bucket S3 — Fotos e Mídia

- [ ] **`aws:s3:Bucket`** — `hairdule-media-{stage}` privado sem acesso público direto
- [ ] CORS configurado para uploads
- [ ] Subpastas por tenant (`photos/barbershops/{id}/`, `photos/staff/{id}/`)

---

### 🌐 2. CloudFront CDN — Dashboard & Portal

- [ ] Distribution Dashboard (`app.hairdule.com.br`) com Origin Access Control (OAC)
- [ ] Distribution Portal (`hairdule.com.br`) com OAC
- [ ] SPA Custom Error Routing (404/403 → `/index.html`)

---

## 📈 Resumo de Progresso

| Categoria | Concluído | Total | % |
|---|---|---|---|
| S3 Bucket Mídias | 0 | 2 | **0%** ⬜ |
| CloudFront Distributions | 0 | 2 | **0%** ⬜ |
| **TOTAL** | **0** | **4** | **0%** ⬜ |

> **Status:** ⬜ Aguarda conclusão dos Marcos 1 a 4.
