# Playbook: Budget Audit — Alocação e Pacing

## Quando usar
- O gestor pergunta "onde investir os próximos R$X?" ou "estou gastando bem?".
- Você suspeita de campanhas budget-limited estrangulando top performers.
- Revisão semanal (segunda-feira) ou re-auditoria de 30/90d (princípio GROW).
- Antes de qualquer recomendação de escala: budget precisa suportar Smart Bidding.

Este playbook cobre os checks **G08, G09, G39** (budget-limited), pacing math e realocação. Sempre rode `conversion-audit.md` antes: sem tracking confiável, todo número de CPA/ROAS abaixo é ficção.

---

## Passo 1 — OBSERVE: puxar os dados ao vivo (Maton/GAQL)

Puxe budget configurado + spend + performance dos últimos 30d por campanha. Rode ao vivo via Maton.

```sql
SELECT
  campaign.id,
  campaign.name,
  campaign.status,
  campaign.advertising_channel_type,
  campaign_budget.amount_micros,
  campaign_budget.explicitly_shared,
  campaign.bidding_strategy_type,
  metrics.cost_micros,
  metrics.conversions,
  metrics.conversions_value,
  metrics.clicks,
  metrics.impressions
FROM campaign
WHERE campaign.status = 'ENABLED'
  AND segments.date DURING LAST_30_DAYS
ORDER BY metrics.cost_micros DESC
```

Sinal de budget-limited (G08/G09/G39). O campo canônico é o Budget Lost IS:

```sql
SELECT
  campaign.id,
  campaign.name,
  metrics.search_budget_lost_impression_share,
  metrics.search_impression_share,
  metrics.cost_micros,
  metrics.conversions
FROM campaign
WHERE campaign.status = 'ENABLED'
  AND segments.date DURING LAST_30_DAYS
ORDER BY metrics.search_budget_lost_impression_share DESC
```

Para pacing intra-dia (burn), puxe spend segmentado por dia dos últimos 7d e por hora do dia corrente:

```sql
SELECT campaign.name, segments.date, metrics.cost_micros
FROM campaign
WHERE campaign.status = 'ENABLED' AND segments.date DURING LAST_7_DAYS
ORDER BY segments.date
```

> Notas: `amount_micros` e `cost_micros` estão em micros (÷ 1.000.000 = R$). `explicitly_shared = true` indica shared budget entre campanhas — realocação exige mexer no shared budget, não na campanha.

**Validação de suficiência de dados** (SKILL ads-budget): só avalie kill/scale se o spend cobre ≥14 dias E a campanha tem ≥20 clicks ou ≥R$100 de spend. Abaixo disso é exploração, não sinal.

---

## Passo 2 — THINK: pacing math

Compare spend real vs plano nos horizontes diário / semanal / mensal.

```
budget_mensal_planejado = daily_budget × dias_do_mês
spend_projetado = (spend_acumulado_no_mês / dias_decorridos) × dias_do_mês
```

- **Underpacing**: `spend_projetado < 85% do budget_mensal_planejado`. Budget disponível não está sendo entregue → verificar budget-limited (não é o caso aqui), lances baixos, targets de Smart Bidding restritivos demais, ou audiência esgotada (IS > 80%).
- **Overpacing**: burn diário esgotaria o mês antes do dia 25. `spend_acumulado / dias_decorridos × 30 > budget_mensal` com folga. Risco de ficar dark no fim do mês.
- **Burn intra-dia** (anomalia): 50% do daily budget nas primeiras 2h → alerta imediato. Investigar spike de CPC/CPM, tráfego de baixa qualidade, ou evento externo.

MER (Marketing Efficiency Ratio) — sempre acima do ROAS de plataforma (que superestima 20-40%):

```
MER = Receita total / Spend total (todas as plataformas)
```

| Tipo de negócio | MER saudável | Excelente | Zona de perigo |
|---|---|---|---|
| E-commerce | 3.0-5.0 | >5.0 | <2.0 |
| SaaS | LTV:CAC 3:1 | >4:1 | <2:1 |
| Lead Gen | Receita/Lead × CVR / CPL | — | <1.5 |

Se MER e ROAS de plataforma divergem >30%, confie no MER/CRM e sinalize o gap (princípio ACCEPT).

---

## Passo 3 — Checks e regras

| Check | PASS | WARNING | FAIL |
|---|---|---|---|
| G08 Budget vs prioridade | Top performers não budget-limited | Restrição menor em top performers | Top performers severamente limitados |
| G09 Daily budget vs spend | Nenhuma campanha atinge cap antes das 18h | 1-2 atingem cap cedo | Várias capadas antes do meio-dia |
| G39 Budget-constrained | Top performers "Eligible", não "Limited by Budget" | Limitação menor | Top performers severamente limitados |

Severidade: G08=High (3.0), G09=Medium (1.5), G39=High (3.0). Contribuem para o Health Score via `Σ(C_pass × W_sev × W_cat)/Σ(...) × 100` (PASS=1 / WARNING=0.5 / FAIL=0).

**Definição de "top performer"**: campanha com CPA abaixo do target OU ROAS acima do target, com ≥15 conv/30d. É nela que a realocação deve concentrar budget.

**Budget-limited real**: `search_budget_lost_impression_share > 10%` E CPA/ROAS dentro do target. Se está budget-limited MAS o CPA já está acima do target, escalar budget só amplifica o desperdício — não realocar para lá.

---

## Passo 4 — Sufficiency para Smart Bidding

Antes de recomendar tCPA/tROAS ou escala, valide o piso de dados:

- Smart Bidding exige **≥15 conv/30d** por campanha (ideal 30+ para tCPA, 50+ para tROAS).
- Budget mínimo Google Search: ~R$20/dia (suficiente para 15+ conv/mês com CPA típico). PMax: ~R$50/dia.
- Se a campanha não bate o piso mas há várias campanhas pequenas correlatas, recomendar **portfolio bid strategy** (ver `bidding-audit.md`, G41) em vez de escalar isoladamente.

Se budget está abaixo do piso de suficiência, a recomendação NÃO é "escalar aos poucos" — é "consolidar ou levar ao piso de uma vez", senão a campanha nunca sai do learning.

---

## Passo 5 — Realocação (70/20/10 + regra dos 20%)

Distribuição-alvo do budget total:

```
70% → proven performers (ROAS/CPA estabelecido dentro do target)
20% → promising growth (tração, precisa de dados/escala)
10% → experiments (novas audiências, formatos, campanhas)
```

Regra dos 20% para escalar um top performer budget-limited:

```
SE actual_CPA < target_CPA em >10%
E conversões_últimos_7d >= threshold de learning
E campanha NÃO está em learning phase
ENTÃO aumentar budget em 20%
→ aguardar 3-5 dias antes do próximo aumento
```

Fonte do budget para realocar: campanhas overpacing com CPA acima do target, ou os 10% de experimentos que falharam. Aplicar 3x Kill Rule onde couber (CPA >3x target → pausar; ver `optimization.md`).

Detecção de retornos decrescentes: se após um aumento o CPA subir >15%, reverter ao nível anterior e tentar escala horizontal (novas audiências/geos) em vez de vertical.

Saturação (Google): Impression Share >80% → retornos decrescentes, diversificar em vez de despejar mais budget.

---

## Passo 6 — WRITE com confirmação

O agente **lê ao vivo, recomenda a mutação exata, e SÓ executa após "confirmo"**. Toda mutação é registrada. Se Maton não expõe escrita de budget, degradar para passo-a-passo manual.

Formato da recomendação de mutação:

```
MUTAÇÃO PROPOSTA (aguardando confirmação)
Campanha: [nome] (id: 12345)
Ação: campaign_budget.amount_micros 100000000 → 120000000 (R$100/dia → R$120/dia, +20%)
Motivo: G39 FAIL, search_budget_lost_IS 34%, CPA R$42 vs target R$55 (top performer)
Regra aplicada: 20% Rule (não exceder +20% de uma vez)
Medição (GROW): re-checar CPA e budget_lost_IS em 5 dias; reverter se CPA subir >15%
Confirma? (responda "confirmo" para executar)
```

Nunca editar campanha em **learning phase ativa** (Quality Gate). Se a campanha está "Learning", segurar a mutação e avisar.

---

## Formato de saída (relatório ao gestor)

```
BUDGET AUDIT — [conta] — [data]

Pacing do mês: [under/on/over]pacing — projeção R$X vs plano R$Y (Z%)
Score de alocação: XX/100

TOP PERFORMERS ESTRANGULADOS (G39 FAIL):
- [Campanha]: budget_lost_IS 34%, CPA R$42 (target R$55) → +20% budget

DESPERDÍCIO / REALOCAR DE:
- [Campanha]: overpacing, CPA R$120 (target R$55, >2x) → -50% budget

REALOCAÇÃO PROPOSTA (net R$0 ou +R$X do gestor):
[tabela: campanha | budget atual | budget proposto | motivo]

MER atual: X.X (saudável/perigo)
Suficiência p/ Smart Bidding: [campanhas abaixo de 15 conv/30d]

MUTAÇÕES AGUARDANDO CONFIRMAÇÃO: [lista]
```

Sempre anexe o plano de medição (GROW): o que re-checar e quando (30/90d contra baseline).
