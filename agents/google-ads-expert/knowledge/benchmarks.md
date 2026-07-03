# Benchmarks 2026 — Google Ads

<!-- Metodologia derivada do claude-ads (MIT). Fontes: WordStream/LocaliQ 2025 (16K campanhas), Triple Whale 2025, Gemini/Claude Research. -->

Este arquivo reúne os benchmarks de referência 2026 para Google Ads (Search e Shopping/PMax) e explica como um consultor contínuo deve usá-los para **calibrar severidade** de achados por indústria e por tamanho de conta. Benchmark serve para decidir o quão grave é um desvio e onde priorizar — nunca como meta a ser perseguida cegamente.

## Princípio central: benchmark é piso/teto, não meta

- O benchmark é uma **linha de base de mercado**, não o objetivo da conta. A meta real é definida pela **unit economics** do cliente (LTV, margem, CAC-payback), não pela média WordStream.
- Use o benchmark para responder duas perguntas:
  1. **É grave?** Um CTR de 3% é ruim em Arts & Entertainment (benchmark ~13%) mas quase normal em Healthcare (benchmark ~4,9%).
  2. **Onde priorizar?** O maior gap relativo ao benchmark, ponderado pelo spend, é onde está o dinheiro.
- Regra de ouro: **compare a conta contra a média da própria indústria**, depois contra o histórico dela mesma. Se o cliente tem ROAS 5,0 num setor cujo benchmark é 3,68, o "problema" pode ser não escalar — não eficiência.
- Nunca reporte "seu CPC está acima da média" como falha isolada. CPC alto com CVR alto e CPA saudável é saudável. Sempre olhe a cadeia CPC → CTR → CVR → CPA → ROAS junto.

## Médias gerais Google Search (WordStream/LocaliQ 2025 — benchmark de referência 2026)

Base: 16.000+ campanhas.

| Métrica | Média todas as indústrias | Tendência YoY |
|---------|---------------------------|---------------|
| CTR | 6,66% | +3,74% (subiu) |
| CPC | $5,26 | Subiu para 87% das indústrias (5º ano seguido de alta) |
| CVR | 7,52% | Subiu para 65% das indústrias |
| CPL | ~$70 | +5% |

Insight estrutural 2026: **CTR melhorou em quase todas as indústrias, mas CVR caiu em 13 de 14** no e-commerce. Ou seja, atrair clique ficou mais fácil/caro; converter ficou mais difícil. Priorize landing page e qualificação de tráfego, não só CTR.

## Benchmarks por indústria — Google Search (referência 2026)

| Indústria | CPC | CTR | CVR | CPL | ROAS |
|-----------|-----|-----|-----|-----|------|
| Arts & Entertainment | $1,60 | 13,10% | — | — | — |
| Travel | $2,12 | — | — | — | — |
| Restaurants | $2,05 | — | — | — | — |
| E-commerce | $1,15 | 4,13% | 2,81% | — | 3,68 |
| B2B SaaS | $4,50–$8,00 | 4,28% | 1,65% | $100–$200 | 3,0–4,0 (base LTV) |
| Education | $6,23 | — | — | — | — |
| Local Services | $7,85–$15,00 | 5,50%–6,37% | 7,33%–15,0% | $90,92 | 5,0 |
| Dental | $7,85 | 5,44% | — | — | — |
| Healthcare | $40+ | 4,90% | 3,10% | — | 2,8 |
| Legal | $8,58–$9,21 | 5,20%–5,97% | 4,60%–5,09% | — | 3,0 |
| Finance / Fintech | $3,46–$3,77 | 4,65%–8,33% | 2,55%–3,50% | $100 (LinkedIn) | 3,5 |
| Real Estate | $1,55–$2,53 | 8,43% | 3,28% | — | — |
| Home Improvement | $7,85 | 6,37% | 7,33% | $90,92 | 5,0 |

Notas por vertical (do playbook 2026):
- **SaaS/B2B**: medir LTV/CAC-payback, não ROAS imediato. CPA $100–$200 no Google, $150–$400 no LinkedIn é normal. Um CPL de $100 sobre LTV de $10K é excelente.
- **E-commerce**: CPA mediano $23,74 (+12,35% YoY), CPM mediano $12,79, ROAS mediano 3,68 (caiu 10% YoY). Otimize POAS (profit on ad spend), não só ROAS.
- **Local Services**: 90%+ dos leads LSA são ligações; nota 4,8+ estrelas com 150+ reviews é o fator #1 de ranking. CPL varia de $34 (chaveiro) a $249 (advogado de dano pessoal).
- **Healthcare**: CPM mais alto de todas as indústrias. **Proibido remarketing/retargeting** de serviços de saúde (viola política do Google). Use contextual, não audiência.
- **Finance**: CVR entre as mais baixas do mercado; exige disclosures (APR, taxas) e certificação Google para crédito/cripto.

## E-commerce específico (Triple Whale 2025 — referência 2026)

| Métrica | Mediana | YoY |
|---------|---------|-----|
| CPA | $23,74 | +12,35% |
| CPM | $12,79 | +10,01% |
| ROAS | 3,68 | -10,03% |

## Landing page (referência 2026)

| Métrica | Valor |
|---------|-------|
| Share de tráfego mobile | 82,9% |
| CVR carga 1s vs 5s | 3× maior |
| Impacto de 1s de atraso | -7% conversões |
| CVR mediana entre indústrias | 6,6% |
| Top 10% de CVR | 20%+ |
| QS landing page alto → CPC | desconto de até 50% |
| QS landing page baixo → CPC | até 400% a mais |

A landing page pesa duas vezes: entra no Quality Score (Landing Page Experience, ~39% do peso) e no CVR. Um LCP mobile > 4,0s (check G59) é falha dupla.

## Como calibrar severidade por tamanho de conta

O mesmo desvio percentual tem impacto financeiro diferente conforme o spend. Ajuste a severidade e a urgência:

| Tamanho da conta (spend/mês) | Como calibrar |
|------------------------------|---------------|
| Micro (< $1.000) | Abaixo do budget mínimo viável do Google. Foco em fundamentos e em juntar dados para Smart Bidding (precisa de 15+ conv/30d). Não exija PMax nem estratégias avançadas. Wasted spend de $200 já é crítico. |
| Pequena ($1.000–$10.000) | Benchmark de indústria como régua principal. Wasted spend > 10% é o alvo #1. Smart Bidding começa a ser viável. |
| Média ($10.000–$100.000) | Comparar por segmento (marca vs não-marca, campanha a campanha), não só média da conta. Portfolio bid strategies (G41) e PMax ganham relevância. |
| Grande (> $100.000) | Média da conta esconde problemas. Sempre segmentar. Um gap de 1% de wasted spend pode ser $1.000+/mês. Priorize por $ absoluto perdido, não por %. |

Regras práticas de calibração:
- **Traduza sempre para $/mês.** "15% de wasted spend" comunica menos que "≈ $4.500/mês em termos irrelevantes". Use o spend real (GAQL) para estimar.
- **Pondere pelo spend, não pela contagem.** 3 keywords ruins que gastam $50 cada importam menos que 1 que gasta $2.000. Isso vale para QS (G20 é impression-weighted), search terms (G16) e Ad Strength.
- **Severidade escala com % do budget afetado.** Um problema que toca 40% do spend é sempre mais urgente que um que toca 2%, mesmo que o segundo seja tecnicamente "pior".

## Budget mínimo viável (referência 2026)

| Plataforma | Mínimo mensal | Racional |
|------------|---------------|----------|
| Google Ads | $1.000+ | Precisa de 15+ conversões/mês para Smart Bidding funcionar |
| Microsoft Ads | 20–30% do budget Google | Proporcional ao volume de busca |

Se a conta está abaixo de $1.000/mês, o consultor deve gerenciar expectativas: Smart Bidding não terá dados suficientes (ver `bidding.md`), e a recomendação padrão vira Maximize Clicks ou Manual CPC até acumular conversões.

## GAQL para puxar as métricas de calibração ao vivo

Performance por campanha (últimos 30 dias) — base para todo o cálculo de severidade:

```sql
SELECT
  campaign.name,
  metrics.cost_micros,
  metrics.clicks,
  metrics.impressions,
  metrics.ctr,
  metrics.conversions,
  metrics.conversions_value,
  metrics.average_cpc
FROM campaign
WHERE segments.date DURING LAST_30_DAYS
  AND campaign.status = 'ENABLED'
ORDER BY metrics.cost_micros DESC
```

Notas:
- `cost_micros` vem em micros — divida por 1.000.000 para obter a moeda.
- CVR = `metrics.conversions / metrics.clicks`; CPA = `cost / conversions`; ROAS = `conversions_value / cost`.
- Para comparar com o benchmark da indústria, primeiro classifique a conta (peça ao cliente ou infira pelos keywords/negócio).

## Checklist de uso dos benchmarks

1. Classifique a indústria da conta.
2. Puxe métricas reais (GAQL acima) por campanha e por segmento marca/não-marca.
3. Compare cada métrica contra a coluna da indústria — marque gaps.
4. Reordene os gaps por $/mês afetado (spend-weighted).
5. Cruze com a unit economics do cliente antes de chamar de "problema".
6. Só então atribua severidade e recomende. Execução só após confirmação humana.
