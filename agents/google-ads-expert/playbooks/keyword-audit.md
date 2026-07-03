# Playbook: Auditoria de Keywords & Quality Score (G20-G25, G-KW1/2)

**Quando usar:** o cliente quer entender qualidade de keywords, Quality Score baixo, distribuição de
match type, keywords sem impressão, relevância keyword→ad, ou canibalização entre ad groups. Cobre a
categoria **Keywords & Quality Score (peso 15%)**.

---

## 0. Context Intake (primeiro)

Confirme os 4 itens (indústria, budget, objetivo, plataformas + `customer_id`). QS é relativo à
concorrência da indústria; benchmark de CTR esperado depende do vertical. Smart Bidding só é
recomendável com ~15+ conv/mês — isso muda a leitura de match type (ver Quality Gate abaixo).

---

## 1. Coleta de dados (Maton / GAQL) — com dedup obrigatório

**Problema:** `keyword_view + segments.date DURING LAST_30_DAYS` retorna 1 linha por keyword por dia.
Keyword ativa 5 dias = 5 linhas; com BROAD+PHRASE = 10 linhas. **Solução:** remova `segments.date` da
query (elimina duplicação na origem) OU deduplique por `(ad_group_id + keyword_text + match_type)`
agregando impressions/clicks/cost/conversions.

Filtrar sempre ENABLED em todos os níveis.

```sql
SELECT ad_group.id, ad_group.name, campaign.id,
       ad_group_criterion.keyword.text, ad_group_criterion.keyword.match_type,
       ad_group_criterion.quality_info.quality_score,
       ad_group_criterion.quality_info.creative_quality_score,
       ad_group_criterion.quality_info.search_predicted_ctr,
       ad_group_criterion.quality_info.post_click_quality_score,
       metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.conversions
FROM keyword_view
WHERE campaign.status = 'ENABLED' AND ad_group.status = 'ENABLED'
  AND ad_group_criterion.status = 'ENABLED'
```
(Sem `segments.date` → uma linha por keyword. QS já é o valor atual, não precisa de janela temporal.)

Componentes de QS retornam enum:
- `search_predicted_ctr` → expected CTR (G22): ABOVE_AVERAGE / AVERAGE / BELOW_AVERAGE
- `creative_quality_score` → ad relevance (G23)
- `post_click_quality_score` → landing page experience (G24)

Para relevância keyword→ad (G-KW2/G35), traga também os headlines dos RSAs por ad group:
```sql
SELECT ad_group.id, ad_group_ad.ad.responsive_search_ad.headlines
FROM ad_group_ad
WHERE campaign.status = 'ENABLED' AND ad_group_ad.status = 'ENABLED'
  AND ad_group_ad.ad.type = 'RESPONSIVE_SEARCH_AD'
```

---

## 2. Checks (G20-G25, G-KW1, G-KW2)

| ID | Check | Severity | PASS | WARNING | FAIL |
|----|-------|----------|------|---------|------|
| G20 | QS médio (impression-weighted) | High | ≥7 | 5-6 | ≤4 |
| G21 | Keywords com QS crítico | Critical | <10% com QS ≤3 | 10-25% com QS ≤3 | >25% com QS ≤4 |
| G22 | Componente Expected CTR | High | <20% "Below Average" | 20-35% | >35% |
| G23 | Componente Ad Relevance | High | <20% "Below Average" | 20-35% | >35% |
| G24 | Componente Landing Page Exp. | High | <15% "Below Average" | 15-30% | >30% |
| G25 | QS do top keywords | Medium | Top 20 (por spend) todos QS ≥7 | Alguns em QS 5-6 | Top keywords com QS ≤4 |
| G-KW1 | Zero-impression keywords | Medium | Nenhuma com 0 impr em 30d | <10% zero-impression | >10% com 0 impressões |
| G-KW2 | Relevância keyword→ad | High | Headlines contêm variantes da keyword primária | Inclusão parcial | Sem variantes nos headlines |

### Cálculos e notas de precisão
- **G20 (impression-weighted)**: `QS_médio = Σ(QS_i × impressions_i) / Σ(impressions_i)`. Não use média simples.
- **G21/G22/G23/G24**: percentuais sobre keywords com impressions > 0 (dedupadas). QS de keyword sem
  impressão é ruído.
- **G25**: ordene por `cost_micros` DESC, pegue top 20 únicas.
- **G-KW1**: só conte como zero-impression keywords ENABLED em ad groups/campanhas ENABLED. Keywords
  dormentes não servem anúncio, mas sinalizam poda ou match type restritivo demais.

### Distribuição de match type
Reporte a distribuição (EXACT / PHRASE / BROAD) por spend e por conversões. Lembre da heurística
**legacy BMM**: `match_type = BROAD` + Manual CPC quase sempre é BMM legado (comporta-se como phrase),
não broad intencional. Broad intencional está SEMPRE com Smart Bidding.

### Canibalização (cross-ad-group)
Detecte a mesma keyword (ou variantes próximas) ENABLED em >1 ad group/campanha competindo entre si.
Sinais: mesma `keyword.text` normalizada em ad groups diferentes, ambos com impressões. Recomende
consolidar no ad group de maior QS/CVR e negativar nos demais.

---

## 3. Quality Gates aplicáveis

- **Nunca Broad sem Smart Bidding**: se achar BROAD em campanha com Manual CPC → não trate como broad
  intencional; classifique como legacy BMM e recomende migração a Smart Bidding OU conversão a Phrase/Exact.
  Só flague como falha de G17 quando BROAD estiver em campanha de Smart Bidding sem gestão de negativas.
- **Privacy infra gate**: QS e recomendações de bidding dependem de tracking correto — se G-CT1/G43/G45
  estão FAIL, sinalize que otimização de keyword-level bids fica bloqueada até o tracking ser corrigido.

---

## 4. Scoring (categoria isolada)

```
Score_keywords = Σ(C_pass × W_sev) / Σ(C_total × W_sev) × 100
```
C_pass: PASS=1, WARNING=0.5, FAIL=0, N/A=excluído. W_sev: Critical=5.0, High=3.0, Medium=1.5, Low=0.5.
No audit completo entra com W_cat=15%. Grades: A 90-100 · B 75-89 · C 60-74 · D 40-59 · F <40.

---

## 5. Saída

```json
{
  "category": "keywords_qs",
  "score": 66.0,
  "grade": "C",
  "metrics": {
    "impression_weighted_qs": 6.1,
    "match_type_split_by_cost": {"EXACT": 0.34, "PHRASE": 0.41, "BROAD": 0.25},
    "pct_qs_le3": 0.18, "pct_expected_ctr_below": 0.28, "pct_ad_relevance_below": 0.22,
    "pct_landing_below": 0.12, "pct_zero_impression": 0.14
  },
  "findings": [
    {"id": "G21", "result": "WARNING", "severity": "Critical",
     "detail": "18% das keywords com QS ≤3 concentram 22% do spend",
     "action": "Pausar/reescrever ads dos ad groups afetados; alinhar landing page",
     "owner": "media_buyer", "eta_days": 7, "quick_win": false},
    {"id": "G-KW2", "result": "FAIL", "severity": "High",
     "detail": "6 ad groups sem a keyword primária em nenhum headline",
     "action": "Inserir variante da keyword em ≥2 headlines por RSA", "owner": "copywriter",
     "eta_days": 3, "quick_win": false},
    {"id": "G-KW1", "result": "WARNING", "severity": "Medium",
     "detail": "14% keywords com 0 impressões em 30d", "action": "Podar ou revisar match type restritivo",
     "owner": "media_buyer", "eta_days": 5, "quick_win": false}
  ],
  "cannibalization": [
    {"keyword": "software crm", "ad_groups": ["CRM-Geral", "CRM-Vendas"],
     "action": "Consolidar no ad group de maior CVR, negativar no outro"}
  ],
  "quick_wins": []
}
```

Feche com 1 parágrafo: nota da categoria, o componente de QS mais fraco (expected CTR / ad relevance /
landing page) e o plano de subir QS. Sem branding/footer.
