# Playbook: Auditoria Completa da Conta Google Ads

**Quando usar:** o cliente pede "audite minha conta", "account health check", "revisão geral de Google Ads",
ou quando você precisa de um diagnóstico ponta-a-ponta antes de qualquer otimização. Este é o playbook
principal — ele orquestra os 4 playbooks focados (`campaign-audit`, `keyword-audit`, `search-term-audit`,
`pmax-audit`) e agrega tudo em um único Health Score.

---

## 0. Context Intake (SEMPRE primeiro)

Nunca rode checks antes de ter estas 4 respostas. Sem elas, benchmarks e severidade ficam errados.
Combine em uma única mensagem:

1. **Indústria / Business type**: SaaS · E-commerce · Local Service · B2B Enterprise · Info Products ·
   Mobile App · Real Estate · Healthcare · Finance · Agency · Other
2. **Budget mensal**: total e breakdown por campanha/plataforma (aproximado serve)
3. **Objetivo primário**: Sales/Revenue · Leads/Demos · App Installs · Calls · Brand
4. **Plataformas ativas** e o `customer_id` (MCC + sub-conta) a auditar

Se o cliente já deu contexto ("audite meu SaaS, gasto R$20k/mês em Search+PMax"), extraia e siga sem re-perguntar.

Use o contexto para: escolher benchmarks de indústria, calibrar severidade (conta de R$2k/mês ≠ R$200k/mês),
e checar viabilidade de Smart Bidding (precisa ~15+ conv/mês).

---

## 1. Coleta de dados (Maton / GAQL)

Rode via Maton (Google Ads API, GAQL). Regras duras de coleta (ver `references/gaql-notes.md`):
- Filtrar `campaign.status = 'ENABLED'` (não `!= 'REMOVED'`, que inclui PAUSED).
- Para `search_term_view`: **não** filtrar `campaign.status`/`ad_group.status` na GAQL (INVALID_ARGUMENT).
  Filtre status na camada de aplicação. E use `LAST_30_DAYS` (não `LAST_90_DAYS` no DURING para search terms).
- Deduplicar keywords por `(ad_group_id + keyword_text + match_type)`, agregando métricas.
- Nunca pular check em silêncio: se um fetch falhar, registrar como **G-SYS1** com o erro.

### 1.1 Conversion Tracking (25%)
```sql
SELECT conversion_action.name, conversion_action.type, conversion_action.status,
       conversion_action.category, conversion_action.origin,
       conversion_action.primary_for_goal, conversion_action.counting_type,
       conversion_action.attribution_model_settings.attribution_model,
       conversion_action.enhanced_conversions_for_leads_enabled
FROM conversion_action
WHERE conversion_action.status = 'ENABLED'
```
Complemente com: status de Consent Mode v2 e Google Tag (via GTM/gtag — geralmente input manual do cliente,
pois não vêm na API), e link GA4 (`SELECT customer.id FROM google_ads_link` ou verificação no UI).
Exclua conversões system-managed de Smart Campaign de checks de DDA/counting.

### 1.2 Wasted Spend / Negatives (20%) — ver `search-term-audit.md`
```sql
SELECT search_term_view.search_term, segments.keyword.info.match_type,
       metrics.cost_micros, metrics.clicks, metrics.conversions, campaign.id, ad_group.id
FROM search_term_view
WHERE segments.date DURING LAST_30_DAYS
ORDER BY metrics.cost_micros DESC
```
+ listas de negativas: `SELECT shared_set.name, shared_set.type FROM shared_set WHERE shared_set.type = 'NEGATIVE_KEYWORDS'`.

### 1.3 Account Structure (15%) — ver `campaign-audit.md`
```sql
SELECT campaign.id, campaign.name, campaign.advertising_channel_type,
       campaign.bidding_strategy_type, campaign_budget.amount_micros,
       campaign.network_settings.target_search_network,
       campaign.network_settings.target_content_network,
       campaign.geo_target_type_setting.positive_geo_target_type
FROM campaign
WHERE campaign.status = 'ENABLED'
```

### 1.4 Keywords & Quality Score (15%) — ver `keyword-audit.md`
```sql
SELECT ad_group.id, ad_group_criterion.keyword.text,
       ad_group_criterion.keyword.match_type, ad_group_criterion.quality_info.quality_score,
       ad_group_criterion.quality_info.creative_quality_score,
       ad_group_criterion.quality_info.search_predicted_ctr,
       ad_group_criterion.quality_info.post_click_quality_score,
       metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.conversions
FROM keyword_view
WHERE campaign.status = 'ENABLED' AND ad_group.status = 'ENABLED'
  AND ad_group_criterion.status = 'ENABLED'
```
(Sem `segments.date` para evitar duplicação por dia; se precisar de período, deduplique por
`ad_group_id + keyword_text + match_type`.)

### 1.5 Ads & Assets (15%) — inclui PMax, ver `pmax-audit.md`
```sql
SELECT ad_group_ad.ad.type, ad_group_ad.ad_strength,
       ad_group_ad.ad.responsive_search_ad.headlines,
       ad_group_ad.ad.responsive_search_ad.descriptions, ad_group.id
FROM ad_group_ad
WHERE campaign.status = 'ENABLED' AND ad_group_ad.status = 'ENABLED'
```
+ extensions (`asset`, `campaign_asset`) e asset groups de PMax.

### 1.6 Settings & Targeting (10%)
Extensions, audiences (`campaign_audience_view`), placements exclusions, ad schedule
(`campaign_criterion` com `ad_schedule`), landing page (LCP via PageSpeed/CrUX — input externo).

---

## 2. Rodar as 7 categorias de checks (80 checks)

Avalie cada check aplicável como **PASS / WARNING / FAIL / N/A**. Delegue aos playbooks focados:

| Categoria | Peso | Checks | Playbook |
|-----------|------|--------|----------|
| Conversion Tracking | 25% | G42-G49, G-CT1..3, G-CTV1 (12) | (inline aqui) |
| Wasted Spend / Negatives | 20% | G13-G19, G-WS1 (8) | `search-term-audit.md` |
| Account Structure | 15% | G01-G12 (12) | `campaign-audit.md` |
| Keywords & Quality Score | 15% | G20-G25, G-KW1, G-KW2 (8) | `keyword-audit.md` |
| Ads & Assets | 15% | G26-G35, G-AD1/2, G-PM1..6, G-DG1..3, G-AI1 (18) | `pmax-audit.md` |
| Settings & Targeting | 10% | G36-G41, G50-G61 (18) | (inline aqui) |

**Critical checks primeiro** (multiplicador 5.0x, dominam o score): G42, G43, G45, G-CT1, G-CT3,
G13, G14, G16, G17, G05, G37, G21, G31, G-DG2.

### Quality Gates (regras duras — nunca violar)
- **Nunca** recomendar Broad Match sem Smart Bidding (ver heurística legacy BMM em G17).
- **3x Kill Rule**: qualquer ad group/campanha com CPA > 3x target → recomendar pausa imediata.
- **Nunca** editar campanha em learning phase ativa.
- **Privacy infra gate**: verificar tracking (Consent Mode v2, Enhanced Conversions, Google Tag)
  ANTES de recomendar qualquer otimização de bidding/budget.
- **Special Ad Categories**: sempre checar (housing/employment/credit/finance) antes de recomendações de targeting.

---

## 3. Calcular o Health Score

```
Health Score = Σ(C_pass × W_sev × W_cat) / Σ(C_total × W_sev × W_cat) × 100
```
- **C_pass**: PASS=1 · WARNING=0.5 · FAIL=0 · N/A=excluído (não entra em numerador nem denominador).
- **W_sev**: Critical=5.0 · High=3.0 · Medium=1.5 · Low=0.5.
- **W_cat**: Conversion 25% · Waste 20% · Structure 15% · Keywords 15% · Ads 15% · Settings 10%.

Calcule também o score **por categoria** (mesma fórmula restrita aos checks da categoria).

### Grades
| Grade | Score | Ação |
|-------|-------|------|
| A | 90-100 | Só otimizações menores |
| B | 75-89 | Algumas melhorias |
| C | 60-74 | Problemas notáveis |
| D | 40-59 | Problemas significativos |
| F | <40 | Intervenção urgente |

---

## 4. Priorizar findings

Ordene por **impacto** = `W_sev × estimated_impact` (impacto em receita/waste/dados). Níveis de prioridade:
- **Critical**: risco de perda de receita/dados → corrigir já.
- **High**: arrasto de performance significativo → corrigir em ≤7 dias.
- **Medium**: oportunidade de otimização → ≤30 dias.
- **Low**: best practice → backlog.

Aplique o 3x Kill Rule para montar a **kill list** (pausar imediatamente).

## 5. Quick Wins

```
Quick Win = severity ∈ {Critical, High} E estimated_fix_time < 15 min
ORDER BY (W_sev × estimated_impact) DESC
```
Candidatos típicos: G43 (Enhanced Conversions, 5min), G11 (People in, 2min), G12 (Display off Search, 2min),
G14 (negative lists, 10min), G17 (Broad→Smart/Exact, 5min), G05 (split brand, 10min), G50 (sitelinks, 10min),
G-PM6 (negativas em PMax, 10min).

---

## 6. Formato de saída

Emita **JSON** seguido de **resumo executivo** em prosa.

```json
{
  "account_id": "123-456-7890",
  "audit_date": "2026-07-03",
  "context": {"industry": "SaaS", "monthly_budget": 20000, "primary_goal": "Leads", "platforms": ["Search","PMax"]},
  "health_score": 63.4,
  "grade": "C",
  "categories": {
    "conversion_tracking": {"score": 55.0, "weight": 0.25, "pass": 5, "warning": 3, "fail": 4, "na": 0},
    "wasted_spend":        {"score": 48.0, "weight": 0.20, "pass": 3, "warning": 2, "fail": 3, "na": 0},
    "account_structure":   {"score": 72.0, "weight": 0.15, "pass": 8, "warning": 2, "fail": 2, "na": 0},
    "keywords_qs":         {"score": 68.0, "weight": 0.15, "pass": 5, "warning": 2, "fail": 1, "na": 0},
    "ads_assets":          {"score": 70.0, "weight": 0.15, "pass": 10, "warning": 5, "fail": 3, "na": 0},
    "settings_targeting":  {"score": 80.0, "weight": 0.10, "pass": 14, "warning": 3, "fail": 1, "na": 0}
  },
  "top_findings": [
    {"id": "G-CT1", "severity": "Critical", "impact": "Dupla contagem infla conversões ~30%, corrompe Smart Bidding",
     "action": "Desativar contagem nativa OU import GA4 para a ação duplicada", "owner": "tracking", "eta_days": 2},
    {"id": "G16", "severity": "Critical", "impact": "18% do spend em termos irrelevantes (R$3.6k/mês)",
     "action": "Adicionar 40 negativas dos top wasters (>R$50, 0 conv)", "owner": "media_buyer", "eta_days": 1},
    {"id": "G45", "severity": "Critical", "impact": "Consent Mode básico: perda de 15-25% de sinal EEA",
     "action": "Upgrade para Advanced Consent Mode v2", "owner": "dev", "eta_days": 7}
  ],
  "quick_wins": [
    {"id": "G43", "action": "Ativar Enhanced Conversions", "eta_min": 5, "expected_impact": "+~10% conversões medidas"},
    {"id": "G12", "action": "Desabilitar Display Network em campanhas de Search", "eta_min": 2, "expected_impact": "reduz waste"},
    {"id": "G-PM6", "action": "Adicionar negativas campaign-level no PMax", "eta_min": 10, "expected_impact": "~15% redução de custo"}
  ],
  "kill_list": [
    {"entity": "AdGroup 'generic-terms'", "reason": "CPA R$310 = 3.4x target R$90 (3x Kill Rule)"}
  ],
  "data_gaps": [{"check": "G59", "reason": "LCP não fornecido — landing page não auditada"}]
}
```

**Resumo executivo** (após o JSON): 1 parágrafo com grade + score, os 3 problemas Critical,
os 3 Quick Wins de maior ROI, e o próximo passo recomendado. Sem branding/footer.

---

## 7. Plano de ação

Monte tabela ordenada por prioridade: `Ação | Check(s) | Owner | ETA | Impacto esperado | Depende de`.
Sempre liste Quick Wins no topo (executáveis hoje) e a kill list logo após. Marque dependências
do Privacy Infra Gate (nenhuma otimização de bidding sai antes de tracking validado).
