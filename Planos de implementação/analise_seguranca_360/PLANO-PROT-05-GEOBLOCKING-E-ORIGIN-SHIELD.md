# 🛡️ Plano de Implementação: Geo-Blocking Brasil e Proteção de Origem (Origin Shield)

> **Status:** 📋 Pronto para Execução  
> **Prioridade:** 🚨 Alta / Imediata  
> **Repositórios Afetados:** `fase_20_hairdule_infra_cdn` e `fase_07_hairdule_infra_api`  
> **Arquivos Alvo:** [`fase_20_hairdule_infra_cdn/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_20_hairdule_infra_cdn/sst.config.ts), [`fase_07_hairdule_infra_api/sst.config.ts`](file:///d:/Documentos/Projetos/Hairdule/Hairdule%20Reborn/fase_07_hairdule_infra_api/sst.config.ts)

---

## 1. Problema Identificado

1. **Ausência de Geo-Restrição no CloudFront:**
   - O CloudFront está configurado com `restrictions: { geoRestriction: { restrictionType: "none" } }`.
   - Isso significa que bots, scanners e atacantes de qualquer país (China, Rússia, Europa, EUA) conseguem acessar o dashboard e os endpoints da API livremente. Mais de 85% dos ataques automatizados na internet originam-se fora do Brasil.
2. **Exposição Direta do Subdomínio `execute-api` do API Gateway:**
   - O endpoint `https://nlrx258a8i.execute-api.us-east-1.amazonaws.com` é público. Mesmo que coloquemos restrições no CloudFront, um atacante que descubra o endpoint direto da AWS consegue burlar o CDN e chamar a API diretamente.

---

## 2. Solução Técnica

### A. Ativação de Geo-Restriction Estrita no CloudFront (`fase_20`)
Configurar o CloudFront com uma lista de permissão exclusiva para o **Brasil (`BR`)**:
```typescript
restrictions: {
  geoRestriction: {
    restrictionType: "whitelist",
    locations: ["BR"],
  },
},
```
- **Custo:** **$0,00 (Nativo e Gratuito no CloudFront)**.
- **Efeito:** Qualquer requisição vinda de IPs fora do Brasil é descartada no próprio Edge Location mais próximo do atacante, retornando `HTTP 403 Forbidden` sem sequer trafegar pela rede interna da AWS ou gerar custo de Lambda/banco.

### B. Proteção contra Bypass de CDN (Origin Verify Header)
Para impedir que atacantes chamem o `execute-api` diretamente sem passar pelo CloudFront:
1. O CloudFront injeta um cabeçalho customizado secreto em todas as requisições enviadas ao origin do API Gateway:
   ```typescript
   customHeaders: [
     {
       name: "X-Hairdule-Origin-Verify",
       value: config.originVerifySecret, // Segredo mantido no SSM/Secrets Manager
     },
   ],
   ```
2. O API Gateway ou a camada de autorização/Lambda valida a presença do cabeçalho `X-Hairdule-Origin-Verify`. Requisições diretas sem o cabeçalho tomam `403 Forbidden` imediatamente.

---

## 3. Plano de Teste e Validação

1. **Validação com VPN Internacional:**
   - Conectar via VPN em servidor nos EUA ou Europa e acessar a URL do CloudFront:
     - **Resultado Esperado:** `403 Forbidden` emitido pelo CloudFront.
2. **Validação de Conexão no Brasil:**
   - Acesso normal a partir de IP brasileiro:
     - **Resultado Esperado:** `200 OK`.
3. **Tentativa de Bypass Direto no `execute-api`:**
   - Chamada direta ao endpoint do API Gateway sem o header secreto:
     - **Resultado Esperado:** Bloqueio com `403 Forbidden`.
