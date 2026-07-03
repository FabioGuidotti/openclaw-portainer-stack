# Quality Score como diagnóstico — Google Ads

<!-- Metodologia derivada do claude-ads (MIT). Referência: google-audit.md (G20-G25, G-KW1, G-KW2). -->

Este arquivo trata Quality Score (QS) como **ferramenta de diagnóstico, não como KPI**. QS não é uma meta a maximizar — é um termômetro que aponta *onde* a conta está pagando caro por relevância ruim. O consultor usa QS para localizar a causa-raiz (ad copy, keyword ou landing page) e propor correção, executando mudanças só após confirmação humana.

## Por que QS não é KPI

- QS é diagnóstico, não objetivo. Ninguém "ganha dinheiro" tendo QS 10 — ganha tendo CPA baixo e ROAS alto. QS alto é **consequência** de relevância boa, não a causa do sucesso.
- QS afeta o negócio via **Ad Rank** e via **CPC**:
  - Ad Rank = Max CPC × Quality Score × Impacto esperado dos assets.
  - CPC real ≈ (Ad Rank do concorrente abaixo / seu Quality Score) + $0,01.
  - Consequência prática: QS alto = mesma posição por menos dinheiro. QS baixo = você paga um "imposto de irrelevância".
  - Landing Page Experience alta pode render **até 50% de desconto no CPC**; baixa pode custar **até 400% a mais** (ver `benchmarks.md`).
- Não persiga QS 10 em keywords de baixo spend. **Priorize QS baixo em keywords de alto gasto** — é onde o imposto dói. Por isso o check G20 é **impression-weighted**.

## Componentes do Quality Score

QS é avaliado 1–10 no nível da keyword, com três componentes, cada um rotulado Below Average / Average / Above Average:

| Componente | Peso aproximado (ref. 2026) | O que mede | Onde corrigir |
|------------|-----------------------------|------------|---------------|
| Expected CTR | ~39% | Probabilidade de clique dado o histórico da keyword/ad | Ad copy (headlines), match type, relevância keyword↔ad |
| Ad Relevance | ~22% | Quão bem o anúncio corresponde à intenção da keyword | Incluir a keyword nas headlines; ad group temático |
| Landing Page Experience | ~39% | Relevância, transparência e velocidade da página de destino | Landing page: conteúdo, H1/title, LCP mobile |

Os dois componentes de maior peso são **Expected CTR** e **Landing Page Experience**. Ad copy fraco e landing page ruim são, juntos, ~78% do QS.

## Thresholds dos checks (G20–G25, G-KW1, G-KW2)

| ID | Check | Severidade | PASS | WARNING | FAIL |
|----|-------|-----------|------|---------|------|
| G20 | QS médio da conta (impression-weighted) | Alta | ≥7 | 5–6 | ≤4 |
| G21 | Keywords com QS crítico | Crítica | <10% com QS ≤3 | 10–25% com QS ≤3 | >25% com QS ≤4 |
| G22 | Componente Expected CTR | Alta | <20% "Below Average" | 20–35% Below Average | >35% Below Average |
| G23 | Componente Ad Relevance | Alta | <20% "Below Average" | 20–35% Below Average | >35% Below Average |
| G24 | Componente Landing Page Experience | Alta | <15% "Below Average" | 15–30% Below Average | >30% Below Average |
| G25 | QS das top keywords | Média | Top 20 keywords por spend todas com QS ≥7 | Algumas top em QS 5–6 | Top keywords com QS ≤4 |
| G-KW1 | Keywords com zero impressão | Média | Nenhuma com 0 impressões em 30d | <10% com zero impressão | >10% com 0 impressões |
| G-KW2 | Relevância keyword↔ad | Alta | Headlines contêm variantes da keyword primária | Inclusão parcial | Nenhuma variante da keyword nas headlines |

Notas de aplicação:
- G20 usa **média ponderada por impressões**, não média simples — assim o QS reflete o tráfego real, não keywords dormentes.
- G21 e G25 são as duas faces do risco: G21 olha o **volume** de keywords ruins; G25 olha se as **keywords que mais gastam** estão saudáveis. Uma conta pode passar em G21 e falhar em G25 (poucas keywords ruins, mas são as caras).
- **Deduplique** keywords por `(ad_group_id + keyword_text + match_type)` antes de contar; a mesma keyword em BROAD + PHRASE é uma keyword, não duas.
- Analise **apenas keywords ENABLED com impressões > 0** (exceto no G-KW1, que é justamente sobre zero-impressão).

## Como diagnosticar QS baixo (do sintoma à causa)

O QS agregado não diz nada acionável. **Sempre desça para o componente.** Roteiro:

1. **Puxe o QS e os três componentes por keyword** (GAQL abaixo).
2. **Filtre por keywords de alto spend** com QS ≤5 — é a lista de prioridade.
3. **Identifique qual componente está "Below Average"** em cada uma. A causa-raiz define a correção:

| Componente Below Average | Causa provável | Correção |
|--------------------------|----------------|----------|
| Expected CTR | Ad copy genérico; keyword não aparece no anúncio; match type amplo demais atraindo cliques errados | Reescrever headlines com a keyword e um CTA/benefício; testar RSA nova (G-AD1); revisar match type |
| Ad Relevance | Ad group com temas misturados; anúncio não fala da keyword | Dividir ad group em temas únicos (≤10 keywords); inserir variantes da keyword nas headlines (G-KW2/G35) |
| Landing Page Experience | Página lenta (LCP >4s), conteúdo genérico, H1/title não bate com o ad group | Melhorar LCP mobile (G59), alinhar H1/title ao tema do ad group (G60), adicionar schema (G61) |

4. **Ordene por impacto**: gap de QS × spend da keyword = imposto de irrelevância estimado.

## Plano de correção (ordem de ataque)

Ataque na ordem de maior alavanca e menor esforço:

1. **Ad Relevance + Expected CTR primeiro** (via ad copy). É a correção mais rápida: reescrever headlines para conter a keyword e melhorar o RSA. Muitas vezes resolve dois componentes de uma vez. Melhorar Ad Strength de "Poor" para "Excellent" rende ~15% mais conversões (referência 2026).
2. **Estrutura do ad group**: se as headlines não conseguem falar de todas as keywords, o ad group tem temas demais. Divida em single-theme ad groups (≤10 keywords).
3. **Landing Page Experience por último**, porque exige dev/design e é mais lento — mas tem peso ~39% e o maior efeito no CPC. Priorize LCP mobile e alinhamento H1/tema.
4. **Pause ou reescreva** keywords com QS ≤3 e spend relevante que não melhoram após ad copy + landing page. Não deixe imposto de irrelevância correndo.
5. **Reavalie após 2–3 semanas** — QS é recalculado com novo histórico de CTR; mudanças levam tempo para refletir.

Sempre apresente o plano com o "porquê" (qual componente, qual keyword, quanto spend) e **execute alterações só após confirmação humana**.

## GAQL para puxar Quality Score ao vivo

QS agregado + os três componentes, por keyword (base do diagnóstico):

```sql
SELECT
  ad_group.name,
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
WHERE segments.date DURING LAST_30_DAYS
  AND ad_group_criterion.status = 'ENABLED'
  AND campaign.status = 'ENABLED'
ORDER BY metrics.cost_micros DESC
```

Mapeamento dos campos para os componentes:
- `quality_info.quality_score` → QS 1–10 (checks G20/G21/G25).
- `quality_info.creative_quality_score` → **Ad Relevance** (Below/Average/Above — check G23).
- `quality_info.post_click_quality_score` → **Landing Page Experience** (check G24).
- `quality_info.search_predicted_ctr` → **Expected CTR** (check G22).

Notas:
- `keyword_view` é a fonte de QS ao vivo. `cost_micros` em micros — divida por 1.000.000.
- Ordenar por `cost_micros DESC` garante que as keywords que mais gastam apareçam primeiro (essencial para G20 impression-weighted e G25).

Top keywords por spend (para o check G25 especificamente):

```sql
SELECT
  ad_group_criterion.keyword.text,
  ad_group_criterion.quality_info.quality_score,
  metrics.cost_micros
FROM keyword_view
WHERE segments.date DURING LAST_30_DAYS
  AND ad_group_criterion.status = 'ENABLED'
ORDER BY metrics.cost_micros DESC
LIMIT 20
```

Keywords com zero impressão (check G-KW1):

```sql
SELECT
  ad_group_criterion.keyword.text,
  metrics.impressions
FROM keyword_view
WHERE segments.date DURING LAST_30_DAYS
  AND ad_group_criterion.status = 'ENABLED'
```
Filtre no cálculo por `metrics.impressions = 0`.

## Erros comuns a evitar

- **Reportar só o QS médio.** Inútil sem os componentes e sem o spend. Sempre desça ao componente.
- **Tratar QS como meta.** O objetivo é CPA/ROAS; QS é o caminho, não o destino.
- **Ignorar o peso do spend.** Melhorar QS de uma keyword que gasta $5 não move o ponteiro; melhorar a que gasta $2.000 sim.
- **Mexer em tudo de uma vez.** Mude ad copy OU landing page e meça; senão você não sabe o que funcionou.
- **Esquecer o peso da landing page.** Com ~39%, uma página lenta derruba o QS de keywords perfeitas. Cruze com G59 (LCP mobile) e G60 (relevância da página).
