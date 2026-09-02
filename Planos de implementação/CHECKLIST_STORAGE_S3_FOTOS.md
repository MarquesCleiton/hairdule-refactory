# 📸 Plano de Implementação — Armazenamento de Fotos no AWS S3 com Presigned URLs
## Checklist de Execução — Status do Projeto

> **Repositórios:** `fase_05_hairdule_shared`, `fase_09_hairdule_barbershop_service`, `fase_11_hairdule_staff_service`, `fase_07_hairdule_infra_api`, `fase_20_hairdule_infra_cdn`, `fase_08_hairdule_ui_web`  
> **Tecnologia:** AWS S3 + Boto3 Presigned URLs (PUT & GET) + Aurora PostgreSQL + Angular 19  
> **Dependências:** Fase 04 (Banco de Dados), Fase 05 (`hairdule_shared`), Fase 20 (CDN & S3 Storage)  
> **Data de Criação:** 2026-09-01  
> **Status:** ✅ **CONCLUÍDO**

---

## 🎯 Objetivo Arquitetural

Substituir o armazenamento rudimentar de imagens Base64 no banco de dados por um **fluxo padrão de mercado de alto desempenho e segurança baseado em AWS S3**:
1. **Upload Direto no S3 (Presigned PUT):** Frontend solicita ao backend um link temporário assinado e faz upload do binário diretamente para o bucket S3 `MediaBucket`, sem passar dados binários pesados pela Lambda ou API Gateway (zero risco de exceder o limite de 6 MB).
2. **Persistência de Chaves no Banco:** O banco PostgreSQL salva exclusivamente o caminho/chave do objeto no S3 (`storage_key`), mantendo o banco leve e otimizado.
3. **Leitura Segura com Links Assinados (Presigned GET):** Ao ler os dados cadastrais da barbearia ou dos colaboradores, o backend lê a chave do banco e gera dinamicamente uma URL assinada temporária (1 hora) no DTO de resposta. As tags `<img>` no Angular continuam funcionando de forma transparente e segura.
4. **Isolamento Multitenant & Anti-Colisão:** Chaves S3 organizadas sob `barbershops/{barbershop_id}/...` com timestamp e UUID, garantindo isolamento total entre estabelecimentos, cache-busting imediato e deleção da imagem antiga para evitar custos ociosos.

---

## 🗺️ Estrutura de Chaves no Bucket S3

```
hairdule-media-{stage}-{accountId}/
└── barbershops/
    └── {barbershop_id}/
        ├── logo/
        │   └── {timestamp}_{uuid}.webp
        ├── banner/
        │   └── {timestamp}_{uuid}.webp
        └── staff/
            └── {staff_id}/
                └── avatar/
                    └── {timestamp}_{uuid}.webp
```

---

## ✅ Checklist de Implementação

### 📦 1. Pacote Compartilhado (`fase_05_hairdule_shared`)
- [x] Configurações de ambiente em `hairdule_shared/types/env.py` (`MEDIA_BUCKET_NAME`, TTLs)
- [x] Criação do módulo `hairdule_shared.storage`:
  - [x] `s3_adapter.py`: Geração de Presigned PUT/GET, `get_signed_url`, deleção e fallback mock para dev local
  - [x] `service.py`: Validação de tipos MIME permitidos (`jpeg`, `png`, `webp`), tamanho máximo (5MB) e montagem de chaves
  - [x] `__init__.py`: Exportação dos métodos
- [x] Exportação no `hairdule_shared/__init__.py` raiz
- [x] Testes unitários com pytest mockando boto3 (11 testes, 100% de sucesso e cobertura)

### ☁️ 2. Infraestrutura SST v4 & Políticas IAM
- [x] `fase_20_hairdule_infra_cdn/sst.config.ts`: Bloqueio de acesso público no `MediaBucket` (`aws.s3.BucketPublicAccessBlock`) e regras de CORS
- [x] `fase_09_hairdule_barbershop_service/sst.config.ts`: Adicionar política IAM `AllowS3MediaAccess` e variável de ambiente `MEDIA_BUCKET_NAME`
- [x] `fase_11_hairdule_staff_service/sst.config.ts`: Adicionar política IAM `AllowS3MediaAccess` e variável de ambiente `MEDIA_BUCKET_NAME`
- [x] `fase_07_hairdule_infra_api/sst.config.ts`: Mapear novas rotas de presigned-url e confirm no API Gateway v2 HTTP API

### 🏪 3. Microsserviço Barbershop (`fase_09_hairdule_barbershop_service`)
- [x] Schemas `PhotoPresignedUrlRequest/Response` e `PhotoConfirmRequest/Response` em `schemas/barbershop.py`
- [x] Rota `POST /barbershop/photo/presigned-url`
- [x] Rota `POST /barbershop/photo/confirm` com limpeza da foto antiga no S3
- [x] `GET /barbershop` convertendo chaves em Presigned GET URLs
- [x] `GET /public/barbershop` convertendo chaves em Presigned GET URLs
- [x] Proteção em `PUT /barbershop` contra sobrescrita acidental por URLs temporárias
- [x] Testes automatizados com pytest (23 testes, 100% de sucesso)

### 👥 4. Microsserviço Staff (`fase_11_hairdule_staff_service`)
- [x] Schemas `StaffAvatarPresignedUrlRequest/Response` e `StaffAvatarConfirmRequest/Response` em `schemas/staff.py`
- [x] Rota `POST /staff/{id}/avatar/presigned-url`
- [x] Rota `POST /staff/{id}/avatar/confirm` com limpeza do avatar anterior no S3
- [x] `GET /staff` e `GET /staff/{id}` convertendo chaves em Presigned GET URLs
- [x] `GET /public/staff` convertendo chaves em Presigned GET URLs
- [x] Proteção em `PUT /staff/{id}` contra sobrescrita acidental por URLs temporárias
- [x] Testes automatizados com pytest (35 testes, 100% de sucesso)

### 💻 5. Frontend Web Dashboard (`fase_08_hairdule_ui_web`)
- [x] Bypass do `auth.interceptor.ts` para requisições diretas ao AWS S3 (evitar conflito SigV4 com Bearer token)
- [x] Criação de `media-upload.service.ts` para PUT binário direto ao S3
- [x] Atualização de `BarbershopService` para orquestrar upload e confirmação de logo/banner
- [x] Atualização de `StaffService` para orquestrar upload e confirmação de avatar
- [x] Atualização do componente `BusinessDataDialogComponent` (substituição de Base64 FileReader por upload direto no S3 com preview imediato via blob URL)
- [x] Atualização dos componentes `StaffDetailDialogComponent` (`features/staff` e `features/settings`)
- [x] Build de produção do Angular 19 concluído com sucesso (`npm run build`)
- [x] Tratamento de erro 422 `INAPPROPRIATE_CONTENT` no frontend com reversão de preview e notificação ao usuário

---

## 8. Auditoria e Moderação de Conteúdo (AWS Rekognition & MediaAuditLog)
- [x] Criação da tabela de domínio `domain_moderation_statuses` (`APPROVED`, `FLAGGED`, `REJECTED`, `PENDING_REVIEW`, `UNVERIFIED`) no `schema.sql` e migrações `002_media_audit_logs.sql` e `003_add_unverified_moderation_status.sql`
- [x] Criação da tabela de auditoria `media_audit_logs` registrando autoria, data/hora, IP, User-Agent, status de moderação e labels detectados
- [x] Modelos ORM SQLAlchemy `DomainModerationStatus` e `MediaAuditLog` implementados em `fase_05_hairdule_shared`
- [x] Serviço `ContentModerator` implementado com suporte a AWS Rekognition (`detect_moderation_labels`) e controle por Feature Flag (`MEDIA_MODERATION_ENABLED`)
- [x] **Custo Zero & Eficiência:** Moderação automatizada mantida desabilitada por padrão (`MEDIA_MODERATION_ENABLED=false`), garantindo R$ 0,00 de custo na AWS e confirmação instantânea das fotos, registrando status `UNVERIFIED` na auditoria
- [x] Políticas IAM com permissão `rekognition:DetectModerationLabels` mantidas nos serviços Barbershop e Staff para reativação imediata sob demanda
- [x] Verificação ativa nos endpoints `POST /barbershop/photo/confirm` e `POST /staff/{id}/avatar/confirm` gravando auditoria completa e expurgando fotos no S3 quando a moderação estiver ativa e detectar violações
- [x] Testes unitários e de integração com 100% de aprovação em todos os microsserviços (validando fluxos com moderação ativa e com status `UNVERIFIED`)

---

## 9. Retenção Probatória e S3 Object Versioning (Opção A)
- [x] Ativação de `BucketVersioningV2` no `MediaBucket` em `fase_20_hairdule_infra_cdn` (preservação de versões anteriores com VersionId ao invés de expurgo físico)
- [x] Configuração de `BucketLifecycleConfigurationV2` com expiração de versões não-atuais após 90 dias (retenção probatória com descarte automático de custo)
- [x] Suporte a `version_id` e método `list_object_versions` implementados em `s3_adapter.py` no `fase_05_hairdule_shared` para recuperação pericial
