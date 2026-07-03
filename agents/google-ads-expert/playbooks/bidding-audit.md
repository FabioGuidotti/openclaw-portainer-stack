# Playbook: Bidding Audit — Estratégias de Lance

## Quando usar
- Revisão de estratégia de bid de uma conta (checks **G36-G41**).
- O gestor pergunta "que estratégia de lance devo usar?" ou "meu tCPA está certo?".
- Antes de escalar budget (a estratégia precisa suportar o volume).
- Ao detectar ECPC (deprecado), Manual CPC em campanha com volume, ou target irreal.

Pré-requisito: rode `conversion-audit.md` primeiro. Smart Bidding sem tracking confiável otimiza para o lugar errado. E valide volume de conversões — é o eixo de toda decisão de bid.

---

## Passo 1 — OBSERVE: puxar estratégias e volume (Maton/GAQL)

```sql
SELECT
  campaign.id,
  campaign.name,
  campaign.status,
  campaign.advertising_channel_type,
  campaign.bidding_strategy_type,
  campaign.maximize_conversions.target_cpa_micros,
  campaign.target_cpa.target_cpa_micros,
  campaign.target_roas.target_roas,
  campaign.bidding_strategy,
  metrics.conversions,
  metrics.cost_micros,
  metrics.conversions_value,
  metrics.average_cpc
FROM campaign
WHERE campaign.status = 'ENABLED'
  AND segments.date DURING LAST_30_DAYS
ORDER BY metrics.conversions DESC
```

Learning phase (G38) e portfolios (G41):

```sql
SELECT
  bidding_strategy.id,
  bidding_strategy.name,
  bidding_strategy.type,
  bidding_strategy.status,
  bidding_strategy.campaign_count
FROM bidding_strategy
```

CPA/ROAS histórico para checar razoabilidade do target (G37) — puxe 90d para ter baseline estável:

```sql
SELECT campaign.name, metrics.conversions, metrics.cost_micros, metrics.conversions_value
FROM campaign
WHERE campaign.status = 'ENABLED' AND segments.date DURING LAST_90_DAYS
```

`actual_CPA = cost_micros / conversions / 1e6`. `actual_ROAS = conversions_value / (cost_micros/1e6)`.

Match type de keywords (para o gate Broad + Smart Bidding):

```sql
SELECT ad_group_criterion.keyword.text, ad_group_criterion.keyword.match_type,
       campaign.bidding_strategy_type, metrics.cost_micros
FROM keyword_view
WHERE campaign.status = 'ENABLED' AND segments.date DURING LAST_30_DAYS
```

---

## Passo 2 — Checks e regras (G36-G41)

| Check | Sev | PASS | WARNING | FAIL |
|---|---|---|---|---|
| G36 Smart Bidding ativo | High | Toda campanha com ≥15 conv/30d usa automated bidding | Parcial, ou ECPC ainda presente | Manual CPC em campanha com dados suficientes |
| G37 Target CPA/ROAS razoável | Critical | Targets dentro de 20% do histórico | Targets 20-50% fora | tCPA <50% do CPA real |
| G38 Learning phase | High | <25% das campanhas em Learning/Learning Limited | 25-40% | >40% |
| G40 Manual CPC justificado | Medium | Manual CPC só em campanhas <15 conv/mês | Manual CPC com 15-30 conv/mês | Manual CPC com >30 conv/mês |
| G41 Portfolios | Medium | Campanhas de baixo volume agrupadas em portfolios | — | Múltiplas campanhas <15 conv rodando isoladas |

**G37 (Critical) é o mais perigoso**: tCPA <50% do CPA real sufoca o delivery, a campanha não sai do learning e o volume despenca. Corrigir setando 1.1x-1.2x do CPA histórico.

**ECPC (Enhanced CPC) deprecado (março 2025)**: qualquer campanha ainda em ECPC = **FAIL**, migração imediata para tCPA/tROAS/Maximize Conversions.

Health Score: `Σ(C_pass × W_sev × W_cat)/Σ(...) × 100`, PASS=1/WARNING=0.5/FAIL=0. Severidades: Critical 5.0, High 3.0, Medium 1.5, Low 0.5.

---

## Passo 3 — Árvore de decisão: qual estratégia usar

O eixo é volume de conversões / 30d:

```
< 15 conv/30d (cold start)
  → Maximize Clicks (Max CPC = target_CPA / (CVR × 1.5))
  → ou Manual CPC se controle total for necessário
  → NUNCA Smart Bidding aqui (< piso de dados). Learning 3-5 dias.
  → Monitorar até atingir 15+ conversões.

15-29 conv/30d
  → Maximize Conversions (sem cap)
  → Learning 7-14 dias. Migrar quando SD do CPA <20% em 14d.

30+ conv/30d, SEM valores dinâmicos
  → Target CPA
  → Setar em 1.1x-1.2x do CPA histórico
  → Ajustar no máx 10% a cada 14 dias; nunca baixar >15% de uma vez.

50+ conv/30d, COM valores dinâmicos
  → Target ROAS
  → Setar no ROAS histórico exato
  → Bid = P(conv) × Value × 1/tROAS

Brand protection
  → Target Impression Share (95-100% em brand keywords)
  → Sem requisito de dados de conversão. Só Search.
```

Casos especiais:
- **PMax**: sempre Maximize Conversions ou Maximize Conversion Value.
- **Demand Gen**: suporta Target CPC (novo), tCPA, tROAS, Max Clicks.
- **Smart Bidding Exploration** (só tROAS, 50+ conv): relaxa o target para descobrir tráfego novo (+18% categorias de query, +19% conversões). Evitar em contas de margem apertada ou já no teto de budget.

Transições:

| De | Para | Gatilho |
|---|---|---|
| Maximize Clicks | Maximize Conversions | 15+ conv/30d |
| Maximize Conversions | Target CPA | SD do CPA <20% em 14d + 30+ conv |
| Target CPA | Target ROAS | 50+ conv + valores dinâmicos disponíveis |
| Qualquer | Target Impression Share | Necessidade de brand protection |

---

## Passo 4 — Gate: Broad Match nunca sem Smart Bidding

Quality Gate crítico (G17 na auditoria de waste, espelhado aqui):
- Broad Match + Manual CPC = desperdício sem controle algorítmico de lance.
- **Ressalva de BMM legado**: o Google removeu o prefixo `+` na migração de 2021 mas manteve `matchType=BROAD` na API. BROAD + Manual CPC quase sempre é BMM legado (comporta-se como phrase), NÃO broad intencional — **não flagar como falha**. Só flagar BROAD em campanhas de Smart Bidding para revisão.
- Broad match verdadeiro é sempre pareado com Smart Bidding (tCPA/tROAS/Max Conv). Só nesse cenário Broad rende (+35% conversões, mas apenas com bons dados de conversão E gestão agressiva de negativas).

---

## Passo 5 — Portfolios (G41)

Quando usar portfolio bid strategy:
- Várias campanhas com <15 conv cada, mas somadas >30.
- Necessidade de otimização de budget cross-campaign.
- **CPC Cap Hack**: portfolio é o único jeito de setar Max CPC em tCPA/tROAS.

Regras: mínimo 3 campanhas por portfolio; agrupar por targets de CPA/ROAS similares; **nunca misturar brand e non-brand** no mesmo portfolio.

---

## Passo 6 — WRITE com confirmação

Recomende a mutação exata; execute só após "confirmo"; registre. Nunca editar em learning phase ativa.

```
MUTAÇÃO PROPOSTA (aguardando confirmação)
Campanha: [nome] (id: 12345)
Ação: bidding_strategy_type MANUAL_CPC → TARGET_CPA, target_cpa_micros = 55000000 (R$55)
Motivo: G36 FAIL (Manual CPC com 47 conv/30d), G40 FAIL (>30 conv). CPA histórico 90d = R$50 → target 1.1x = R$55 (G37 dentro de 20%)
Pré-check: tracking OK (conversion-audit passou), 47 conv/30d ≥ piso de 15
Medição (GROW): re-checar em 14d — CPA, % em learning, volume de conversões vs baseline
Confirma?
```

Se Maton não expõe escrita de estratégia de bid, degradar para passo-a-passo manual na UI.

---

## Formato de saída

```
BIDDING AUDIT — [conta] — [data]
Score de bidding: XX/100

FAILS CRÍTICOS (G37):
- [Campanha]: tCPA R$20 vs CPA real R$48 (42% — sufocando delivery) → subir para R$53

MIGRAÇÕES OBRIGATÓRIAS:
- [Campanha]: ECPC (deprecado) → tCPA. FAIL G36.
- [Campanha]: Manual CPC com 47 conv/mês → Target CPA. FAIL G40.

LEARNING PHASE (G38): X% das campanhas em learning [status vs threshold 25%]

PORTFOLIOS RECOMENDADOS (G41):
- Agrupar [camp A, B, C] (8+5+4 conv) em portfolio tCPA R$X

MUTAÇÕES AGUARDANDO CONFIRMAÇÃO: [lista]
```
