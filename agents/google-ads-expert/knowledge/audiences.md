<!-- Origem metodológica: claude-ads (MIT) — google-audit.md (Audiences G56-G58, geo G11, network G12). -->

# Audience Signals & Targeting

Na era pós-keyword do Google Ads, audience deixou de ser um filtro rígido e virou **sinal**: um input que informa o Smart Bidding e o Power Pack (PMax + Demand Gen + AI Max) sobre quem tem maior probabilidade de converter, sem excluir ninguém à força. Este arquivo cobre como usar remarketing e in-market como sinal em modo Observation (G56), Customer Match como o sinal first-party mais forte (G57), exclusões de placement (G58), targeting geográfico correto (G11) e network settings (G12). Como consultor contínuo, o agente lê os segmentos aplicados ao vivo e recomenda; executa só após confirmação humana.

## Observation vs Targeting — a distinção que define tudo

- **Observation (recomendado como default em Search):** a audiência não restringe o alcance. Ela alimenta o algoritmo com sinal e permite bid adjustments e leitura de performance por segmento. O anúncio continua servindo para todos.
- **Targeting:** restringe o alcance apenas à audiência. Use com intenção clara (ex.: campanha de remarketing puro), nunca por default — targeting acidental em Search estrangula volume.

Regra: em Search, aplique audiences em **Observation**. Reserve Targeting para casos onde a restrição é o objetivo.

---

## G56 — Segmentos de audiência aplicados (High)

- **Pass:** remarketing + in-market audiences em modo **Observation**.
- **Warning:** algumas audiences aplicadas.
- **Fail:** nenhum sinal de audiência.

Sem audience signal, o Smart Bidding trabalha com menos contexto sobre propensão. Remarketing (visitantes do site, engajamento no YouTube, listas de app) e in-market (Google infere intenção de compra ativa) são os dois pilares. Aplicados em Observation, viram bid adjustment e insight — não custam alcance.

GAQL para ver segmentos e modo:
```sql
SELECT ad_group_criterion.type, ad_group_criterion.user_list.user_list,
       metrics.conversions, metrics.cost_micros
FROM ad_group_audience_view
WHERE segments.date DURING LAST_30_DAYS
```

---

## G57 — Customer Match (High)

Customer Match é o **sinal de audiência mais forte** que existe no Google Ads — dado first-party direto do CRM (emails, telefones, endereços com hash). É também o sinal mais potente para PMax (ver pmax.md, G-PM1).

- **Pass:** lista de Customer Match subida E **refreshada há menos de 30 dias**.
- **Warning:** lista com mais de 30 dias (dado velho degrada o match).
- **Fail:** nenhuma lista de Customer Match.

Requisitos de acesso e limites (atenção às mudanças de 2025):
- Requer 90 dias de histórico de conta e $50.000+ de gasto lifetime para acesso pleno.
- **Duração máxima de membership: 540 dias** (mudou em 7/abr/2025; antes era infinita). Listas precisam de refresh periódico ou os membros expiram.
- Usos: RLSA, audiências similares e listas de Customer Match para PMax/Demand Gen.

O refresh <30d importa porque o valor do sinal decai: emails mudam, clientes convertem, o CRM evolui. Uma lista congelada há 6 meses é um sinal cada vez mais impreciso. Como consultor contínuo, o agente monitora a idade da lista e reabre o finding quando ela cruza 30 dias.

---

## G58 — Exclusões de placement (High)

- **Pass:** exclusões de placement em **nível de conta** (games, apps, sites MFA — made-for-advertising).
- **Warning:** exclusões só em nível de campanha.
- **Fail:** nenhuma exclusão de placement.

Placements de baixa qualidade (jogos mobile, apps de lanterna, sites MFA) consomem budget de Display/Demand Gen/PMax sem intenção real. Exclusões em nível de conta cobrem todas as campanhas de uma vez — mais robusto que campanha a campanha. Alimente a lista de exclusão a partir do relatório de placements reais, não de suposição.

---

## G11 — Targeting geográfico "People in" (High)

Uma das falhas mais caras e mais fáceis de corrigir (Quick Win 2 min).

- **Pass:** "People in" (presença física) e **não** "People in or interested in" para negócio local.
- **Fail:** "People in or interested in" para negócio local.

O default "or interested in" faz o anúncio de um encanador de São Paulo servir para alguém em Recife pesquisando sobre São Paulo. Para negócio local, use presença física ("People in"). Para negócio que atende à distância ou marca nacional, "interested in" pode ser intencional — mas só com justificativa.

---

## G12 — Network settings (High)

- **Pass:** Search Partners **ligado** (alcance incremental a CPA comparável); Display Network **desligado** em campanha de Search (salvo intenção explícita).
- **Warning:** Search Partners **desligado** — oportunidade de alcance perdida.
- **Fail:** Display Network **ligado** em campanha de Search.

**Nota:** Search Partners tipicamente dá alcance incremental a CPA comparável — flag Search Partners OFF como oportunidade perdida (Warning), não como falha. Display Network ligado numa campanha de Search continua sendo Fail: mistura inventário de display de baixa intenção com uma campanha de search, poluindo a performance e a leitura.

---

## Uso de audiences como sinal — princípio de fechamento

Amarrando com o núcleo cognitivo (principles.md, CONNECT):
- Audience signal, criativo (creatives.md) e search themes (pmax.md) são as três alavancas do "novo targeting" no Power Pack. Nenhuma sozinha basta.
- Customer Match é o sinal transversal: fortalece Search (RLSA), PMax (G-PM1) e Demand Gen ao mesmo tempo. Priorize mantê-la fresca (<30d) acima de sinais mais fracos.
- Em Observation, audiences custam zero alcance e rendem insight — não há razão para não aplicá-las em Search. Em Targeting, exigem justificativa explícita.

Ordem de recomendação típica: (1) G11 geo correto — barato e alto impacto; (2) G12 network sane; (3) G56 audiences em Observation; (4) G57 Customer Match fresca; (5) G58 exclusões de placement em conta.
