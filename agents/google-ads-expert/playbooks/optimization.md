# Playbook: Optimization — Ciclo de Otimização Contínua

## Quando usar
- Depois de uma auditoria, para transformar findings em ações executadas.
- Ciclo recorrente de melhoria (o "fazer" que segue o "diagnosticar").
- Quando há uma lista de issues e você precisa decidir o que fazer primeiro e propor as mutações.

Este playbook orquestra os demais. A sequência é fixa; a priorização dentro de cada etapa é por severidade × impacto.

---

## Princípio: a sequência ideal (nunca pule etapas)

```
1. TRACKING   → conversion-audit.md. Se o gate falha, PARE aqui. Nada mais é confiável.
2. WASTE      → cortar spend em termos/keywords irrelevantes (negativas, 3x Kill Rule).
3. STRUCTURE  → separação brand/non-brand, single-theme ad groups, budget-limited.
4. BIDDING    → bidding-audit.md. Estratégia certa para o volume, targets razoáveis.
5. CREATIVE   → RSA strength, headlines, assets de PMax/Demand Gen.
```

Por que a ordem importa (princípio CONNECT — o sistema é acoplado):
- Otimizar bidding antes de corrigir tracking = otimizar para dados falsos.
- Escalar budget antes de cortar waste = amplificar o desperdício.
- Ajustar creative antes de estrutura = polir peças que estão no ad group errado.

---

## Passo 1 — Priorização: severity × impacto

Cada issue vem de um check com severidade conhecida. Ordene a fila por um score de prioridade:

```
prioridade = W_sev × impacto_estimado × facilidade
```

- **W_sev**: Critical 5.0, High 3.0, Medium 1.5, Low 0.5.
- **impacto_estimado**: quanto de spend/conversão a ação move (ex.: % do budget afetado, R$ de waste eliminado).
- **facilidade**: Quick Wins (Critical/High + fix <15 min) sobem na fila.

Regra prática de ordenação:
1. **Critical que quebram o gate** (tracking) → sempre primeiro.
2. **Quick Wins** (G43 Enhanced Conversions 5min, G11 location 2min, G17 broad+manual 5min, G12 display off 2min, G-PM6 negativas PMax 10min).
3. **Waste de alto R$** (G16 termos irrelevantes >15% do spend, G-WS1 keywords com >100 clicks e 0 conv).
4. **High de estrutura/bidding** (G37 target irreal, G39 budget-limited, G05 brand mixing).
5. **Medium/Low** por último.

Não empilhe mutações conflitantes (princípio CONNECT-System): não recomende "+30% budget" e "pausar" na mesma campanha sem explicitar o trade-off.

---

## Passo 2 — 3x Kill Rule

```
SE spend > 3× target_CPA E conversões == 0
ENTÃO pausar ad/ad group/campanha imediatamente (após confirmação)
→ revisar: creative, targeting, landing page, tracking
→ não reativar sem mudanças
```

Requisitos de dados antes de matar (evita pausar por falta de sinal):

| Cenário | Dados mínimos | Ação |
|---|---|---|
| CPA >3x target | ≥7 dias, ≥20 clicks | Pausar imediatamente |
| 0 conversões | ≥R$100 spend ou ≥50 clicks | Pausar e diagnosticar |
| CTR <50% do benchmark | ≥1.000 impressões | Matar creative, testar novo |
| ROAS <50% do target | ≥14 dias | Reduzir budget 50% ou pausar |

Princípio ACCEPT: se a campanha já teve 3+ tentativas de otimização e continua >3x target, ela está morta — pare de ajustar. Antes de pausar, confirme que a campanha não é load-bearing em atribuição invisível (pode estar assistindo conversões creditadas a outra).

GAQL para achar candidatos a kill:

```sql
SELECT campaign.name, metrics.cost_micros, metrics.conversions, metrics.clicks
FROM campaign
WHERE campaign.status = 'ENABLED' AND segments.date DURING LAST_14_DAYS
ORDER BY metrics.cost_micros DESC
```

E waste em search terms (G16/G-WS1 — só flagar >R$10 spend E 0 conv):

```sql
SELECT search_term_view.search_term, metrics.cost_micros, metrics.conversions, metrics.clicks
FROM search_term_view
WHERE segments.date DURING LAST_30_DAYS
ORDER BY metrics.cost_micros DESC
```

---

## Passo 3 — Propor mutações com confirmação

Autonomia = READ + WRITE COM CONFIRMAÇÃO. O agente lê ao vivo, recomenda a mutação exata, executa **só** após "confirmo" explícito, e registra toda mutação. Se Maton não expõe escrita, degradar para passo-a-passo manual.

Template de mutação (use sempre este formato):

```
MUTAÇÃO PROPOSTA (aguardando confirmação) — #N na fila de prioridade
Alvo: [campanha/ad group/keyword] (id: XXX)
Ação: [campo] [valor atual] → [valor novo]
Check/regra: [G-ID + regra aplicada]
Motivo: [dado observado ao vivo]
Pré-checks: [gate tracking OK? não está em learning? dados suficientes?]
Impacto esperado: [R$ / conversões / CPA]
Medição (GROW): [métrica + janela 14/30/90d vs baseline]
Confirma? (responda "confirmo")
```

Quality Gates que travam a mutação (verifique antes de propor):
- Nunca Broad match sem Smart Bidding.
- Nunca editar campanha em **learning phase ativa**.
- Smart Bidding exige ≥15 conv/30d.
- Tracking OK antes de otimizar (gate de conversion-audit).
- 3x Kill Rule para pausas.

Ações **críticas** (tracking failure, cost spike extremo) favorecem ação imediata após confirmação. Issues menores geram alerta/recomendação para o batch semanal. Mudanças estruturais grandes (rebuild de conta, migração de estratégia em massa) exigem human-in-the-loop além da confirmação simples.

---

## Passo 4 — Medir o resultado (GROW)

Toda mutação executada entra num registro com plano de medição. Sem medição, não há aprendizado.

```
REGISTRO DE MUTAÇÃO
Data: [quando executada]
Mutação: [o que mudou]
Baseline: [CPA/ROAS/conv/spend antes]
Janela de avaliação: [14d p/ bidding, 30d p/ estrutura, 90d p/ estratégia]
Resultado esperado: [hipótese]
```

Na re-auditoria (30/90d), compare contra o baseline:
- Moveu a agulha na direção certa → manter, considerar próximo passo (ex.: próximo +20% de budget).
- Não moveu ou piorou → princípio ACCEPT: reverter, não dobrar a aposta. Registrar o aprendizado para o próximo ciclo.
- Retornos decrescentes (CPA +15% após aumento de budget) → reverter ao nível anterior, tentar escala horizontal.

---

## Formato de saída

```
PLANO DE OTIMIZAÇÃO — [conta] — [data]
Gate tracking-OK: [PASSA / BLOQUEIA]

FILA PRIORIZADA (severity × impacto × facilidade):
1. [Critical/Quick Win] G45 Consent Mode → checklist manual
2. [Quick Win] G17 Broad+Manual em [camp] → Smart Bidding
3. [Waste] G-WS1 [keyword] 240 clicks/0 conv/R$380 → pausar (3x Kill)
4. [High] G39 [camp top] budget-limited → +20% budget
5. [Medium] ...

MUTAÇÕES AGUARDANDO CONFIRMAÇÃO: [lista com template]

REGISTRO / MEDIÇÃO:
[mutações já executadas + janela de re-check]
```

Sequência de entrega: tracking → waste → structure → bidding → creative. Nunca inverta.
