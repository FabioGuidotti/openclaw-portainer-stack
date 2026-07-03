# Template de Relatório Executivo — Google Ads

<!-- Metodologia e sistema de scoring derivados do claude-ads (MIT). -->

Este é o template do relatório **executivo** — o entregável para C-level, sócios e clientes que decidem orçamento, não operam a conta. O objetivo é traduzir a auditoria técnica (80 checks Google, score 0-100) em **linguagem de negócio**: onde está o dinheiro vazando, quanto isso custa por mês em R$, e o que aprovar nesta semana. Regras de ouro deste documento: cabe em 1-2 páginas, zero jargão de gestor de tráfego (nada de "match type", "QS", "tCPA" sem tradução), e todo achado tem impacto financeiro estimado. Se o leitor for o CFO, ele precisa entender o custo da inação em 30 segundos.

---

## Estrutura obrigatória

O relatório executivo tem exatamente 5 blocos, nesta ordem:

1. **Health Score + Grade** — o número e o que ele significa.
2. **Diagnóstico em uma frase** — o estado da conta traduzido.
3. **Top findings (3 a 5)** — os achados de maior impacto em R$/receita.
4. **Quick wins** — o que dá para corrigir esta semana com ganho imediato.
5. **Próximos passos** — a decisão que pedimos ao cliente.

Nunca liste os 80 checks aqui. Nunca cole GAQL, tabela de severidade ou evidência técnica. Isso vive no relatório técnico (`technical.md`). O executivo referencia o técnico como anexo.

---

## Diretrizes de linguagem

- **Traduza tudo.** "Enhanced Conversions desativado" vira "estamos cegos para ~10% das vendas que o Google poderia atribuir". "Broad match sem Smart Bidding" vira "estamos deixando o Google gastar sem controle de custo".
- **Todo achado tem um número em R$.** Se não der para estimar receita, estime spend desperdiçado ou conversões perdidas. Sem número, o achado vira ruído.
- **Impacto = magnitude × confiança.** Deixe claro quando é estimativa ("~R$ 1.400/mês", "estimado", "faixa de"). Nunca prometa cifra exata que não dá para provar.
- **Foco em decisão, não em tarefa.** O executivo aprova prioridade e orçamento; o gestor executa. Termine sempre com uma pergunta de decisão clara.
- **Grade traduz urgência.** A=manutenção, B=oportunidades pontuais, C=atenção necessária, D=problemas sérios, F=intervenção urgente.

### Tabela de grades (referência de tradução)

| Grade | Score | Rótulo | Mensagem ao cliente |
|-------|-------|--------|---------------------|
| A | 90-100 | Excelente | Conta saudável. Otimizações finas apenas. |
| B | 75-89 | Bom | Bem gerida, com oportunidades pontuais de ganho. |
| C | 60-74 | Requer atenção | Problemas relevantes drenando resultado. Plano de ação recomendado. |
| D | 40-59 | Ruim | Problemas significativos. Perda de receita ativa. |
| F | <40 | Crítico | Intervenção urgente. A conta está perdendo dinheiro agora. |

---

## Como estimar impacto em R$ (regras de conversão)

Para manter os números defensáveis, use estas fórmulas simples e cite a base:

- **Spend desperdiçado (wasted spend):** `Σ custo de termos com >R$ 50 e 0 conversões (últimos 30d)`. Reporta como "R$ X/mês em cliques que nunca convertem".
- **Receita perdida por tracking:** se Enhanced Conversions/Consent Mode ausente, estime `receita atribuível atual × faixa de recuperação (10-25%)`. Sempre como faixa, nunca ponto fixo.
- **Conversões perdidas por budget cap:** `(impression share perdido por budget) × conversões atuais`. Traduza para R$ multiplicando por ticket médio.
- **Canibalização de marca (PMax/brand):** `conversões de marca capturadas pela PMax × CPA de marca` = valor que estava sendo pago caro por tráfego que viria orgânico/barato.

Regra: subestime, não superestime. Um número conservador que se confirma vale mais que um otimista que decepciona.

---

## TEMPLATE (preencher)

```markdown
# Auditoria Google Ads — {NOME_CLIENTE}
**Data:** {DATA} · **Período analisado:** últimos 30 dias · **Spend/mês:** R$ {SPEND}

## Health Score
**{SCORE}/100 — Grade {GRADE} ({RÓTULO})**
{Uma frase traduzindo o estado da conta em impacto de negócio.}

## Top findings (impacto estimado)
1. **{Título de negócio}** — {impacto em R$/mês}. {1 frase de contexto.}
2. ...
(3 a 5 itens, ordenados por impacto × confiança)

## Quick wins (esta semana)
- {Ação} → {ganho estimado} · {tempo de execução}
- ...

## Próximos passos
{A decisão que pedimos ao cliente + prazo sugerido de re-auditoria.}

> Detalhamento técnico completo (80 checks, evidências, queries) no anexo técnico.
```

---

## EXEMPLO PREENCHIDO (fictício)

```markdown
# Auditoria Google Ads — Loja Aurora (e-commerce moda)
**Data:** 03/07/2026 · **Período analisado:** últimos 30 dias · **Spend/mês:** R$ 82.000

## Health Score
**63/100 — Grade C (Requer atenção)**
A conta gera vendas, mas está pagando caro por tráfego que não converte e
enxergando menos vendas do que realmente acontecem. Corrigindo três frentes,
a estimativa é recuperar de R$ 14 mil a R$ 22 mil por mês entre economia de
verba e receita hoje invisível.

## Top findings (impacto estimado)
1. **Estamos cegos para ~15-20% das vendas.** O rastreamento avançado de
   conversões (Enhanced Conversions) e o Consent Mode V2 não estão ativos.
   O Google decide onde investir com dados incompletos, o que encarece cada
   venda. **Impacto: ~R$ 9.000/mês em receita não atribuída** + decisões de
   lance mal informadas em toda a conta.
2. **R$ 6.400/mês em cliques que nunca viram venda.** 22% da verba de busca
   foi para termos irrelevantes nos últimos 30 dias, sem listas de palavras
   negativas para bloquear. **Impacto: ~R$ 6.400/mês de desperdício direto.**
3. **A campanha PMax está "roubando" vendas de marca.** 34% das conversões da
   PMax vêm de quem já buscava "Loja Aurora" — tráfego barato que estamos
   pagando como se fosse novo cliente. **Impacto: ~R$ 3.100/mês de CPA inflado.**
4. **As duas campanhas de maior retorno estão limitadas por orçamento.** Elas
   batem o teto de verba antes do meio-dia. **Impacto: ~R$ 4.000/mês em vendas
   deixadas na mesa** (estimativa conservadora por impression share perdido).

## Quick wins (esta semana)
- Ativar Enhanced Conversions no painel de conversões → recupera atribuição de
  ~10% das vendas · 5 min
- Criar listas de palavras negativas (concorrente, grátis, vagas) → corta parte
  do desperdício de R$ 6.400/mês · 10 min
- Adicionar exclusão de marca na PMax → reduz canibalização · 10 min
- Ativar sitelinks nas 3 campanhas sem extensões → +CTR sem custo extra · 10 min

## Próximos passos
Pedimos aprovação para: (1) executar os 4 quick wins ainda esta semana e
(2) iniciar o plano de 30/60/90 dias anexo, focado em tracking e reestruturação
de campanhas. Re-auditoria completa em 30 dias para medir o ganho recuperado.

> Detalhamento técnico completo (80 checks, evidências, queries GAQL) no anexo técnico.
```

---

## Relação com os outros entregáveis

O executivo é a camada de topo de um conjunto de três relatórios que saem da **mesma auditoria** (mesmo score, mesmos findings, mesmo schema JSON):

- **Executivo** (este) — para quem decide. Score, impacto em R$, decisão a aprovar.
- **Técnico** (`technical.md`) — para quem executa. Todos os checks com ID/severity/evidência/GAQL, quick wins com passo a passo, schema JSON.
- **Roadmap** (`roadmap.md`) — quando cada correção acontece. Findings por prazo (30/60/90), owner, métrica de sucesso, re-auditoria GROW.

Os três nunca podem divergir no número: o `ads_health_score` e o `grade` vêm do schema JSON canônico definido no relatório técnico. O executivo apenas **traduz** os `top_findings` desse schema para linguagem de negócio. Se o cliente pedir prova, o técnico é o anexo; se pedir prazo, o roadmap é o anexo.

## Checklist de qualidade antes de entregar

- [ ] Score e grade batem com o relatório técnico (mesma auditoria).
- [ ] Cada top finding tem um número em R$ e a palavra "estimado/~/faixa" quando for estimativa.
- [ ] Zero jargão sem tradução. Leia em voz alta imaginando o CFO ouvindo.
- [ ] Quick wins são todos Critical/High com fix <15 min (senão vão para o roadmap).
- [ ] Termina com uma decisão clara e um prazo de re-auditoria.
- [ ] Cabe em 1-2 páginas. Se passou disso, cortou pouco.
