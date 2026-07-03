# Search Terms & Negative Keywords — Google Ads

<!-- Metodologia derivada do claude-ads (MIT). Referência: google-audit.md (G13-G19, G-WS1) + regras de negativas do SKILL.md. -->

Este arquivo cobre a gestão de search terms e negative keywords: como detectar wasted spend, montar listas temáticas de negativas, lidar com close variant pollution e BMM legado, e a cadência de revisão. É a categoria de **maior ROI de curto prazo** do consultor (Wasted Spend pesa 20% no score). O consultor busca os search terms ao vivo, propõe negativas e **só aplica após confirmação humana** — negativas erradas matam campanhas.

## O que é "wasted spend" (definição operacional)

Wasted spend não é "termo que não converteu". É:

> **Termo de busca com > $10 de gasto E 0 conversões nos últimos 30 dias.**

- O piso de $10 é essencial. Termos long-tail com gasto mínimo (<$10) são **exploração normal**, não desperdício — não os sinalize. (Nota de acurácia do check G16/G-WS1.)
- Isso evita o erro clássico de flaggear centenas de termos de $0,50 que somam quase nada e escondem o real problema.
- Ao reportar, mostre o **top 10 de desperdiçadores** com spend e cliques, ordenados por $ gasto.

## Checks de Wasted Spend / Negatives (G13–G19, G-WS1)

| ID | Check | Severidade | PASS | WARNING | FAIL |
|----|-------|-----------|------|---------|------|
| G13 | Recência da auditoria de search terms | Crítica | Revisados nos últimos **14 dias** | Revisados em até 30 dias | Não revisados há >30 dias |
| G14 | Listas de negativas existem | Crítica | ≥3 listas temáticas (Competitor, Jobs, Free, Irrelevant) | 1–2 listas | Nenhuma lista de negativas |
| G15 | Negativas aplicadas em nível de conta | Alta | Listas aplicadas em nível de conta / todas as campanhas | Aplicadas só em algumas campanhas | Não aplicadas |
| G16 | Wasted spend em termos irrelevantes | Crítica | <5% do spend em termos irrelevantes (30d) | 5–15% | >15% |
| G17 | Broad match + Smart Bidding pairing | Crítica | Nenhum Broad em Manual CPC | N/A | Broad + Manual CPC ativo |
| G18 | Close variant pollution | Alta | Exact/Phrase não disparando close variants irrelevantes | Problemas menores | Gasto significativo em close variants irrelevantes |
| G19 | Visibilidade dos search terms | Média | >60% do spend de termos é visível (não oculto) | 40–60% visível | <40% visível |
| G-WS1 | Keywords sem conversão | Alta | Nenhuma keyword com >100 cliques e 0 conversões | 1–3 keywords assim | >3 keywords com >100 cliques, 0 conversões |

Notas de acurácia (aplicar sempre):
- **G14/G15**: conte **tanto negativas em nível de campanha quanto Shared Negative Lists**. Campanhas cobertas por listas compartilhadas NÃO devem ser marcadas como "sem negativas". Reporte o breakdown por campanha (negativas diretas vs listas compartilhadas).
- **G16/G-WS1**: só é wasted se **>$10 E 0 conversões**. Long-tail com <$10 é exploração.
- **G19**: ao computar `totalVisibleSpend`, use **todos** os search terms buscados antes de qualquer truncamento/top-N. Erro comum: somar custo de um subconjunto truncado (ex.: top 500 de 2000), subestimando a visibilidade. Busque ordenado por custo desc.

## Listas temáticas de negative keywords

Monte e mantenha listas compartilhadas por tema (check G14 exige ≥3). Fontes vêm **sempre do Search Terms Report real, nunca de adivinhação**:

| Lista | Padrões de intenção a bloquear | Exemplos de tokens |
|-------|-------------------------------|--------------------|
| Competitor | Nomes de concorrentes (só se você decidiu não competir por eles) | marca-concorrente-A, marca-concorrente-B |
| Jobs / Careers | Quem busca emprego, não compra | jobs, careers, salary, vagas, salário, carreira, estágio |
| Free / DIY | Intenção de não pagar | free, grátis, gratis, crack, torrent, como fazer, diy, tutorial |
| Irrelevant / Informational | Informacional puro, sem intenção comercial | what is, o que é, definição, wikipedia, significado, exemplo |

Regras críticas de negativas (negativas ruins matam campanhas):
- **NUNCA sugira negativas em Broad Match** a menos que explicitamente justificado — elas bloqueiam amplo demais e podem derrubar queries que convertem.
- Padrão: **Exact Match `[keyword]`** para queries irrelevantes específicas.
- Use **Phrase Match `"keyword"`** para padrões de intenção irrelevante.
- Recomende **Shared Negative Lists em nível de conta**, não só campanha (G15).
- **Revise negativas existentes por over-blocking**: alguma negativa está acidentalmente bloqueando queries que convertem? Isso é tão danoso quanto não ter negativas.
- Negativas do Google **agora cobrem misspellings automaticamente** (mudança 2025) — não precisa listar cada erro de digitação.

## Close variant pollution (check G18)

- O Google faz match de close variants (misspellings, sinônimos, paráfrases, mesma intenção) mesmo em Exact e Phrase. Às vezes traz queries irrelevantes.
- **15% das buscas diárias do Google são novas** — close variants são inevitáveis; a gestão de negativas é contínua, não one-time.
- Sintoma: keyword Exact/Phrase disparando search terms que não têm relação com a intenção. Detecte comparando o search term com a keyword que o disparou.
- Correção: adicionar a query poluente como negativa (Exact/Phrase), sem bloquear a keyword-mãe.

## BMM legado: BROAD + Manual CPC = phrase (heurística G17/FL04)

Ponto crítico para não gerar falso positivo:

- Na migração de 2021, o Google **removeu o prefixo `+` do Broad Match Modified** mas manteve `matchType=BROAD` na API.
- Portanto **BROAD + Manual CPC quase sempre é BMM legado**, que se comporta como **phrase match** — NÃO é broad intencional.
- **Não sinalize BROAD + Manual CPC como falha.** É legado e comporta-se de forma controlada.
- Broad intencional **sempre** anda com Smart Bidding (tCPA, tROAS, Maximize Conversions/Value). **Só sinalize keywords BROAD em campanhas de Smart Bidding** como necessitando revisão/negativas agressivas.
- Broad intencional (em Smart Bidding) exige listas de negativas robustas e revisão frequente — a reach é 3–5× maior.

## Cadência de revisão

- **A cada 14 dias** é o alvo do check G13 (PASS). 15–30 dias = WARNING; >30 dias = FAIL.
- Broad Match / AI Max ativos → encurte para semanal: a expansão gera novos termos rápido.
- A revisão é um ciclo: puxar search terms → classificar (converte / irrelevante / exploração) → propor negativas → confirmar → aplicar → medir.

## GAQL de search_term_view (com armadilhas de compatibilidade)

Query base de search terms (últimos 30 dias):

```sql
SELECT
  search_term_view.search_term,
  segments.search_term_match_type,
  metrics.cost_micros,
  metrics.clicks,
  metrics.impressions,
  metrics.conversions
FROM search_term_view
WHERE segments.date DURING LAST_30_DAYS
ORDER BY metrics.cost_micros DESC
```

**Armadilhas de compatibilidade do `search_term_view` (importante):**
- **NÃO filtre por `campaign.status` dentro de `search_term_view`.** Esse campo é incompatível com o recurso e a query falha. Se precisar restringir a campanhas ativas, filtre em código depois, ou colete o mapa de status via query separada em `campaign`.
- **Use `LAST_30_DAYS`** (ou faixa de datas explícita). Evite depender de janelas ambíguas — o report de search terms é sensível à janela.
- Busque **ordenado por `metrics.cost_micros DESC`** para capturar primeiro os maiores gastadores (essencial para G16, G19 e para o top 10 de wasted spend).
- `cost_micros` em micros → divida por 1.000.000.
- Para identificar wasted spend: filtre em código por `cost_micros/1e6 > 10 AND conversions = 0`.
- `segments.search_term_match_type` ajuda no G18 (close variant pollution) — veja quanto do spend vem de matches mais amplos que a keyword.

Keywords com muitos cliques e nenhuma conversão (check G-WS1):

```sql
SELECT
  ad_group_criterion.keyword.text,
  ad_group_criterion.keyword.match_type,
  metrics.clicks,
  metrics.conversions,
  metrics.cost_micros
FROM keyword_view
WHERE segments.date DURING LAST_30_DAYS
  AND ad_group_criterion.status = 'ENABLED'
ORDER BY metrics.clicks DESC
```
Filtre em código por `clicks > 100 AND conversions = 0`.

Negativas existentes em nível de campanha e listas compartilhadas (para G14/G15):

```sql
SELECT
  campaign.name,
  campaign_criterion.keyword.text,
  campaign_criterion.keyword.match_type,
  campaign_criterion.negative
FROM campaign_criterion
WHERE campaign_criterion.negative = TRUE
  AND campaign_criterion.type = 'KEYWORD'
```
Complemente com a consulta às Shared Sets para não marcar como "sem negativas" campanhas cobertas por lista compartilhada.

## Estimando o valor do wasted spend (para priorização)

1. Puxe search terms (query acima), ordenados por custo.
2. Classifique cada termo com >$10 e 0 conversões como candidato a negativa.
3. Some o custo desses termos = **wasted spend mensal estimado em $**.
4. Divida pelo spend total → % (aplica o threshold do G16: <5% PASS, 5–15% WARNING, >15% FAIL).
5. Reporte em $/mês, não só %: "≈ $X/mês recuperáveis adicionando N negativas". É o número que move o cliente.

## Fluxo do consultor (search terms)

1. Puxe search terms ao vivo (respeitando as armadilhas de GAQL acima).
2. Aplique a definição de wasted spend (>$10 E 0 conversões).
3. Classifique os irrelevantes nas listas temáticas (Competitor/Jobs/Free/Irrelevant).
4. Escolha match type correto para cada negativa (padrão Exact; Phrase para padrões).
5. Cheque over-blocking nas negativas existentes.
6. Estime o $/mês recuperável e priorize.
7. Aplique a heurística BMM legado antes de falar em broad match (G17).
8. **Aplique negativas só após confirmação humana** — uma negativa ampla errada pode zerar uma campanha que convertia.
