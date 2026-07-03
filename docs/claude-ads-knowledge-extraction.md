# Claude Ads — Extração de Conhecimento (Fonte da Verdade)

> **Fase 1 da demanda.** Engenharia reversa da metodologia de PPC do repositório
> [`AgriciDaniel/claude-ads`](https://github.com/AgriciDaniel/claude-ads) (v1.7.1,
> MIT), catalogando critérios, heurísticas, lógica de priorização, benchmarks,
> regras de decisão, fluxo de raciocínio, templates e sequência ideal — adaptada
> para um **consultor permanente de Google Ads no OpenClaw** com Maton como camada
> de execução de dados ao vivo.
>
> Este documento é a referência conceitual. A materialização operacional está em
> `agents/google-ads-expert/` (system-prompt, knowledge, playbooks, scoring, reports).

## Índice

1. [Filosofia](#capítulo-1--filosofia)
2. [Framework de Auditoria](#capítulo-2--framework-de-auditoria)
3. [Framework de Gestão](#capítulo-3--framework-de-gestão)
4. [Framework de Otimização](#capítulo-4--framework-de-otimização)
5. [Framework de Relatórios](#capítulo-5--framework-de-relatórios)
6. [Regras de Decisão](#capítulo-6--regras-de-decisão)
7. [Playbooks](#capítulo-7--playbooks)
8. [Benchmarks](#capítulo-8--benchmarks)
9. [Anti-patterns](#capítulo-9--anti-patterns)
10. [Prompt Strategy](#capítulo-10--prompt-strategy)

---

## Capítulo 1 — Filosofia

### 1.1 O que o claude-ads é

Um skill/plugin do Claude Code que faz **auditoria de mídia paga** em 8 plataformas
(Google, Meta, YouTube, LinkedIn, TikTok, Microsoft, Apple, Amazon), com **250+
checks**, Health Score 0–100 ponderado, e plano de ação priorizado. Uma auditoria
manual de conta Google que levaria 4–6h de um PPC sênior é entregue em 10–15 min,
de forma **local, determinística e repetível**.

Arquitetura: um **orquestrador** (`ads/SKILL.md`) roteia comandos para **22
sub-skills** e **10 agentes** (6 de auditoria + 4 de criação), com **26 arquivos
de referência** carregados sob demanda (padrão RAG) e templates por indústria.

### 1.2 Princípios de projeto herdados

- **Determinístico e auditável.** Mesmos inputs → mesmo score. Regras explícitas,
  não "achismo". O projeto original tem 41 testes de pytest que travam a matemática
  do score, a cobertura do catálogo de checks e o roteamento.
- **Local-first / privacidade.** Nenhum dado de conta vai para servidor de
  terceiros; quando há MCP ao vivo, o dado flui direto máquina→API da plataforma.
- **Tracking é a fundação.** Conversion tracking recebe o maior peso (25–30%),
  porque tracking quebrado invalida toda decisão de otimização a jusante.
- **Contexto antes de julgamento.** Nada é auditado sem indústria, budget e
  objetivo — os mesmos números significam coisas diferentes em contas de tamanhos
  e metas distintas.
- **Recência de plataforma.** O diferencial é conhecer o que mudou em 2026 (AI Max,
  PMax, Demand Gen, Consent Mode V2, DDA), não o que "costumava importar".

### 1.3 A evolução que esta implementação faz (auditor → gestor)

O claude-ads é desenhado para **executar uma auditoria**. O GoogleAdsExpert vai além:
é um **gestor de mídia permanente**. As diferenças de filosofia:

| claude-ads (auditor) | GoogleAdsExpert (gestor) |
|---|---|
| Auditoria pontual sob demanda | Gestão contínua + rotina semanal |
| Dados colados/exportados (MCP opcional) | **Dados ao vivo por padrão** via Maton/GAQL |
| Recomenda; humano executa tudo | **Recomenda e executa com confirmação** |
| Foto do momento | **Trajetória** (baseline + comparação temporal) |
| Multi-plataforma amplo | **Google em profundidade** + frameworks reusáveis |

---

## Capítulo 2 — Framework de Auditoria

### 2.1 Estrutura de um check

Cada check tem: **ID** (ex.: G17), **descrição**, **severidade** (Critical/High/
Medium/Low) e três limiares — **Pass**, **Warning**, **Fail**. Convenção de ID:
sequenciais (G01–G61) = v1.0; hifenizados (G-AI1, G-PM3, G-WS1) = adições v1.5+.
Prefixos: G=Google, M=Meta, L=LinkedIn, T=TikTok, MS=Microsoft, ASA=Apple,
X=cross-platform.

### 2.2 As 7 categorias do Google (pesos)

| Categoria | Peso | Checks |
|---|---|---|
| Conversion Tracking | 25% | G42–G49, G-CT1..3, G-CTV1 (12) |
| Wasted Spend / Negatives | 20% | G13–G19, G-WS1 (8) |
| Account Structure | 15% | G01–G12 (12) |
| Keywords & Quality Score | 15% | G20–G25, G-KW1..2 (8) |
| Ads & Assets | 15% | G26–G35, G-AD1..2 (12) + PMax (6) + AI/DG (4) |
| Settings & Targeting | 10% | G50–G61 (12) |

Bidding & Budget (G36–G41) é pontuado dentro de Settings & Targeting; PMax
(G-PM1..6) e AI Max/Demand Gen (G-AI1, G-DG1..3) dentro de Ads & Assets.

### 2.3 O algoritmo (Health Score)

```
S_total = Σ(C_pass × W_sev × W_cat) / Σ(C_total × W_sev × W_cat) × 100
```
PASS=1, WARNING=0.5, FAIL=0, N/A=excluído. W_sev: Critical 5.0, High 3.0, Medium
1.5, Low 0.5. Detalhe completo + exemplo em `agents/google-ads-expert/scoring/health-score.md`.

### 2.4 Sequência ideal da auditoria

1. **Context Intake** — indústria, budget, objetivo, conta/plataformas.
2. **Coleta de dados** — GAQL ao vivo via Maton (ou exports). Ordem: estrutura →
   keywords/search terms → ads/assets → conversões → settings → bidding/budget.
3. **Rodar checks** por categoria; marcar N/A o que faltar dado (G-SYS1).
4. **Pontuar** cada categoria e computar o score agregado.
5. **Priorizar** findings (severity × impacto) e extrair Quick Wins.
6. **Sintetizar** o relatório + plano de ação com owner e ETA por item.

O `/ads audit` original faz isto em paralelo com 6 sub-agentes; na adaptação
OpenClaw (agente único) as categorias são cobertas sequencialmente por playbooks.

### 2.5 Os 80 checks do Google (resumo por categoria)

- **Conversion Tracking (25%):** conversion actions definidas (G42), Enhanced
  Conversions (G43), server-side (G44), Consent Mode V2 (G45), janela de conversão
  (G46), micro vs macro como Primary (G47), DDA (G48), value assignment (G49),
  sem duplo-contagem GA4/nativo (G-CT1), GA4 linkado/fluindo (G-CT2), tag firing
  (G-CT3), limitação de Floodlight em CTV (G-CTV1).
- **Wasted Spend (20%):** recência de search terms ≤14d (G13), listas de negativas
  temáticas (G14), negativas em nível de conta (G15), <5% de spend em termos
  irrelevantes (G16), Broad+Manual CPC (G17, cuidado com legacy BMM), close variant
  pollution (G18), visibilidade de search terms (G19), keywords com >100 cliques e
  0 conv (G-WS1).
- **Account Structure (15%):** naming (G01/G02), ad groups single-theme ≤10 kw
  (G03), ≤5 campanhas por objetivo (G04), brand vs non-brand separados (G05), PMax
  presente (G06), overlap Search+PMax com brand exclusions (G07), budget alinhado à
  prioridade (G08/G09), ad schedule (G10), geo "People in" (G11), network settings
  (G12).
- **Keywords & QS (15%):** QS médio ponderado ≥7 (G20), <10% com QS≤3 (G21),
  Expected CTR (G22), Ad Relevance (G23), Landing Page Exp (G24), top keywords QS≥7
  (G25), zero-impression (G-KW1), keyword-to-ad relevance (G-KW2).
- **Ads & Assets (15%):** RSA por ad group (G26), ≥8 headlines (G27), ≥3 descriptions
  (G28), Ad Strength Good/Excellent (G29), pinning estratégico (G30), densidade de
  PMax assets (G31), vídeo nativo em 3 formatos (G32), ≥2 asset groups (G33), URL
  expansion intencional (G34), copy relevante a keywords (G35), ad freshness ≤90d
  (G-AD1), CTR vs benchmark (G-AD2). PMax: audience signals (G-PM1), Ad Strength
  (G-PM2), brand cannibalization <15% (G-PM3), search themes (G-PM4), negativas
  (G-PM5/G-PM6). IA: AI Max avaliado (G-AI1), Demand Gen multi-formato (G-DG1),
  migração VAC→DG (G-DG2), perda de frequency cap pós-migração (G-DG3).
- **Settings & Targeting (10%):** sitelinks (G50), callouts (G51), structured
  snippets (G52), image ext (G53), call ext c/ tracking (G54), lead form (G55),
  audience segments em Observation (G56), Customer Match <30d (G57), placement
  exclusions (G58), mobile LCP <2.5s (G59), landing relevance (G60), schema (G61).
- **Bidding & Budget (dentro de Settings):** Smart Bidding ativo ≥15 conv (G36),
  target reasonableness ±20% (G37), learning phase <25% (G38), budget-constrained
  (G39), Manual CPC justificado (G40), portfolios (G41).

### 2.6 Contexto de plataforma 2026 (o que mudou)

ECPC removido (mar/2025) → migrar para tCPA/tROAS/Max Conversions. Call Campaigns
descontinuadas (fev/2026, servem até fev/2027). VAC→Demand Gen (abr/2026). AI Max
for Search (+14% conv médio, exige negativas fortes). Power Pack = PMax + Demand
Gen + AI Max. Consent Mode V2 Advanced (enforcement jul/2025 EEA/UK; recupera
15–25% das conversões). DDA como default (modelos rule-based foram auto-migrados).

---

## Capítulo 3 — Framework de Gestão

O claude-ads não tem uma camada de gestão contínua explícita — é a maior expansão
desta implementação. O framework de gestão do GoogleAdsExpert:

### 3.1 Rotina semanal (cadência de gestor)

Toda segunda-feira, por conta: pacing review → detecção de anomalias → checagem de
learning phase → oportunidades de escala → o que pausar → o que escalar ao humano.
Detalhe em `playbooks/weekly-management.md`.

### 3.2 Budget pacing

Comparar spend vs plano em horizontes diário/semanal/mensal:
- **Underpacing:** projeção de fim de mês < 85% do budget → há verba parada.
- **Overpacing:** ritmo de burn esgotaria o mês antes do dia 25 → risco de apagar.
- Realocar de campanhas budget-limited de baixo retorno para top performers
  "Eligible" (G08/G09/G39).

### 3.3 Detecção de anomalias

- CPC/CPM **+30% em 1 dia**; queda de CVR abaixo do range histórico; burn de 50%
  do budget diário nas primeiras 2h; CTR sobe mas conversões não (sinal de tracking
  ou qualidade); erros de tracking.
- **Ação por criticidade:** falha de tracking / cost spike extremo → propor ação
  imediata (pausa/ajuste) com confirmação; issues menores → alerta/recomendação.

### 3.4 Perguntas de gestor

O agente deve responder, com dado ao vivo + raciocínio: "onde investir os próximos
R$10k?", "qual campanha pausar hoje?", "por que meu CPA subiu?", "quais campanhas
escalam bem?", "risco de +30% de budget?", "que experimentos rodar?". Cada resposta
carrega número, ação, owner e plano de medição.

### 3.5 Human-in-the-loop

Mudanças estruturais grandes e realocações agressivas de budget **sempre** passam
por confirmação humana. O agente propõe; o humano decide. Ganhos vêm de **muitos
ajustes pequenos e consistentes**, não de pivôs dramáticos.

---

## Capítulo 4 — Framework de Otimização

### 4.1 Sequência de otimização (ordem de impacto)

`tracking → wasted spend → estrutura → bidding → creative`. Nunca otimizar bidding
ou criativo sobre tracking quebrado — o algoritmo estaria aprendendo com sinal ruim.

### 4.2 Priorização

`prioridade = severity × impacto_estimado`. Quick Wins (Critical/High com fix
<15min) primeiro, pois destravam valor imediato. Depois High por prazo de 7 dias,
Medium 30 dias, Low backlog.

### 4.3 3x Kill Rule

Se CPA > 3× o target **e** já houve tentativas de otimização, aceitar que a
campanha/ad group está morto e pausar (princípio ACCEPT). Não ficar "ajustando"
indefinidamente.

### 4.4 Learning phase

Nunca editar campanha em learning/learning-limited ativa — cada edição
significativa reinicia o aprendizado. Aguardar estabilização (tipicamente ~50 conv
para Smart Bidding sair do learning).

### 4.5 Loop de melhoria (GROW)

Toda ação tem plano de medição. Re-auditar em 30/90 dias, comparar com baseline
(`references/memory.md`). O que não moveu o ponteiro não se repete.

---

## Capítulo 5 — Framework de Relatórios

### 5.1 Três audiências, três relatórios

- **Executivo** (C-level/cliente): Health Score + grade, 3–5 top findings em
  linguagem de negócio (impacto em R$), quick wins, próximos passos. Sem jargão.
- **Técnico** (gestor de tráfego): tabela por categoria, todos os findings com
  ID/severity/evidência/ação, GAQL usado, quick wins detalhados, JSON completo.
- **Roadmap** (30/60/90 dias): findings por prazo, owner e métrica de sucesso, plano
  de re-auditoria.

### 5.2 Anatomia de um finding

`id · severidade · título · impacto estimado · ação · owner · eta_days`. Sempre
com o **porquê** (evidência + princípio). Ver `reports/` para templates.

### 5.3 Schema de saída (JSON)

```json
{ "ads_health_score": 73, "grade": "C", "audit_date": "2026-07-03",
  "platforms": { "google_ads": { "score": 78, "grade": "B", "checks_run": 80, "critical": 2, "high": 5 } },
  "top_findings": [ { "id": "G-AIM-03", "severity": "high", "platform": "google", "title": "...", "impact": "...", "action": "...", "owner": "search", "eta_days": 2 } ],
  "quick_wins": [ "Habilitar Enhanced Conversions (~5 min)" ] }
```

---

## Capítulo 6 — Regras de Decisão

Regras "se X, faça Y" catalogadas do claude-ads (Quality Gates + heurísticas):

| Situação | Decisão |
|---|---|
| Broad match sem Smart Bidding | Nunca recomendar; migrar para Smart Bidding ou Exact |
| BROAD + Manual CPC | É legacy BMM (phrase) — **não** sinalizar como falha |
| CPA > 3× target (pós-tentativas) | 3x Kill Rule → propor pausa |
| Campanha em learning phase ativa | Não editar; aguardar |
| Conta com <15 conv/30d | Manual CPC justificado; não forçar Smart Bidding |
| tCPA/tROAS >50% off do histórico | Flag Critical (G37) |
| Search term >$10 spend e 0 conv | Wasted spend → negativar |
| Keyword >100 cliques e 0 conv | Flag G-WS1 |
| Local business com "People in or interested in" | Trocar para "People in" (G11) |
| Display Network ON em Search | Fail (G12) — desabilitar |
| PMax sem negativas | Adicionar (G-PM5/G-PM6, disponível p/ todos) |
| PMax brand cannibalization >30% | Fail (G-PM3) → brand exclusions |
| VAC ainda ativa | Deprecado (G-DG2) → migrar para Demand Gen |
| ECPC ativa | Migrar imediatamente (removido mar/2025) |
| Tracking quebrado | Gate: corrigir antes de qualquer otimização |
| Special Ad Category (housing/credit/finance) | Checar compliance antes |
| Toda mutação | Confirmação humana explícita antes de aplicar |

---

## Capítulo 7 — Playbooks

Procedimentos passo-a-passo materializados em `agents/google-ads-expert/playbooks/`:

- **account-audit** — auditoria completa + Health Score (playbook principal).
- **campaign-audit / keyword-audit / search-term-audit / pmax-audit** — auditorias focadas.
- **budget-audit / bidding-audit / conversion-audit** — auditorias por eixo.
- **optimization** — ciclo de otimização e priorização.
- **weekly-management** — rotina de gestão contínua (o coração da evolução gestor).

Cada playbook: objetivo · quando usar · dados a buscar (GAQL) · checks · scoring ·
priorização · formato de saída.

---

## Capítulo 8 — Benchmarks

Benchmarks 2026 por indústria (CPC, CTR, CVR, CPA, ROAS) em
`agents/google-ads-expert/knowledge/benchmarks.md`. Regra de ouro: **benchmark é
piso/teto de referência, não meta** — a meta vem da unit economics do cliente
(CAC, LTV:CAC, payback, MER). Severidade é calibrada pelo tamanho da conta: uma
conta de R$500/mês tem prioridades diferentes de uma de R$50k/mês.

Pré-requisitos quantitativos herdados: Smart Bidding ≥15 conv/30d (ideal 30+);
PMax 30–50+ conv/mês; Consent Mode V2 behavioral modeling exige 700+ cliques/dia
por país/domínio ao longo de 7 dias.

---

## Capítulo 9 — Anti-patterns

Do thinking-framework e das notas de acurácia do claude-ads:

- **Diagnosticar de memória** antes de abrir a conta (pular OBSERVE).
- **Aplicar heurística errada de contexto** (ROAS de e-commerce em campanha de
  brand awareness; SKAG em conta pequena).
- **Confiar cegamente na atribuição da plataforma** quando MMP/server-side/plataforma
  divergem 30%+.
- **Recomendar best practice sem checar pré-requisitos** (Smart Bidding sem volume).
- **Otimizar sobre tracking quebrado** (ignorar o gate de privacy infra).
- **Falsos positivos de GAQL**: contar keywords duplicadas por dia; incluir pausados;
  sinalizar legacy BMM como falha; somar visibilidade de subconjunto truncado.
- **Auditorias siloadas** que perdem a alavanca cross-cutting (criativo = targeting
  na era de PMax/AI Max).
- **Recomendações que se contradizem** ("+30% de budget" e "pausar" sem reconhecer o trade-off).
- **Report wall-of-findings** sem owner, sem ETA, sem impacto — análise sem ação.
- **Otimização eterna de campanha morta** (ignorar o 3x Kill Rule).
- **Auditoria one-shot** sem plano de medição nem re-auditoria (pular GROW).
- **Aplicar mutação sem confirmação** (violação do protocolo read/write).

---

## Capítulo 10 — Prompt Strategy

Como o claude-ads estrutura o comportamento do modelo, e como adaptamos:

1. **Orquestrador + RAG.** Um SKILL.md roteia; referências carregam sob demanda —
   nunca tudo de uma vez. Reduz ruído e mantém foco. Adaptado em `SKILL.md`.
2. **Thinking framework como portão de mentalidade.** Não é checklist; é uma
   disciplina cognitiva (OBSERVE×2/LISTEN/THINK/CONNECT×2/FEEL/ACCEPT/CREATE/GROW)
   carregada antes de qualquer deliverable. Em `knowledge/principles.md`.
3. **Context Intake obrigatório.** O prompt força coletar contexto antes de julgar.
4. **Quality Gates como regras duras** no system prompt — invioláveis.
5. **Saída estruturada** (JSON + relatório) com campos fixos — determinismo e
   comparabilidade.
6. **Notas de acurácia inline** por check para evitar falsos positivos — migradas
   para `references/gaql-notes.md`.
7. **Severidade calibrada por contexto**, não absoluta.

Adaptações desta implementação:
- **Persona de gestor permanente** (não auditor pontual) no system prompt.
- **Maton-first**: buscar dado ao vivo por padrão, com fallback para dados colados.
- **Protocolo read/write com confirmação** explícito no prompt.
- **Memória/baseline** para fechar o loop GROW entre auditorias.
- **PT-BR** com termos técnicos em inglês.
- Remoção do branding/comunidade do projeto original (mantida só a atribuição MIT).
</content>
