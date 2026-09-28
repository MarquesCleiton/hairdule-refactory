# 🛡️ Plano de Implementação: Defesa contra IP Dinâmico, Proxies Residenciais e Botnets

> **Status:** 📋 Pronto para Execução  
> **Prioridade:** 🚨 Alta  
> **Escopo:** Microsserviços (`fase_06`, `fase_17`), Shared Layer (`fase_05`), CDN (`fase_20`)

---

## 1. O Problema do IP Dinâmico e Proxies Residenciais

Em ataques profissionais de força bruta ou raspagem de dados (scraping), invasores não utilizam um único IP. Eles contratam **pools de proxies residenciais rotativos** (ex: BrightData, Oxylabs, redes Tor ou botnets), onde **cada requisição HTTP chega ao servidor com um endereço IP diferente**.

> ⚠️ **A falha da proteção convencional:** Se o sistema depender apenas de `rate_limit por IP`, o atacante terá sucesso garantido, pois cada tentativa parecerá vir de um visitante inédito e legítimo.

---

## 2. Estratégia de Defesa Multidimensional (4 Pilares)

Para neutralizar atacantes com IP dinâmico, o Hairdule implementará uma defesa que não depende exclusivamente do endereço IP:

```
                      [ REQUISIÇÃO DO ATACANTE ]
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│ PILAR 1: Desafio Criptográfico Anti-Bot (Cloudflare Turnstile)         │
│ • Bloqueia bots no ato, mesmo com milhões de IPs rotativos             │
│ • O atacante precisa de um navegador real com alto custo de CPU/RAM    │
└─────────────────────────────────┬──────────────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│ PILAR 2: Target-Based Throttling (Limitação por Alvo de Negócio)       │
│ • Limite atrelado ao RECURSO atacado, não ao IP                        │
│ • Bloqueia tentativas contra o mesmo e-mail, telefone ou barbearia     │
└─────────────────────────────────┬──────────────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│ PILAR 3: Detecção Heurística de Scanner (Honeypot & 404 Threshold)     │
│ • IPs que consultam múltiplos recursos inexistentes tomam ban imediato │
└─────────────────────────────────┬──────────────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│ PILAR 4: Bloqueio de Tor e Proxies Anônimos (AWS WAF Managed Rules)    │
│ • Descarte automático de nós Tor, VPNs comerciais e datacenters        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Detalhamento dos Pilares de Defesa

### Pilar 1: Desafio Criptográfico Anti-Bot (Cloudflare Turnstile)
- **Como funciona:** O Turnstile avalia se a requisição partiu de um ambiente de navegador legítimo (analisando integridade de Canvas, WebGL, APIs criptográficas e assinatura de hardware).
- **Por que anula o IP dinâmico:** Mesmo que o atacante rotacione 50.000 IPs residenciais em um script Python/Go, ele **não consegue forjar o token do Turnstile**. O backend descarta a chamada em `403 Forbidden` antes de processar qualquer lógica ou consultar o banco.

---

### Pilar 2: Target-Based Throttling (Rate Limit por Alvo)
Em vez de avaliar apenas *"quantas vezes o IP X chamou"*, o sistema avalia *"quantas vezes o recurso Y foi requisitado"*:

1. **Proteção de Login (`POST /auth/login`):**
   - **Chave de Limitação:** `email` do usuário.
   - **Regra:** Se o e-mail `dono@barbearia.com` registrar **5 falhas de senha em 5 minutos**, o acesso àquela conta é suspenso por 15 minutos, **mesmo que cada tentativa tenha vindo de um IP diferente**!
   - **Mitigação:** Elimina ataques de força bruta direcionados (*targeted brute-force*).

2. **Proteção de Consulta de Agendamento (`GET /public/appointments/by-phone`):**
   - **Chave de Limitação:** Chave composta `(barbershop_id, phone)`.
   - **Regra:** Um mesmo número de telefone não pode ser consultado mais de **3 vezes a cada 5 minutos**, independentemente de quantos IPs façam a requisição.
   - **Mitigação:** Impede que bots com múltiplos IPs consigam monitorar ou raspar a agenda de um cliente específico.

3. **Proteção Geral da Barbearia (`POST /public/appointments`):**
   - **Chave de Limitação:** `barbershop_id`.
   - **Regra:** Velocidade máxima de 10 agendamentos por minuto para uma mesma barbearia. Se ultrapassar, ativa desafio adicional ou fila de espera.

---

### Pilar 3: Detecção Heurística de Scanners e Enumeração
Atacantes que tentam descobrir telefones válidos ou e-mails realizam muitas consultas que retornam `404 Not Found` (telefone não agendado / e-mail não existente):
- **Regra do Scanner:** Se um cliente gerar **3 erros `404` consecutivos** em rotas de busca (`/by-phone`), a sessão/IP é marcada como "comportamento de scanner" e bloqueada temporariamente.
- **Resposta:** Acesso suspenso por 30 minutos com `HTTP 429 Too Many Requests`.

---

### Pilar 4: Bloqueio de Tor e Proxies Anônimos no AWS WAF
No ambiente de produção (`fase_07_hairdule_infra_api`), o WAF incorpora regras gerenciadas da AWS:
1. `AWSManagedRulesAnonymousIpList`:
   - Bloqueia automaticamente nós de saída da rede Tor.
   - Bloqueia proxies abertos (open proxies) e serviços de VPN comerciais usados para ofuscar tráfego malicioso.
2. `AWSManagedRulesAmazonIpReputationList`:
   - Bloqueia IPs catalogados na inteligência de ameaças da AWS (envolvidos em ataques DDoS, botnets, crawlers maliciosos conhecidos).

---

## 4. Matriz de Ataques e Como o Hairdule Mitiga

| Tipo de Ataque | Vetor / Método do Invasor | Como o Hairdule Mitiga |
| :--- | :--- | :--- |
| **Ataque com IP Dinâmico** | Usa proxy pool residencial para burlar rate limit por IP | **Target-Based Throttling** (bloqueia por email/telefone) + **Turnstile** (exige prova de navegador) |
| **Ataque Internacional** | Bots chineses/russos varrendo vulnerabilidades | **Geo-Blocking CloudFront** (descarte de 100% do tráfego fora do Brasil na borda) |
| **Credential Stuffing** | Testa listas de senhas vazadas em massa no login | **Cognito Lockout** + **Rate Limit por E-mail** + **Turnstile** |
| **Scraping de Clientes** | Varre DDD + telefones para roubar nomes e PII | **RouteSettings no Gateway (429)** + **Turnstile** + **Mascaramento de PII** |
| **Email Bombing (SES)** | Dispara 50k requisições em recuperar senha para spam | **Turnstile Obrigatório** + **Rate Limit de 1 email/15 min por destinatário** |
| **Agenda Flooding (DoS)** | Cria centenas de agendamentos falsos na barbearia | **Turnstile Obrigatório** + **Limite de 3 agendamentos pendentes por cliente** |
| **Layer 7 DoS / Esgotamento**| Inunda a API com requisições rápidas para travar o RDS | **Burst Limit rígido no Gateway** (corta antes da Lambda) |
