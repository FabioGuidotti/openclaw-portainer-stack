# Template de Roadmap de Otimização 30/60/90 — Google Ads

<!-- Prazos derivados dos critérios de severidade do claude-ads (MIT). Framework GROW aplicado à re-auditoria. -->

Este é o template do **roadmap de otimização** — a ponte entre "o que está errado" (relatório técnico) e "quando cada coisa será corrigida". Ele reorganiza os findings da auditoria por **prazo de execução**, não por categoria, porque quem vai tocar o plano pensa em janelas de tempo: o que faço hoje, esta semana, este mês, este trimestre. Cada item carrega um **owner** e uma **métrica de sucesso** mensurável — sem métrica, o item não entra no roadmap. Ao final, um **plano de re-auditoria** sob o princípio GROW fecha o loop: medir o ganho real e recalibrar.

---

## Mapeamento severity → prazo

O prazo de cada item deriva diretamente da severity do finding (critérios do sistema de scoring):

| Severity | Prazo | Janela | Racional |
|----------|-------|--------|----------|
| Critical | Imediato | 0-7 dias | Risco de perda de receita/dados agora. Remediação urgente. |
| High | Curto | 7-30 dias | Arrasto significativo de performance. Corrigir em até 30d. |
| Medium | Médio | 30-60 dias | Oportunidade de otimização. |
| Low | Longo/backlog | 60-90 dias | Best practice, impacto menor. Nice to have. |

**Quick wins furam a fila:** qualquer Critical/High com fix <15 min vai para "esta semana" independentemente da complexidade do resto do roadmap. São ganho imediato de baixo esforço.

---

## Estrutura obrigatória

1. **Resumo do roadmap** — quantos itens por janela, ganho total estimado.
2. **Sprint 0 — Quick wins (esta semana)** — Critical/High <15 min.
3. **30 dias (Critical + High)** — o que estabiliza a conta.
4. **60 dias (Medium)** — otimização estrutural.
5. **90 dias / backlog (Low)** — refinamento e best practices.
6. **Plano de re-auditoria (GROW)** — quando e como medir.

Cada item segue o formato:

```markdown
- **[{ID}] {Ação}** · Owner: {owner} · Métrica de sucesso: {métrica mensurável + alvo} · Impacto: {R$/mês}
```

A **métrica de sucesso** é o alvo verificável na re-auditoria — ex.: "wasted spend <5% do total (hoje 22%)", "Enhanced Conversions ativo e verificado nas 4 conversões primárias", "0 campanhas top limitadas por budget".

---

## Owners (mapa de responsáveis)

| Owner | Escopo |
|-------|--------|
| tracking | Conversões, Enhanced Conversions, Consent Mode V2, GA4, tags |
| search | Termos de busca, negativas, keywords, QS, RSAs de Search |
| pmax | Performance Max, asset groups, brand exclusions, search themes |
| creative | Assets de anúncio, RSA strength, vídeo, freshness (parte subjetiva é manual) |
| account | Estrutura, budgets, bidding, settings, extensões, targeting |

---

## TEMPLATE (preencher)

```markdown
# Roadmap de Otimização — {NOME_CLIENTE}
**Data:** {DATA} · **Health Score atual:** {SCORE}/100 ({GRADE}) · **Meta 90d:** {SCORE_META}/100

## Resumo
- Sprint 0 (quick wins): {n} itens · ganho ~R$ {v}/mês
- 30d (Critical/High): {n} itens · ganho ~R$ {v}/mês
- 60d (Medium): {n} itens
- 90d/backlog (Low): {n} itens
- **Ganho total estimado: ~R$ {V}/mês ao completar o roadmap**

## Sprint 0 — Quick wins (esta semana)
- **[{ID}] {ação}** · Owner: {} · Métrica: {} · Impacto: {}

## 30 dias — Estabilização (Critical + High)
- **[{ID}] {ação}** · Owner: {} · Métrica: {} · Impacto: {}

## 60 dias — Otimização estrutural (Medium)
- **[{ID}] {ação}** · Owner: {} · Métrica: {}

## 90 dias / backlog — Refinamento (Low)
- **[{ID}] {ação}** · Owner: {} · Métrica: {}

## Plano de re-auditoria (GROW)
{Ver seção GROW abaixo.}
```

---

## EXEMPLO PREENCHIDO (fictício)

```markdown
# Roadmap de Otimização — Loja Aurora (e-commerce moda)
**Data:** 03/07/2026 · **Health Score atual:** 63/100 (C) · **Meta 90d:** 82/100 (B)

## Resumo
- Sprint 0 (quick wins): 4 itens · ganho ~R$ 12.000/mês
- 30d (Critical/High): 5 itens · ganho ~R$ 8.000/mês
- 60d (Medium): 4 itens
- 90d/backlog (Low): 2 itens
- **Ganho total estimado: ~R$ 20.000/mês ao completar o roadmap**

## Sprint 0 — Quick wins (esta semana)
- **[G43] Ativar Enhanced Conversions** · Owner: tracking · Métrica: EC ativo e
  verificado nas 4 conversões primárias · Impacto: recupera ~10% de atribuição (~R$ 9.000/mês)
- **[G14] Criar 3 listas de negativas temáticas (concorrente, grátis, vagas)** ·
  Owner: search · Métrica: ≥3 listas aplicadas em nível de conta · Impacto: corta parte dos R$ 6.400/mês
- **[G-PM6] Adicionar negativas em nível de campanha na PMax** · Owner: pmax ·
  Métrica: negativas de marca + irrelevantes ativas · Impacto: reduz canibalização
- **[G50] Adicionar 4+ sitelinks nas 3 campanhas sem extensões** · Owner: account ·
  Métrica: ≥4 sitelinks por campanha · Impacto: +CTR sem custo extra

## 30 dias — Estabilização (Critical + High)
- **[G45] Implementar Consent Mode V2 Advanced** · Owner: tracking · Métrica: modo
  Advanced ativo, modelagem comportamental habilitada · Impacto: recupera 15-25% de conversões EEA
- **[G16] Zerar wasted spend com revisão de termos + negativas** · Owner: search ·
  Métrica: wasted spend <5% do total (hoje 22%) · Impacto: ~R$ 6.400/mês
- **[G-PM3] Configurar brand exclusions na PMax** · Owner: pmax · Métrica: conversões
  de marca na PMax <15% (hoje 34%) · Impacto: ~R$ 3.100/mês
- **[G08/G39] Elevar budget das 2 campanhas top limitadas** · Owner: account ·
  Métrica: 0 campanhas top com status "Limited by Budget" · Impacto: ~R$ 4.000/mês
- **[G05] Separar keywords de marca em campanha dedicada** · Owner: search ·
  Métrica: marca e não-marca em campanhas separadas · Impacto: CPA de marca isolado e reduzido

## 60 dias — Otimização estrutural (Medium)
- **[G48] Migrar atribuição para Data-Driven (DDA)** · Owner: tracking · Métrica: DDA ativo em todas as conversões controladas pelo anunciante
- **[G-KW1] Limpar keywords com 0 impressões (30d)** · Owner: search · Métrica: <10% de keywords zero-impressão
- **[G33] Segmentar PMax em ≥2 asset groups por intenção** · Owner: pmax · Métrica: ≥2 asset groups por campanha PMax
- **[G01/G02] Padronizar convenção de nomenclatura** · Owner: account · Métrica: padrão consistente em 100% das campanhas/ad groups

## 90 dias / backlog — Refinamento (Low)
- **[G10] Configurar ad schedule conforme horário comercial** · Owner: account · Métrica: schedule ativo
- **[G55] Testar lead form extensions** · Owner: account · Métrica: 1 teste rodando

## Plano de re-auditoria (GROW)
Ver seção abaixo.
```

---

## Plano de re-auditoria — princípio GROW

O roadmap não é entregue e esquecido: ele é medido. Aplicamos o ciclo **GROW** para transformar cada re-auditoria em recalibração, não em repetição.

- **G — Goal (meta):** definida no topo do roadmap. Ex.: sair de 63 (C) para 82 (B) em 90 dias, recuperando ~R$ 20 mil/mês. Cada item tem sua métrica de sucesso — a soma delas é a meta.
- **R — Reality (realidade):** a re-auditoria mede o estado atual **com a mesma metodologia** (mesmos 80 checks, mesmo score ponderado, mesma janela de 30d). Comparar score global, score por categoria e o status de cada finding do roadmap (resolvido / parcial / não iniciado).
- **O — Options (opções):** para itens não resolvidos ou que não moveram a métrica, reavaliar a abordagem. Um finding que continua FAIL após a ação planejada indica ou execução incompleta ou hipótese errada — gerar novas opções, não repetir a mesma tarefa.
- **W — Will (compromisso):** repriorizar o próximo ciclo. Itens resolvidos saem; itens parciais viram Critical/High do próximo roadmap; novos findings da re-auditoria entram no mapa severity→prazo.

### Cadência de re-auditoria

| Momento | Escopo | O que medir |
|---------|--------|-------------|
| +7 dias | Verificação de quick wins | Cada QW do Sprint 0 aplicado e validado (checklist, não score) |
| +30 dias | Re-auditoria dos Critical/High | Score global + categorias Tracking e Wasted Spend; findings 30d resolvidos |
| +60 dias | Re-auditoria completa (80 checks) | Score global vs meta; todos os findings 30d/60d; recalibrar 90d |
| +90 dias | Fechamento do ciclo + novo roadmap | Meta atingida? Gerar próximo roadmap com o GROW → W |

### Regras da re-auditoria

- **Mesma metodologia sempre.** Score só é comparável se os pesos, severidades e janela forem idênticos. Documentar qualquer mudança de metodologia como quebra de série.
- **Medir a métrica de sucesso, não a atividade.** "Negativas adicionadas" não é sucesso; "wasted spend caiu de 22% para 4%" é.
- **Atribuir o ganho.** Onde possível, comparar spend/receita antes×depois para provar o R$ recuperado. Isso sustenta a renovação do contrato.
- **Checks manuais (G59-61, Consent Mode V2, criativo) re-verificados fora do GAQL** — não deixar cair do radar só por não serem automatizáveis.

---

## Checklist de qualidade antes de entregar

- [ ] Todo item tem owner e métrica de sucesso mensurável com alvo numérico.
- [ ] Prazos batem com o mapa severity→prazo (Critical=7d, High=30d, Medium=60d, Low=90d).
- [ ] Quick wins (<15 min, Critical/High) estão no Sprint 0, não diluídos no 30d.
- [ ] Meta 90d (G do GROW) coerente com a soma dos impactos estimados.
- [ ] Cadência de re-auditoria definida com datas concretas.
- [ ] IDs de finding rastreiam de volta ao relatório técnico e ao schema JSON.
