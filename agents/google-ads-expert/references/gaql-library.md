# Biblioteca GAQL — Motor de Dados da Auditoria Google Ads

<!-- Queries e notas de precisão derivadas do claude-ads (MIT): gaql-notes.md + google-audit.md. API v20+. -->

Esta é a biblioteca de queries **GAQL (Google Ads Query Language)** que o agente executa ao vivo via Maton para alimentar cada check da auditoria Google (80 checks, 7 categorias). É o motor de dados: cada bloco declara **quais check IDs ele alimenta**, a **query GAQL** pronta para execução, e as **notas de precisão** que evitam falsos positivos. As notas não são opcionais — elas codificam incompatibilidades reais da API v20+, deduplicação de keyword, escopo de filtro e a heurística de legacy BMM. Ignorá-las gera centenas de falhas falsas. Ao final, a seção **Fora do GAQL** lista o que NÃO é obtenível por query e permanece manual.

---

## Convenções globais (valem para todas as queries)

- **Janela padrão:** `segments.date DURING LAST_30_DAYS` para métricas. Para busca de termos, `LAST_30_DAYS` é o limite seguro com search terms; `LAST_90_DAYS` só quando o recurso suportar.
- **Escopo ENABLED:** filtrar `campaign.status = 'ENABLED'` (não `!= 'REMOVED'`, que inclui PAUSED). Campanhas/ad groups pausados geram falsos positivos.
- **Deduplicação de keyword:** `keyword_view` + `segments.date` retorna uma linha por keyword por dia. Deduplicar por `(ad_group_id + keyword_text + match_type)` no fetch e agregar métricas. Alternativa: remover `segments.date` da query para eliminar a duplicação de data na origem.
- **Ordenação por custo:** sempre `ORDER BY metrics.cost_micros DESC` em queries de spend, para capturar os maiores gastadores primeiro (evita subestimar visibilidade ao truncar).
- **Micros:** `cost_micros` e valores monetários vêm em micros (÷ 1.000.000 para a moeda da conta).
- **Erros:** rastrear cada fetch que falhar e reportar em G-SYS1 (nunca pular check em silêncio).

> **Incompatibilidades conhecidas (API v20+):**
> | Recurso | Campo incompatível | Correção |
> |---------|--------------------|----------|
> | `search_term_view` | `campaign.status`, `ad_group.status` | filtrar status na aplicação, não no GAQL |
> | `search_term_view` | `search_term_view.status` | campo removido em v20 |
> | `asset_group_signal` | `audience_signal` | usar `resource_name` |
> | cláusula DURING | `LAST_90_DAYS` (search terms) | usar `LAST_30_DAYS` |

---

## 1. Account Structure

**Alimenta:** G01, G02, G03, G04, G05, G06, G07, G08, G09, G11, G12.

### Bloco `campaigns-structure`
Campanhas ENABLED com tipo, canal, budget, bidding e status de serving. Base para G01, G04, G06, G08, G09.

```sql
SELECT
  campaign.id,
  campaign.name,
  campaign.advertising_channel_type,
  campaign.advertising_channel_sub_type,
  campaign.bidding_strategy_type,
  campaign.status,
  campaign.primary_status,
  campaign_budget.amount_micros,
  metrics.cost_micros,
  metrics.conversions,
  metrics.impressions
FROM campaign
WHERE campaign.status = 'ENABLED'
  AND segments.date DURING LAST_30_DAYS
ORDER BY metrics.cost_micros DESC
```

**Notas de precisão:**
- G04: para contas multi-local, remover identificadores geográficos (cidade, estado, CEP, "Norte/Sul") do nome antes de contar objetivos únicos. "Divórcio - SP", "Divórcio - Campinas" = 1 objetivo em 2 geos, não 2. Preservar termos PPC-relevantes (brand, nonbrand, pmax, remarketing).
- G09: `campaign.primary_status` = `LIMITED` sinaliza budget cap; cruzar com hora do cap exige relatório intraday (não sempre disponível via GAQL — reportar como sinal, não certeza).
- G01/G02: convenção de nomenclatura é avaliação de padrão sobre `campaign.name`/`ad_group.name`, não há campo booleano.

### Bloco `ad-groups`
Ad groups ENABLED de campanhas ENABLED. Base para G02, G03.

```sql
SELECT
  ad_group.id,
  ad_group.name,
  campaign.id,
  campaign.name,
  ad_group.status,
  metrics.impressions
FROM ad_group
WHERE campaign.status = 'ENABLED'
  AND ad_group.status = 'ENABLED'
  AND segments.date DURING LAST_30_DAYS
```

### Bloco `network-and-location-settings`
Configurações de rede e método de localização por campanha. Base para G11, G12.

```sql
SELECT
  campaign.id,
  campaign.name,
  campaign.network_settings.target_google_search,
  campaign.network_settings.target_search_network,
  campaign.network_settings.target_content_network,
  campaign.network_settings.target_partner_search_network,
  campaign.geo_target_type_setting.positive_geo_target_type,
  campaign.geo_target_type_setting.negative_geo_target_type
FROM campaign
WHERE campaign.status = 'ENABLED'
```

**Notas de precisão:**
- G11: `positive_geo_target_type = 'PRESENCE'` = "People in" (PASS para local); `PRESENCE_OR_INTEREST` = "in or interested in" (FAIL para negócio local).
- G12: `target_content_network = true` em campanha de Search = FAIL. `target_search_network = false` (Search Partners OFF) = WARNING (reach incremental perdido), não Fail.

### Bloco `brand-classification` (para G05, G07, G-PM3)
Composição de keywords por campanha para classificar brand vs non-brand. Ver query de keywords no bloco 3; classificar campanha por >50% de keywords de marca.

**Notas de precisão:** não confiar só no nome da campanha. Derivar tokens de marca do nome da conta/negócio e escanear o texto real das keywords. Campanha com >50% de keywords de marca = campanha de marca. Isso pega campanhas mal rotuladas.

---

## 2. Wasted Spend / Negatives

**Alimenta:** G13, G14, G15, G16, G17, G18, G19, G-WS1.

### Bloco `wasted-search-terms`
Termos de busca por custo. Base para G13, G16, G18, G19.

```sql
SELECT
  search_term_view.search_term,
  segments.search_term_match_type,
  campaign.id,
  ad_group.id,
  metrics.cost_micros,
  metrics.clicks,
  metrics.conversions,
  metrics.impressions
FROM search_term_view
WHERE segments.date DURING LAST_30_DAYS
ORDER BY metrics.cost_micros DESC
```

**Notas de precisão (críticas):**
- **NÃO** incluir `campaign.status` nem `ad_group.status` na query (INVALID_ARGUMENT). Trazer `campaign.id`/`ad_group.id` e filtrar status na aplicação, cruzando com os blocos `campaigns-structure`/`ad-groups`.
- **NÃO** usar `search_term_view.status` (removido em v20).
- **DURING:** manter `LAST_30_DAYS` para search terms (`LAST_90_DAYS` dá INVALID_VALUE_WITH_DURING_OPERATOR neste recurso).
- G16/G-WS1: só flagar como waste termos com **>R$ 50 (ou equiv.) de custo E 0 conversões**. Long-tail com <R$ 50 é exploração normal, não desperdício. Reportar top 10 wasters.
- G19: `totalVisibleSpend` deve somar **todos** os termos retornados antes de qualquer truncamento/top-N. Somar só um subconjunto truncado subestima a visibilidade. Por isso o `ORDER BY cost DESC`.

### Bloco `negative-keyword-lists`
Listas de negativas compartilhadas (shared sets) e suas keywords. Base para G14, G15.

```sql
SELECT
  shared_set.id,
  shared_set.name,
  shared_set.type,
  shared_set.status,
  shared_set.member_count
FROM shared_set
WHERE shared_set.type = 'NEGATIVE_KEYWORDS'
  AND shared_set.status = 'ENABLED'
```

Aplicação das listas às campanhas (`campaign_shared_set`):

```sql
SELECT
  campaign.id,
  campaign.name,
  shared_set.id,
  shared_set.name
FROM campaign_shared_set
WHERE campaign.status = 'ENABLED'
```

Negativas em nível de campanha (`campaign_criterion`):

```sql
SELECT
  campaign.id,
  campaign_criterion.keyword.text,
  campaign_criterion.keyword.match_type,
  campaign_criterion.negative
FROM campaign_criterion
WHERE campaign_criterion.type = 'KEYWORD'
  AND campaign_criterion.negative = TRUE
  AND campaign.status = 'ENABLED'
```

**Notas de precisão:**
- G14/G15: contar **tanto** negativas em nível de campanha **quanto** shared negative lists ao avaliar cobertura. Campanhas cobertas por lista compartilhada **não** devem ser flagadas como "sem negativas". Reportar breakdown por campanha (negativas diretas vs lista compartilhada).
- G14 alvo: ≥3 listas temáticas (Competitor, Jobs, Free, Irrelevant) = PASS.

### Bloco `broad-match-bidding` (G17)
Keywords BROAD cruzadas com a estratégia de lance da campanha. Ver query de keywords no bloco 3; a classificação BROAD + estratégia acontece na aplicação.

**Notas de precisão (legacy BMM):**
- Google removeu o prefixo '+' do Broad Match Modified na migração de 2021 mas manteve `match_type = 'BROAD'` na API.
- **BROAD + Manual CPC ≈ legacy BMM** (comporta-se como phrase). **NÃO flagar como falha.**
- Broad match intencional é **sempre** pareado com Smart Bidding (tCPA, tROAS, Maximize Conversions/Value). Só flagar BROAD para revisão em campanhas com Smart Bidding.
- Sem essa heurística, contas com legacy BMM geram centenas de falsos FAILs em G17.

---

## 3. Keywords & Quality Score

**Alimenta:** G20, G21, G22, G23, G24, G25, G-KW1, G-KW2 (e cruza com G03, G05, G17).

### Bloco `keywords-quality`
Keywords ENABLED com Quality Score e componentes. Base para G20-G25, G-KW1.

```sql
SELECT
  ad_group.id,
  campaign.id,
  ad_group_criterion.keyword.text,
  ad_group_criterion.keyword.match_type,
  ad_group_criterion.quality_info.quality_score,
  ad_group_criterion.quality_info.creative_quality_score,
  ad_group_criterion.quality_info.post_click_quality_score,
  ad_group_criterion.quality_info.search_predicted_ctr,
  metrics.impressions,
  metrics.clicks,
  metrics.cost_micros,
  metrics.conversions
FROM keyword_view
WHERE campaign.status = 'ENABLED'
  AND ad_group.status = 'ENABLED'
  AND ad_group_criterion.status = 'ENABLED'
  AND segments.date DURING LAST_30_DAYS
ORDER BY metrics.cost_micros DESC
```

**Notas de precisão (críticas):**
- **Deduplicar por `(ad_group_id + keyword_text + match_type)`** e agregar métricas. Com `segments.date`, uma keyword ativa 5 dias = 5 linhas; BROAD + PHRASE = 2 keywords, não 1. A dedup correta impacta G03, G05, G07, G17, G21, G25, G-KW1 e ~10 outros.
- G20: QS médio **ponderado por impressão** ≥7 = PASS. Não média simples.
- G21: <10% de keywords com QS ≤3 = PASS.
- G22: `search_predicted_ctr = 'BELOW_AVERAGE'` — <20% das keywords = PASS.
- G23: `creative_quality_score = 'BELOW_AVERAGE'` (ad relevance) — <20% = PASS.
- G24: `post_click_quality_score = 'BELOW_AVERAGE'` (landing page exp.) — <15% = PASS.
- G-KW1: keywords com `metrics.impressions = 0` nos 30d — <10% = PASS. (Query completa sem filtro de impressão para poder contar zeros.)
- G03: ao avaliar coerência de tema, contar só keywords com impressões >0, ad groups ENABLED, deduplicar por texto, e excluir stopwords (ex.: "advogado") do score de coerência.

### Bloco `keyword-ad-relevance` (G-KW2, G35)
Headlines dos RSAs cruzadas com keywords do ad group. Ver bloco 4 (`responsive-search-ads`) + bloco `keywords-quality`; a checagem de "headline contém variante da keyword primária" acontece na aplicação.

---

## 4. Ads & Assets

**Alimenta:** G26, G27, G28, G29, G30, G31, G32, G33, G34, G35, G-AD1, G-AD2, e PMax G-PM1..6.

### Bloco `responsive-search-ads`
RSAs ENABLED com assets. Base para G26, G27, G28, G29, G30, G35, G-AD1, G-AD2.

```sql
SELECT
  ad_group.id,
  campaign.id,
  ad_group_ad.ad.id,
  ad_group_ad.ad.type,
  ad_group_ad.ad.responsive_search_ad.headlines,
  ad_group_ad.ad.responsive_search_ad.descriptions,
  ad_group_ad.ad_strength,
  ad_group_ad.status,
  ad_group_ad.ad.final_urls,
  metrics.ctr,
  metrics.impressions,
  metrics.clicks
FROM ad_group_ad
WHERE campaign.status = 'ENABLED'
  AND ad_group.status = 'ENABLED'
  AND ad_group_ad.status = 'ENABLED'
  AND ad_group_ad.ad.type = 'RESPONSIVE_SEARCH_AD'
  AND segments.date DURING LAST_30_DAYS
```

**Notas de precisão:**
- G26: contar RSAs por ad group (≥1 = PASS, ≥2 recomendado). Ad group ENABLED sem RSA = FAIL.
- G27: contar headlines únicas no array `responsive_search_ad.headlines` (≥8 = PASS, ideal 12-15).
- G28: descriptions ≥3 = PASS.
- G29: `ad_group_ad.ad_strength` ∈ {`POOR`, `AVERAGE`, `GOOD`, `EXCELLENT`}. Qualquer `POOR` = FAIL.
- G30: pinning vem em cada headline/description (campo `pinned_field`); over-pinning (todas as posições) = WARNING.
- G-AD1 (ad freshness): requer `ad_group_ad.ad.added_by_google_ads` + data de criação; se indisponível, aproximar por ausência de novos IDs de anúncio recentes — pode virar sinal manual.
- G-AD2: comparar `metrics.ctr` com benchmark de indústria (fonte externa, ver `knowledge/benchmarks.md`).

### Bloco `pmax-campaigns`
Campanhas Performance Max. Base para G06, G07, G-PM3.

```sql
SELECT
  campaign.id,
  campaign.name,
  campaign.status,
  metrics.cost_micros,
  metrics.conversions,
  metrics.conversions_value
FROM campaign
WHERE campaign.advertising_channel_type = 'PERFORMANCE_MAX'
  AND campaign.status = 'ENABLED'
  AND segments.date DURING LAST_30_DAYS
```

### Bloco `pmax-asset-groups`
Asset groups e densidade de assets. Base para G31, G32, G33, G-PM2.

```sql
SELECT
  asset_group.id,
  asset_group.name,
  asset_group.campaign,
  asset_group.status,
  asset_group.ad_strength,
  asset_group.final_urls
FROM asset_group
WHERE asset_group.status = 'ENABLED'
```

Contagem/tipo de assets por asset group (`asset_group_asset`):

```sql
SELECT
  asset_group.id,
  asset_group_asset.field_type,
  asset_group_asset.asset,
  asset.type
FROM asset_group_asset
WHERE asset_group_asset.status = 'ENABLED'
```

**Notas de precisão:**
- G31: densidade máxima = ≥20 imagens, ≥5 logos, ≥5 vídeos nativos por grupo. PMax precisa de 30-50+ conversões/mês para otimizar; <30 conv/mês = WARNING (dados insuficientes). Vídeo auto-gerado a partir de imagens = WARNING (subir vídeo nativo).
- G32: vídeo nativo em todos os formatos (16:9, 1:1, 9:16). Contar `field_type` de vídeo por dimensão via `asset.type`.
- G33: ≥2 asset groups por PMax (segmentados por intenção) = PASS.
- G-PM2: `asset_group.ad_strength` — `GOOD`/`EXCELLENT` = PASS, `AVERAGE` = WARNING, `POOR` = FAIL.

### Bloco `pmax-signals-and-themes` (G-PM1, G-PM4)
Sinais de audiência e search themes por asset group (`asset_group_signal`).

```sql
SELECT
  asset_group.id,
  asset_group_signal.resource_name
FROM asset_group_signal
WHERE asset_group.status = 'ENABLED'
```

**Notas de precisão:**
- **NÃO** usar o campo `audience_signal` (UNRECOGNIZED_FIELD). Usar `resource_name` e resolver o tipo de sinal na aplicação.
- G-PM4: search themes (até 50 por asset group) — <5 = WARNING, 0 = FAIL.

### Bloco `pmax-negatives` (G-PM5, G-PM6)
Negativas em nível de campanha PMax. Usar `campaign_criterion` (ver bloco 2) filtrando por campanhas PERFORMANCE_MAX.

**Notas de precisão:** negativas em nível de campanha agora disponíveis para TODOS os anunciantes PMax (2025). G-PM6: ausência de negativas de campanha na PMax = FAIL (quick win 10 min). G-PM5: brand + irrelevant negatives aplicadas = PASS.

---

## 5. Conversion Tracking

**Alimenta:** G42, G43, G46, G47, G48, G49, G-CT1, G-CT2, G-CTV1. (G44 server-side, G45 Consent Mode, G-CT3 tag firing = parcial/manual — ver notas.)

### Bloco `conversion-actions`
Ações de conversão com status, tipo, contagem, atribuição e Enhanced Conversions. Base para G42, G43, G46, G47, G48, G49, G-CT1.

```sql
SELECT
  conversion_action.id,
  conversion_action.name,
  conversion_action.status,
  conversion_action.type,
  conversion_action.category,
  conversion_action.origin,
  conversion_action.primary_for_goal,
  conversion_action.counting_type,
  conversion_action.attribution_model_settings.attribution_model,
  conversion_action.click_through_lookback_window_days,
  conversion_action.value_settings.default_value,
  conversion_action.value_settings.always_use_default_value,
  conversion_action.enhanced_conversions_for_leads_enabled
FROM conversion_action
WHERE conversion_action.status = 'ENABLED'
```

Enhanced Conversions em nível de conta (`customer`):

```sql
SELECT
  customer.id,
  customer.conversion_tracking_setting.conversion_tracking_status,
  customer.conversion_tracking_setting.enhanced_conversions_for_leads_enabled,
  customer.conversion_tracking_setting.accepted_customer_data_terms
FROM customer
```

**Notas de precisão:**
- G42: ≥1 ação de conversão primária ENABLED = PASS.
- G43: Enhanced Conversions ativo E verificado nas conversões primárias = PASS.
- G47: só macro (Purchase, Lead) como `primary_for_goal = TRUE` = PASS. Micro events (AddToCart) como primary = FAIL.
- G48: `attribution_model = DATA_DRIVEN` = PASS. Modelos rule-based (first click, linear, time decay, position-based) foram auto-migrados para DDA; qualquer rule-based remanescente = misconfiguração legada. **Excluir** conversões system-managed de Smart Campaign (atribuição e counting travados pelo Google).
- G-CT1: checar duplicidade **só** em ações ENABLED (excluir HIDDEN/REMOVED). Reportar duplicata com ID, tipo, origin, category, status, flag primary/secondary, counting type e attribution model. Cruzar `origin` (GOOGLE_ANALYTICS vs WEBPAGE) para detectar GA4 + tag nativa contando a mesma ação.
- G46: `click_through_lookback_window_days` coerente com o ciclo de venda (7d ecom, 30-90d B2B, 30d lead gen).
- G49: `default_value`/`always_use_default_value` — ausência de valor = FAIL.

### Bloco `ga4-links` (G-CT2)
Links de GA4/analytics à conta (`google_ads_link` ou `third_party_app_analytics_link` conforme setup).

```sql
SELECT
  customer.id,
  customer.conversion_tracking_setting.google_ads_conversion_customer
FROM customer
```

**Notas de precisão:** o link GA4↔Ads e o fluxo de dados nem sempre são 100% inspecionáveis via GAQL; confirmar discrepâncias exige o painel de GA4. Reportar como PASS/WARNING com a ressalva. G-CT3 (tag firing) e G45 (Consent Mode V2) **não** são obtidos por GAQL — ver seção Fora do GAQL.

### Bloco `ctv-video-tracking` (G-CTV1)
Campanhas de vídeo/CTV para checar dependência de Floodlight.

```sql
SELECT
  campaign.id,
  campaign.name,
  campaign.advertising_channel_type,
  campaign.advertising_channel_sub_type
FROM campaign
WHERE campaign.advertising_channel_type IN ('VIDEO', 'DEMAND_GEN')
  AND campaign.status = 'ENABLED'
```

**Notas de precisão:** Floodlight não mede conversão em dispositivos CTV. Se campanhas CTV dependem de Floodlight = FAIL. A verificação do método de medição (Floodlight vs Google Ads/GA4) pode exigir inspeção de tag — reportar WARNING se não confirmável por GAQL.

---

## 6. Settings & Targeting

**Alimenta:** G50, G51, G52, G53, G54, G55, G56, G57, G58. (G59, G60, G61 = manual, landing page.)

### Bloco `extensions-assets`
Assets vinculados a campanhas por tipo (sitelink, callout, structured snippet, image, call, lead form). Base para G50-G55.

```sql
SELECT
  campaign.id,
  campaign.name,
  campaign_asset.field_type,
  campaign_asset.asset,
  campaign_asset.status,
  asset.type
FROM campaign_asset
WHERE campaign.status = 'ENABLED'
  AND campaign_asset.status = 'ENABLED'
```

Também checar em nível de conta (`customer_asset`) e ad group (`ad_group_asset`) para cobertura completa.

**Notas de precisão:**
- G50: `field_type = 'SITELINK'` — ≥4 por campanha = PASS.
- G51: `field_type = 'CALLOUT'` — ≥4 = PASS.
- G52: `field_type = 'STRUCTURED_SNIPPET'` — ≥1 = PASS.
- G53: `field_type = 'IMAGE'` (image extension) presente = PASS.
- G54: `field_type = 'CALL'` com call tracking para negócio de telefone.
- G55: `field_type = 'LEAD_FORM'` (Low severity, só para lead gen).

### Bloco `audiences-and-exclusions`
Sinais de audiência aplicados e exclusões de placement. Base para G56, G57, G58.

```sql
SELECT
  ad_group.id,
  campaign.id,
  ad_group_criterion.type,
  ad_group_criterion.user_list.user_list,
  ad_group_criterion.audience.audience,
  ad_group_criterion.negative
FROM ad_group_criterion
WHERE campaign.status = 'ENABLED'
  AND ad_group.status = 'ENABLED'
  AND ad_group_criterion.type IN ('USER_LIST', 'AUDIENCE')
```

Customer Match lists e recência (`user_list`):

```sql
SELECT
  user_list.id,
  user_list.name,
  user_list.type,
  user_list.size_for_search,
  user_list.membership_status
FROM user_list
WHERE user_list.type = 'CRM_BASED'
```

Exclusões de placement em nível de campanha (`campaign_criterion`):

```sql
SELECT
  campaign.id,
  campaign_criterion.type,
  campaign_criterion.placement.url,
  campaign_criterion.negative
FROM campaign_criterion
WHERE campaign_criterion.negative = TRUE
  AND campaign_criterion.type IN ('PLACEMENT', 'YOUTUBE_CHANNEL', 'YOUTUBE_VIDEO', 'MOBILE_APPLICATION', 'MOBILE_APP_CATEGORY')
  AND campaign.status = 'ENABLED'
```

**Notas de precisão:**
- G56: remarketing + in-market em modo Observation = PASS. Modo (Observation vs Targeting) via `ad_group_criterion` não expõe diretamente o modo em todos os casos — confirmar na aplicação.
- G57: Customer Match uploaded e refreshed <30 dias = PASS. A **data do último refresh** nem sempre vem via GAQL; `size_for_search` e `membership_status` ajudam, mas a recência pode exigir inspeção manual → reportar WARNING se não confirmável.
- G58: exclusões de placement em nível de conta (games, apps, MFA). Nível de campanha apenas = WARNING; nenhuma = FAIL.

---

## 7. Bidding & Budget

**Alimenta:** G36, G37, G38, G39, G40, G41 (pontuam dentro de Settings & Targeting).

### Bloco `bidding-strategies`
Estratégia de lance, targets e status de learning por campanha. Base para G36, G37, G38, G40, G41.

```sql
SELECT
  campaign.id,
  campaign.name,
  campaign.bidding_strategy_type,
  campaign.bidding_strategy,
  campaign.target_cpa.target_cpa_micros,
  campaign.target_roas.target_roas,
  campaign.maximize_conversions.target_cpa_micros,
  campaign.maximize_conversion_value.target_roas,
  campaign.primary_status,
  campaign.primary_status_reasons,
  metrics.conversions,
  metrics.cost_micros,
  metrics.average_cpc
FROM campaign
WHERE campaign.status = 'ENABLED'
  AND segments.date DURING LAST_30_DAYS
```

**Notas de precisão:**
- G36: campanhas com ≥15 conv/30d devem usar automated bidding. `bidding_strategy_type = 'MANUAL_CPC'` com dados suficientes = FAIL. **ECPC foi totalmente depreciado (março/2025)** — qualquer `ENHANCED_CPC` remanescente = FAIL, migrar para tCPA/tROAS/Max Conversions.
- G37: target CPA/ROAS dentro de 20% do histórico = PASS. Target CPA <50% do CPA real = FAIL (Critical).
- G38: `primary_status = 'LEARNING'` / `primary_status_reasons` contendo learning — <25% das campanhas = PASS, >40% = FAIL.
- G39: `primary_status_reasons` contendo `BUDGET_CONSTRAINED` / `LIMITED_BY_BUDGET` nos top performers = FAIL.
- G40: Manual CPC justificável só com <15 conv/mês; >30 conv/mês em Manual = FAIL.
- G41: múltiplas campanhas <15 conv rodando independentes (não em portfolio) = oportunidade de portfolio bid strategy.

### Bloco `budgets` (G08, G09, G39)
Budgets e recommended budget (se disponível).

```sql
SELECT
  campaign.id,
  campaign.name,
  campaign_budget.amount_micros,
  campaign_budget.delivery_method,
  campaign_budget.has_recommended_budget,
  campaign_budget.recommended_budget_amount_micros,
  metrics.cost_micros
FROM campaign
WHERE campaign.status = 'ENABLED'
  AND segments.date DURING LAST_30_DAYS
```

---

## 8. Performance Max (consolidado)

Os checks PMax (G-PM1 a G-PM6) usam os blocos `pmax-campaigns`, `pmax-asset-groups`, `pmax-signals-and-themes` e `pmax-negatives` (seção 4). Resumo de mapeamento:

| Check | Bloco | Sinal-chave |
|-------|-------|-------------|
| G-PM1 | pmax-signals-and-themes | `asset_group_signal.resource_name` (não `audience_signal`) |
| G-PM2 | pmax-asset-groups | `asset_group.ad_strength` |
| G-PM3 | pmax-campaigns + search terms | % conversões de termos de marca (<15% PASS) |
| G-PM4 | pmax-signals-and-themes | nº de search themes (<5 WARNING) |
| G-PM5 | pmax-negatives | brand + irrelevant negatives |
| G-PM6 | pmax-negatives | negativas em nível de campanha (ausência = FAIL, quick win) |

**Nota G-PM3:** insights de search terms/categorias da PMax vêm de relatórios específicos e podem ser limitados via GAQL padrão; usar dados de `campaign_search_term_insight` quando disponível, caso contrário reportar como estimativa.

---

## Fora do GAQL — checks manuais

Estes checks **não são obteníveis via GAQL** e permanecem manuais. Sempre reportar em G-SYS1 como "requer inspeção manual", nunca como PASS silencioso:

| Check | Por que não é GAQL | Como obter |
|-------|--------------------|------------|
| **G59** — Landing page mobile speed (LCP) | Métrica de performance web, fora da API Ads | PageSpeed/CrUX ou `analyze_landing.py` |
| **G60** — Landing page relevance (H1/title vs tema) | Conteúdo da página, não da conta | Inspeção da URL / scraping |
| **G61** — Landing page schema markup | Marcação estrutural da página | Inspeção HTML da URL |
| **G45** — Consent Mode V2 (Advanced) | Implementação de tag/GTM, não exposta na API Ads | Auditoria de GTM/tag + Google Tag Assistant |
| **G44** — Server-side tracking (sGTM/API import) | Infra de tag/servidor | Inspeção do container sGTM / config de import |
| **G-CT3** — Google Tag firing (todas as páginas) | Comportamento de tag no site | Tag Assistant / inspeção de páginas |
| **Qualidade criativa subjetiva** | Julgamento humano (mensagem, apelo, marca) | Avaliação manual do consultor |
| **G-CTV1** (método de medição) | Confirmar não-Floodlight pode exigir inspeção de tag | GAQL identifica campanhas CTV; medição confirmada manualmente |
| **G57** (recência de Customer Match) | Data de último refresh nem sempre exposta | Painel de Audiences |

**Regra:** o GAQL alimenta ~60 dos 80 checks Google de forma confiável. Os ~20 restantes (landing page, tag/consent, criativo, recência de listas) misturam manual + semi-automatizável. Nunca inflar o score marcando manual como PASS — deixar explícito em G-SYS1 e nos relatórios técnico e roadmap.

---

## Diagnóstico de fetch (G-SYS1)

Após executar os blocos, montar o diagnóstico:

- **Fontes OK:** listar recursos consultados com sucesso.
- **Fontes com falha:** recurso + mensagem de erro → check IDs pulados.
- **Nunca pular check em silêncio.** Todo check sem dado vira "N/A — dados indisponíveis: {motivo}", excluído do denominador do score (não conta como FAIL nem como PASS).
