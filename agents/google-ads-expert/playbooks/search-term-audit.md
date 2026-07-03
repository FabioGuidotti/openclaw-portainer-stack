# Playbook: Auditoria de Search Terms & Negativas (G13-G19, G-WS1)

**Quando usar:** o cliente quer caçar wasted spend, revisar termos de busca, montar/expandir listas de
negativas, ou entender close variants e visibilidade de search terms. Cobre a categoria
**Wasted Spend / Negatives (peso 20%)** — a segunda de maior peso, logo atrás de Conversion Tracking.

---

## 0. Context Intake (primeiro)

Confirme os 4 itens (indústria, budget, objetivo, plataformas + `customer_id`). O threshold de "wasted"
é relativo ao budget: o corte padrão é **>$10 de spend E 0 conversões** (ajuste a moeda e escala para o
budget do cliente — em conta de R$200k/mês, use um piso proporcionalmente maior).

---

## 1. Coleta de dados (Maton / GAQL) — cuidado com search_term_view

Regras duras (ver `references/gaql-notes.md`):
- **NÃO** filtre `campaign.status`, `ad_group.status` nem `search_term_view.status` na GAQL de
  `search_term_view` → retorna INVALID_ARGUMENT (campos incompatíveis/removidos na API v20+).
  **Filtre status na camada de aplicação** depois de buscar.
- Use `DURING LAST_30_DAYS`. **Não** use `LAST_90_DAYS` no DURING de search terms (INVALID_VALUE_WITH_DURING_OPERATOR).
  Se precisar de mais histórico, use ranges de data explícitos (`segments.date BETWEEN '...' AND '...'`).
- Ordene por `metrics.cost_micros DESC` para capturar primeiro os maiores gastadores (crítico para G19).

```sql
SELECT search_term_view.search_term,
       segments.keyword.info.text, segments.keyword.info.match_type,
       segments.search_term_match_type,
       campaign.id, ad_group.id,
       metrics.cost_micros, metrics.clicks, metrics.impressions, metrics.conversions
FROM search_term_view
WHERE segments.date DURING LAST_30_DAYS
ORDER BY metrics.cost_micros DESC
```
Depois, na aplicação: descarte linhas de campanhas/ad groups não-ENABLED (junte com a lista de
campanhas/ad groups ENABLED buscada à parte).

Listas de negativas (para G14/G15):
```sql
SELECT shared_set.id, shared_set.name, shared_set.type, shared_set.member_count
FROM shared_set
WHERE shared_set.type = 'NEGATIVE_KEYWORDS' AND shared_set.status = 'ENABLED'
```
```sql
SELECT campaign.id, campaign.name, campaign_shared_set.shared_set
FROM campaign_shared_set
WHERE campaign.status = 'ENABLED'
```
Negativas campaign-level diretas:
```sql
SELECT campaign.id, campaign_criterion.keyword.text, campaign_criterion.keyword.match_type
FROM campaign_criterion
WHERE campaign_criterion.type = 'KEYWORD' AND campaign_criterion.negative = TRUE
  AND campaign.status = 'ENABLED'
```

---

## 2. Checks (G13-G19, G-WS1)

| ID | Check | Severity | PASS | WARNING | FAIL |
|----|-------|----------|------|---------|------|
| G13 | Recência da revisão de search terms | Critical | Revisados nos últimos 14 dias | 15-30 dias | >30 dias sem revisão |
| G14 | Listas de negativas existem | Critical | ≥3 listas temáticas (Competitor, Jobs, Free, Irrelevant) | 1-2 listas | Nenhuma lista |
| G15 | Negativas aplicadas em nível de conta | High | Listas aplicadas em account/todas as campanhas | Só em algumas campanhas | Não aplicadas |
| G16 | Wasted spend em termos irrelevantes | Critical | <5% do spend (30d) | 5-15% | >15% |
| G17 | Broad match + smart bidding pairing | Critical | Nenhum Broad em Manual CPC (ver BMM) | N/A | Broad + Manual CPC ativo |
| G18 | Poluição por close variants | High | Exact/Phrase não disparam close variants irrelevantes | Problemas menores | Spend relevante em close variants irrelevantes |
| G19 | Visibilidade de search terms | Medium | >60% do spend de search term é visível | 40-60% | <40% |
| G-WS1 | Keywords zero-conversão | High | Nenhuma com >100 clicks e 0 conv | 1-3 keywords | >3 keywords com >100 clicks, 0 conv |

### Cálculos e notas de precisão
- **G16 / G-WS1 — definição de "waste"**: só flague um search term como desperdício se tiver
  **>$10 de spend E 0 conversões**. Termos long-tail com <$10 são exploração normal, não waste.
  Reporte os **top 10 wasters** com spend e clicks.
- **G19 — visibilidade**: `visibilidade = totalVisibleSpend / totalSpend`. Use **TODOS** os search terms
  buscados (ordenados por cost DESC), **antes** de qualquer truncamento/top-N. Erro comum: somar cost de
  um subset truncado (ex.: top 500 de 2000) subestima a visibilidade. Search terms de baixo volume ficam
  ocultos por privacidade — o gap entre spend total da campanha e spend somável em search_term_view é o "hidden".
- **G14/G15 — cobertura**: conte negativas campaign-level **E** Shared Negative Lists. Campanhas cobertas
  por lista compartilhada **não** devem ser flagadas como "sem negativas". Reporte breakdown por campanha:
  negativas diretas vs. listas atribuídas.
- **G17 — legacy BMM**: `BROAD` + Manual CPC ≈ BMM legado (2021 removeu o '+', manteve matchType=BROAD),
  comporta-se como phrase. **Não** flague como falha. Só flague BROAD em campanha de Smart Bidding sem
  gestão forte de negativas.
- **G13 — recência**: use a Change History / data da última adição de negativa como proxy da última revisão.

### Recência e listas temáticas recomendadas
Listas mínimas (G14): **Competitor** (marcas concorrentes), **Jobs/Careers** ("vaga", "emprego", "salário"),
**Free/DIY** ("grátis", "gratuito", "como fazer"), **Irrelevant** (termos do vertical que não convertem).

---

## 3. Quality Gates aplicáveis

- **Privacy infra gate**: se tracking (G-CT1/G43/G45) está quebrado, "0 conversões" pode ser falso
  negativo de medição, não waste real. Verifique tracking ANTES de recomendar pausar termos por 0 conv.
- **3x Kill Rule**: search terms/ad groups com CPA > 3x target → candidatos a negativa imediata ou pausa.
- **Nunca Broad sem Smart Bidding**: ao recomendar mudança de match type para conter close variants,
  cheque a bidding strategy da campanha.

---

## 4. Scoring (categoria isolada)

```
Score_waste = Σ(C_pass × W_sev) / Σ(C_total × W_sev) × 100
```
C_pass: PASS=1, WARNING=0.5, FAIL=0, N/A=excluído. W_sev: Critical=5.0, High=3.0, Medium=1.5, Low=0.5.
No audit completo entra com W_cat=20%. Grades: A 90-100 · B 75-89 · C 60-74 · D 40-59 · F <40.

---

## 5. Saída

```json
{
  "category": "wasted_spend",
  "score": 52.0,
  "grade": "D",
  "metrics": {
    "wasted_spend_pct": 0.17, "wasted_spend_value": 3400,
    "search_term_visibility_pct": 0.58, "negative_lists_count": 1,
    "zero_conv_high_click_keywords": 5
  },
  "top_wasters": [
    {"term": "curso gratis marketing", "cost": 420, "clicks": 88, "conversions": 0},
    {"term": "vaga analista trafego", "cost": 310, "clicks": 61, "conversions": 0}
  ],
  "findings": [
    {"id": "G16", "result": "FAIL", "severity": "Critical",
     "detail": "17% do spend (R$3.4k/mês) em termos irrelevantes, 0 conv",
     "action": "Adicionar 35 negativas dos top wasters; criar listas Free e Jobs",
     "owner": "media_buyer", "eta_days": 1, "quick_win": true},
    {"id": "G14", "result": "WARNING", "severity": "Critical",
     "detail": "Só 1 lista de negativas; faltam Competitor, Jobs, Free",
     "action": "Criar 3 listas temáticas e aplicar em account-level",
     "owner": "media_buyer", "eta_days": 1, "quick_win": true},
    {"id": "G13", "result": "FAIL", "severity": "Critical",
     "detail": "Search terms não revisados há 47 dias",
     "action": "Estabelecer cadência quinzenal de revisão", "owner": "media_buyer",
     "eta_days": 1, "quick_win": true}
  ],
  "quick_wins": ["G16", "G14", "G13"],
  "kill_list": []
}
```

Feche com 1 parágrafo: nota da categoria, o valor de waste mensal estimado, e as negativas de maior
economia imediata (ordem: negativar top wasters → criar listas temáticas → cadência de revisão).
Sem branding/footer.
