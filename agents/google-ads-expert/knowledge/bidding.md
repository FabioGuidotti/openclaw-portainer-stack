# Estratégias de Bid — Google Ads

<!-- Metodologia derivada do claude-ads (MIT). Referência: bidding-strategies.md + google-audit.md (G36-G41). -->

Este arquivo é a árvore de decisão de bidding para o consultor GoogleAdsExpert: qual estratégia recomendar conforme o volume de conversões e os objetivos, quais os pré-requisitos, e como diagnosticar má configuração via checks G36–G41. O consultor busca o dado ao vivo (GAQL), recomenda a estratégia certa e **só executa a mudança após confirmação humana**.

## Regra número um: bidding segue os dados de conversão

Smart Bidding é um modelo de ML. Sem volume de conversão, ele não tem sinal e performa pior que Manual. O gatilho de tudo é: **quantas conversões nos últimos 30 dias?**

GAQL para descobrir isso por campanha:

```sql
SELECT
  campaign.name,
  campaign.bidding_strategy_type,
  metrics.conversions,
  metrics.cost_micros,
  metrics.conversions_value
FROM campaign
WHERE segments.date DURING LAST_30_DAYS
  AND campaign.status = 'ENABLED'
ORDER BY metrics.conversions DESC
```

`campaign.bidding_strategy_type` revela a estratégia atual; `metrics.conversions` decide qual deveria ser.

## Árvore de decisão (Google Search)

```
INÍCIO → Quantas conversões nos últimos 30 dias?

┌─ < 15 conversões (cold start) ──────────────────────────┐
│  → Maximize Clicks                                       │
│  → OU Manual CPC se precisar de controle total          │
│  → Max CPC inicial ≈ Target_CPA / (CVR × 1,5)          │
│  → Learning: 3–5 dias                                   │
│  → Monitorar até atingir 15+ conversões                 │
│  → ECPC NÃO é opção (removido mar/2025)                 │
└──────────────────────────────────────────────────────────┘

┌─ 15–29 conversões ──────────────────────────────────────┐
│  → Maximize Conversions (sem cap)                        │
│  → Learning: 7–14 dias                                  │
│  → Transição quando desvio-padrão do CPA < 20% em 14d   │
│  → DEPOIS migrar para Target CPA                        │
└──────────────────────────────────────────────────────────┘

┌─ 30+ conversões, SEM valores dinâmicos ─────────────────┐
│  → Target CPA (tCPA)                                     │
│  → Google diz 15+, mas exija 30+ para confiabilidade    │
│    (50+ é o ideal)                                       │
│  → Definir em: 1,1×–1,2× o CPA histórico               │
│  → Ajustar: máx 10% de mudança a cada 14 dias          │
│  → Nunca reduzir mais de 15% de uma vez                 │
└──────────────────────────────────────────────────────────┘

┌─ 50+ conversões COM valores dinâmicos ──────────────────┐
│  → Target ROAS (tROAS)                                   │
│  → Requer valores de conversão dinâmicos                │
│  → Definir em: ROAS histórico EXATO                     │
│  → Fórmula: Bid = P(conv) × Valor × (1/tROAS)          │
│  → Ajustar: mesmas regras do tCPA                       │
└──────────────────────────────────────────────────────────┘

CASOS ESPECIAIS:
- Proteção de marca → Target Impression Share (95–100% em brand keywords)
- PMax → sempre Maximize Conversions ou Maximize Conversion Value
- Demand Gen → suporta Target CPC (novo), tCPA, tROAS, Max Clicks
```

## Pré-requisitos de cada estratégia

| Estratégia | Conversões/30d mínimas | Requer valores dinâmicos? | Quando recomendar |
|------------|------------------------|---------------------------|-------------------|
| Manual CPC | 0 | Não | Controle total; conta nova sem dados; < 15 conv (G40) |
| Maximize Clicks | 0 | Não | Cold start, acumular dados de conversão |
| Maximize Conversions | 15+ | Não | Ponte entre cold start e tCPA; budget deve ser gasto por completo |
| Target CPA (tCPA) | 30+ (ideal 50+) | Não | Lead gen / e-com sem valor por conversão; CPA é o KPI |
| Target ROAS (tROAS) | 50+ | Sim (obrigatório) | E-commerce com receita por conversão; ROAS é o KPI |
| Target Impression Share | 0 (sem requisito de conversão) | Não | Só Search. Proteção de marca / defesa de território |

Regra Smart Bidding (check **G36**): toda campanha com **≥15 conv/30d** deve usar bidding automatizado. Manual CPC com >30 conv/mês é falha (check **G40**).

## ECPC deprecado (março/2025)

- **Enhanced CPC (ECPC) foi totalmente removido em 31/03/2025** para Search e Display.
- Campanhas não migradas caíram para Manual CPC puro.
- Qualquer campanha ainda marcada como ECPC é uma **misconfiguração legada → FAIL** (check G36). Recomende migração imediata para tCPA, tROAS ou Maximize Conversions.
- Não existe mais "meio-termo automatizado" abaixo do Smart Bidding pleno. A escolha é binária: Manual CPC (controle) ou Smart Bidding (algoritmo).

## Learning phase (check G38)

- Toda mudança de estratégia de bid dispara nova learning phase.
- **Threshold do check G38**: PASS se <25% das campanhas em "Learning"/"Learning Limited"; WARNING 25–40%; FAIL >40%.
- Duração típica: 7–14 dias para Smart Bidding conversion-based.
- **Não julgue performance nem mexa em targets durante a learning phase.** Espere estabilizar.
- Transição só quando o desvio-padrão do CPA < 20% ao longo de 14 dias.

Detectar campanhas em learning via `campaign` + status de estratégia (ou pela aba de status na UI; a API expõe via `bidding_strategy` e sinais de otimização).

## Target CPA/ROAS reasonableness (check G37)

Check **crítico**. O target precisa ser realista frente ao histórico, senão o algoritmo sufoca a entrega:

| Situação | Severidade |
|----------|------------|
| Target dentro de 20% do histórico | PASS |
| Target 20–50% fora do histórico | WARNING |
| Target CPA < 50% do CPA real | FAIL (irrealista — algoritmo para de entregar) |

Regras de ajuste (nunca choque o sistema):
- Defina tCPA inicial em **1,1×–1,2× o CPA histórico**, não abaixo dele.
- Defina tROAS inicial no **ROAS histórico exato**.
- Ajuste no máximo **10% a cada 14 dias**; **nunca reduza mais de 15% de uma vez**.
- Baixar o target agressivamente = menos volume, não mais eficiência. É o erro mais comum.

GAQL para checar reasonableness — compare o target configurado contra o CPA/ROAS real:

```sql
SELECT
  campaign.name,
  campaign.bidding_strategy_type,
  campaign.target_cpa.target_cpa_micros,
  campaign.target_roas.target_roas,
  metrics.cost_micros,
  metrics.conversions,
  metrics.conversions_value
FROM campaign
WHERE segments.date DURING LAST_30_DAYS
  AND campaign.status = 'ENABLED'
```

CPA real = `cost_micros / conversions / 1e6`; compare com `target_cpa_micros / 1e6`. ROAS real = `conversions_value / (cost_micros/1e6)`; compare com `target_roas`.

## Portfolio bid strategies (check G41)

Quando várias campanhas individualmente têm <15 conv mas somadas passam de 30, agrupe num portfolio para o algoritmo ter dados.

Quando usar portfolio:
- Múltiplas campanhas cada uma com <15 conv, mas combinadas >30.
- Necessidade de otimização de budget entre campanhas.
- **CPC Cap hack**: portfolio é a única forma de setar um teto de Max CPC em estratégias tCPA/tROAS.

Regras:
- Mínimo 3 campanhas por portfolio para dados significativos.
- Agrupe campanhas com targets de CPA/ROAS parecidos.
- **Nunca misture marca e não-marca no mesmo portfolio** (dinâmicas de conversão totalmente diferentes).

Check G41: campanhas de baixo volume rodando isoladas quando poderiam ser agrupadas = WARNING.

## Smart Bidding Exploration (2025+)

- Disponível **apenas em estratégias Target ROAS**.
- O algoritmo relaxa temporariamente o alvo de ROAS para entrar em leilões que normalmente pularia, testando novos segmentos de usuário.
- Ganho de referência 2026: **+18% de categorias únicas de query** e **+19% de conversões**.
- **Quando habilitar**: campanhas tROAS estáveis, 50+ conv/mês, buscando crescimento incremental além da cobertura atual de queries.
- **Quando evitar**: contas de margem apertada, ou campanhas já gastando o budget inteiro (exploration adiciona volume, não só eficiência — vai puxar mais gasto).

## Transições de estratégia (gatilhos)

| De | Para | Gatilho |
|----|------|---------|
| Maximize Clicks | Maximize Conversions | 15+ conversões em 30 dias |
| Maximize Conversions | Target CPA | desvio-padrão do CPA <20% em 14 dias + 30+ conv |
| Target CPA | Target ROAS | 50+ conv + valores dinâmicos disponíveis |
| Manual CPC | Maximize Clicks | pronto para testar automação |
| Qualquer | Target Impression Share | necessidade de proteção de marca identificada |

## Broad Match + Manual CPC = red flag (cruza com G17)

- **Broad Match nunca deve rodar em Manual CPC.** Sem controle algorítmico de bid, broad sangra budget. Broad intencional sempre anda com Smart Bidding.
- **Heurística legacy BMM**: o Google removeu o prefixo `+` do Broad Match Modified na migração de 2021 mas manteve `matchType=BROAD` na API. **BROAD + Manual CPC quase sempre é BMM legado (comporta-se como phrase)** — NÃO é broad intencional, e não deve ser tratado como falha crítica de bid. Só sinalize keywords BROAD em campanhas de Smart Bidding como necessitando revisão de negativas. Ver detalhes de search terms em `search-terms.md`.
- Broad Match intencional (em Smart Bidding) exige gestão agressiva de negative keywords.

## Atribuição afeta o bidding (contexto)

- **DDA (Data-Driven Attribution) é o padrão obrigatório desde set/2025.** Só restam DDA e Last Click; todos os modelos baseados em regra foram deprecados.
- DDA distribui crédito de conversão entre touchpoints, o que altera os sinais que o Smart Bidding recebe. Ao migrar atribuição, espere reajuste na entrega — dê tempo ao algoritmo.

## Red flags de bidding (resumo para triagem rápida)

| Red flag | Severidade | Ação |
|----------|------------|------|
| Campanha ainda em ECPC | Crítica | Migrar para tCPA/tROAS/Max Conversions imediatamente (G36) |
| tCPA < 50% do CPA real | Crítica | Target irrealista; setar em 1,1–1,2× histórico (G37) |
| Smart Bidding com <15 conv/mês | Alta | Voltar para Manual CPC ou Maximize Clicks |
| Manual CPC com >30 conv/mês | Alta | Migrar para Smart Bidding (G40) |
| Broad Match + Manual CPC (em Smart Bidding real) | Crítica | Trocar para Smart Bidding ou Exact; checar negativas (G17) |
| >40% das campanhas em learning | Alta | Consolidar; evitar mudanças que resetam learning (G38) |
| Campanhas <15 conv rodando isoladas | Média | Agrupar em portfolio (G41) |

## Fluxo do consultor

1. Puxe volume de conversões e estratégia atual por campanha (GAQL acima).
2. Rode a árvore de decisão para cada campanha.
3. Cheque G36–G41 e reasonableness dos targets (G37).
4. Priorize por $/mês afetado.
5. Apresente a recomendação com o "porquê" (dados) e o impacto esperado.
6. **Execute a mudança de bid somente após confirmação humana explícita** — mudanças de bid resetam learning e movem gasto.
