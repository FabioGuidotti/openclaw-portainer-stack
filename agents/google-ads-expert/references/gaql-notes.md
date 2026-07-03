<!-- Adaptado de claude-ads (MIT) — ads/references/gaql-notes.md -->

# GAQL — Notas de Compatibilidade e Precisão

Regras para evitar **falsos positivos** ao analisar Google Ads via GAQL (Maton)
ou exports. Ignorar isto gera centenas de findings incorretos.

## Campos incompatíveis conhecidos (API v20+)

| Recurso | Campo incompatível | Erro | Correção |
|---|---|---|---|
| `search_term_view` | `campaign.status`, `ad_group.status` | INVALID_ARGUMENT | Filtre status na camada de aplicação, não no GAQL |
| `search_term_view` | `search_term_view.status` | INVALID_ARGUMENT | Campo removido/deprecado em v20 |
| `asset_group_signal` | `audience_signal` | UNRECOGNIZED_FIELD | Use `resource_name` |
| cláusula DURING | `LAST_90_DAYS` (search terms) | INVALID_VALUE_WITH_DURING_OPERATOR | Use `LAST_30_DAYS` |

## Deduplicação de keywords

**Problema:** `keyword_view + segments.date DURING LAST_30_DAYS` retorna **uma
linha por keyword por dia**. Uma keyword ativa 5 dias = 5 linhas. A mesma keyword
com BROAD + PHRASE = 2 linhas/dia = 10 no total.

**Correção:** deduplique por `(ad_group_id + keyword_text + match_type)` no fetch
e **agregue** métricas (impressions, clicks, cost, conversions) entre as linhas.
**Alternativa:** remova `segments.date` da query para eliminar a duplicação por dia.

**Impacto:** todos os checks dependentes de keyword (G03, G05, G07, G-PM3, G17,
G21, G25, G-KW1, e ~10 outros) passam a usar contagens únicas corretas.

## Escopo de filtro (auditoria ativa)

Filtre para recursos **ENABLED** apenas:

- **Campanhas:** `campaign.status = 'ENABLED'` (não use `!= 'REMOVED'`, que inclui PAUSED).
- **Ad groups:** campanhas ENABLED + grupos não removidos.
- **Keywords:** campanhas ENABLED + grupos não removidos + keywords não removidas.
- **Search terms:** ordene por `metrics.cost_micros DESC`; janela `LAST_30_DAYS`.

**Por quê:** incluir pausados gera falsos positivos. Ad groups pausados podem ter
keywords ENABLED no nível de critério, mas não aparecem na UI — auditá-los confunde.

## Legacy BMM (Broad Match Modified)

O Google removeu os prefixos `+` na migração de 2021, mas manteve `matchType='BROAD'`
na API.

**Heurística:** broad match **intencional** está SEMPRE pareado com Smart Bidding
(tCPA, tROAS, Maximize Conversions/Value). **BROAD + Manual CPC = legacy BMM**
(comporta-se como phrase). **Não** sinalize BROAD + Manual CPC como falha em G17 —
só avalie BROAD em campanhas de Smart Bidding.

## Detecção de brand (G05/G07/G-PM3)

Não confie apenas em naming. Derive brand tokens do nome da conta/negócio e
escaneie o texto real das keywords. Classifique campanhas por composição:
>50% keywords de brand = brand campaign. Isso pega campanhas mal-rotuladas.

## "Wasted spend" (G16/G-WS1)

Só marque um search term/keyword como desperdício se tiver **> R$/$ 10 de spend E
0 conversões**. Termos long-tail com spend mínimo (<$10) são exploração normal,
não waste. Ao reportar, mostre o top 10 com spend e clicks.

## Cálculo de visibilidade (G19)

Ao computar `totalVisibleSpend`, use **todos** os search terms buscados antes de
qualquer truncamento/top-N. Somar cost de um subconjunto truncado subestima a
visibilidade. Busque ordenado por cost DESC para capturar os de maior spend primeiro.

## Tratamento de erros (diagnóstico G-SYS1)

Rastreie quais fetches falharam e por quê. Reporte como diagnóstico G-SYS1:

- Liste todas as fontes de dado que falharam com a mensagem de erro.
- Diga, por check, quais foram pulados por falta de dado.
- **Nunca** pule um check em silêncio — sempre explique. Checks sem dado viram
  N/A e são excluídos do score (não contam como falha).
</content>
