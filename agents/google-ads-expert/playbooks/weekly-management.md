# Playbook: Weekly Management — Rotina Semanal de Gestão

## Quando usar
- Toda **segunda-feira**, por conta (cadência de revisão semanal).
- Sempre que o gestor faz uma pergunta operacional: "onde investir os próximos R$10k?", "qual campanha pausar?", "por que meu CPA subiu?".
- Este é o playbook que faz o agente ser um **gestor contínuo**, não só auditor. Ele conecta detecção de anomalias → diagnóstico → recomendação → confirmação → medição (loop GROW).

Diferença de mentalidade: auditoria é snapshot; gestão é trajetória. Aqui você compara sempre contra o baseline da semana/mês anterior.

---

## Passo 1 — Checklist de segunda-feira

Rode nesta ordem, por conta:

```
[ ] 1. GATE tracking-OK (conversion-audit.md, passo 6). Se falha, o resto dos números é suspeito.
[ ] 2. Detecção de anomalias (últimos 7d vs baseline) — passo 2.
[ ] 3. Pacing review (spend vs plano, diário/semanal/mensal) — passo 3.
[ ] 4. Fila de otimização priorizada (optimization.md) — o que mudou desde semana passada.
[ ] 5. Re-check de mutações da semana anterior (a agulha moveu? GROW) — passo 6.
[ ] 6. Responder perguntas abertas do gestor — passo 4.
[ ] 7. Decidir o que escalar ao humano — passo 5.
```

GAQL de abertura (WoW — week over week):

```sql
SELECT campaign.name, segments.date,
       metrics.cost_micros, metrics.conversions, metrics.conversions_value,
       metrics.clicks, metrics.impressions, metrics.average_cpc, metrics.average_cpm, metrics.ctr
FROM campaign
WHERE campaign.status = 'ENABLED' AND segments.date DURING LAST_14_DAYS
ORDER BY segments.date DESC
```

Compare os 7d recentes contra os 7d anteriores para todo sinal abaixo.

---

## Passo 2 — Detecção de anomalias

Dispare alerta quando:

| Anomalia | Gatilho | Provável causa |
|---|---|---|
| Spike de CPC/CPM | +30% em 1 dia | Aumento de competição, mudança de lance, sazonalidade |
| Queda de CVR | Abaixo do range histórico | Landing page, tracking quebrado, tráfego ruim |
| Burn de budget | 50% do budget diário nas primeiras 2h | Lance alto demais, tráfego de baixa qualidade, evento externo |
| CTR sobe mas conversões não | Divergência CTR↑ / conv→ | **Tracking quebrado** ou qualidade de tráfego/promessa da ad |
| Erros de tracking | Tag não dispara, conversões zeradas | Deploy quebrou o site, mudança de CMP/consent |

Classificação da resposta:
- **Ação crítica** (tracking failure, cost spike extremo): favorece ação imediata (após confirmação). Ex.: pausar campanha com burn anômalo, alertar sobre tag quebrada.
- **Issue menor**: gera alerta/recomendação para o batch da semana, não intervenção imediata.

"CTR sobe mas conversões não" é armadilha: quase sempre é tracking ou qualidade — **NÃO** otimize bids por cima disso. Volte ao gate de tracking.

---

## Passo 3 — Pacing review

```
spend_projetado_mês = (spend_acumulado / dias_decorridos) × dias_do_mês
```

- **Underpacing**: projeção <85% do budget mensal. Budget sobrando não entregue → checar budget-limited (não é), targets de Smart Bidding restritivos, IS saturado, lances baixos.
- **Overpacing**: burn diário esgotaria o mês antes do dia 25. Risco de ficar dark. Reduzir ritmo ou realocar.

Cruze pacing com performance: underpacing num top performer (CPA abaixo do target) é oportunidade de escalar (regra dos 20%). Overpacing num CPA acima do target é sangria a estancar. Detalhe em `budget-audit.md`.

---

## Passo 4 — Responder as perguntas do gestor

### "Onde investir os próximos R$10k?"
1. Aplicar 70/20/10: ~R$7k em proven performers budget-limited (G39, CPA/ROAS dentro do target, `search_budget_lost_impression_share` alto), ~R$2k em promising, ~R$1k em experimentos.
2. Validar suficiência: cada destino precisa suportar ≥15 conv/30d para Smart Bidding.
3. Respeitar regra dos 20% por campanha (não despejar tudo de uma vez — reseta learning).
4. Checar saturação: campanha com IS >80% tem retorno decrescente; preferir escala horizontal (novas geos/audiências).
5. Entregar tabela de alocação com CPA/ROAS esperado por destino + plano de medição.

### "Qual campanha pausar?"
1. 3x Kill Rule: `spend > 3× target_CPA E 0 conv`, com dados suficientes (≥7d, ≥20 clicks, ou ≥R$100).
2. Candidatas: CPA >3x target por ≥14d após ≥3 tentativas (princípio ACCEPT — está morta).
3. Antes de confirmar pausa, checar se a campanha é load-bearing em atribuição (pode estar assistindo conversões).
4. Propor mutação de pausa com confirmação; registrar.

### "Por que meu CPA subiu?"
Diagnóstico em árvore (não chute — puxe os dados, princípio OBSERVE):
```
CPA subiu →
├─ Conversões caíram? (numerador)
│  ├─ Tracking quebrou? → conversion-audit gate. CTR estável + conv↓ = tracking.
│  ├─ CVR caiu? → landing page, oferta, qualidade de tráfego
│  └─ Volume de conv caiu com CVR estável? → menos cliques (ver abaixo)
├─ Custo subiu? (denominador)
│  ├─ CPC/CPM +30%? → competição/sazonalidade/leilão
│  ├─ Target de bid mudou? → alguém editou tCPA/tROAS
│  └─ Match type / broad expandiu? → search terms irrelevantes novos (G16)
└─ Mudança recente? → checar histórico de edições + learning phase reativada
```
Sempre isole numerador vs denominador antes de recomendar. Reporte a causa raiz, não só o sintoma.

---

## Passo 5 — O que escalar ao humano

Decida por confirmação simples vs human-in-the-loop pleno:

| Situação | Tratamento |
|---|---|
| Mutação rotineira (budget ±20%, ajuste de target, negativa, pausa por 3x Kill) | WRITE com confirmação "confirmo" |
| Tracking failure / cost spike extremo | Ação imediata após confirmação |
| Mudança estrutural grande (rebuild, migração de estratégia em massa, mudança de atribuição da conta) | **Human-in-the-loop** — não basta "confirmo", exige decisão explícita do gestor com contexto |
| Divergência entre meta declarada e sinal de dados (diz "leads", só rastreia receita) | Escalar: nomear o gap, pedir alinhamento |
| Budget novo além do plano acordado | Escalar ao gestor |

---

## Passo 6 — Loop de re-auditoria (GROW)

Feche o ciclo toda semana:
1. Toda mutação da semana anterior tem plano de medição — cheque a janela (14d bidding, 30d estrutura, 90d estratégia).
2. Compare contra baseline: moveu na direção certa → manter/avançar; não moveu → reverter (ACCEPT), registrar aprendizado.
3. Atualize o baseline da conta para a próxima semana.
4. Re-auditoria completa a cada 30/90d comparando com o snapshot anterior — trajetória, não só o número da semana.

Toda recomendação carrega um plano de medição desde que nasce. Se não dá para medir se funcionou, não recomende.

---

## WRITE com confirmação (recap)

O agente lê ao vivo via Maton, recomenda a mutação exata, executa só após "confirmo", registra tudo. Nunca editar em learning phase ativa. Se Maton não expõe escrita, degradar para passo-a-passo manual. Use o template de mutação de `optimization.md` (passo 3).

---

## Formato de saída (report semanal ao gestor)

```
GESTÃO SEMANAL — [conta] — segunda [data]
Health Score: XX/100 (Δ vs semana passada: +X)

1. TRACKING GATE: [PASSA / BLOQUEIA]
2. ANOMALIAS DA SEMANA:
   - [🔴 crítica] CPC +42% em [camp] terça → investigar leilão
   - [🟡 menor] CVR de [camp] no limite inferior do range
3. PACING: [under/on/over]pacing — projeção R$X vs plano R$Y
4. RESULTADO DAS MUTAÇÕES DA SEMANA PASSADA:
   - [mutação]: CPA R$55→R$48 ✓ manter
5. AÇÕES PROPOSTAS ESTA SEMANA (fila priorizada):
   [mutações aguardando confirmação]
6. RESPOSTAS ÀS PERGUNTAS DO GESTOR: [se houver]
7. ESCALAR AO HUMANO: [itens que exigem decisão do gestor]
```
