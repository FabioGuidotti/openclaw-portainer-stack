# Template de Relatório Técnico — Google Ads

<!-- Metodologia, catálogo de checks (80) e sistema de scoring derivados do claude-ads (MIT). -->

Este é o template do relatório **técnico** — o entregável para o gestor de tráfego que vai executar as correções. Ao contrário do executivo, aqui **tudo é explícito**: score por categoria, todos os findings com ID/severity/resultado/evidência/ação, a query GAQL que alimentou cada check, e os quick wins com passo a passo. É o documento auditável: quem lê consegue reproduzir cada conclusão, contestar cada evidência e executar cada correção sem pedir contexto. Este relatório também carrega o **schema JSON canônico** do resultado da auditoria — a fonte de verdade que alimenta tanto o executivo quanto o roadmap.

---

## Estrutura obrigatória

1. **Cabeçalho** — cliente, data, período, spend, conta/customer ID, fontes de dados (e quais falharam).
2. **Score global + distribuição** — score 0-100, grade, contagem pass/warning/fail.
3. **Score por categoria** — tabela com peso, score e nº de checks por categoria.
4. **Findings detalhados** — todos os checks não-PASS, por categoria, com evidência + GAQL.
5. **Quick wins detalhados** — passo a passo executável.
6. **Diagnóstico de dados (G-SYS1)** — o que não foi possível auditar e por quê.
7. **Schema JSON** — resultado estruturado da auditoria.

---

## Sistema de scoring (referência)

Fórmula ponderada por severidade e categoria:

```
S_total = Σ(C_pass × W_sev × W_cat) / Σ(C_total × W_sev × W_cat) × 100
```

- `C_pass`: PASS=1, WARNING=0.5, FAIL=0. N/A é excluído do total possível.
- `W_sev` (multiplicador de severidade): Critical=5.0, High=3.0, Medium=1.5, Low=0.5.
- `W_cat` (peso da categoria no Google, soma 100%):

| Categoria | Peso | Checks |
|-----------|------|--------|
| Conversion Tracking | 25% | 12 (G42-G49, G-CT1..3, G-CTV1) |
| Wasted Spend / Negatives | 20% | 8 (G13-G19, G-WS1) |
| Account Structure | 15% | 12 (G01-G12) |
| Keywords & Quality Score | 15% | 8 (G20-G25, G-KW1, G-KW2) |
| Ads & Assets | 15% | 12 + PMax 6 (G-PM1..6) + AI/DG 4 |
| Settings & Targeting | 10% | 12 (G50-G61); Bidding G36-G41 pontua aqui |

Grades: A 90-100 · B 75-89 · C 60-74 · D 40-59 · F <40.

**Regra de quick win:** `severity ∈ {Critical, High} AND tempo_de_fix < 15 min`. Ordenar por `severity × impacto` DESC.

---

## Tabela de score por categoria (template)

```markdown
| Categoria | Peso | Score | Checks | Pass | Warn | Fail | N/A |
|-----------|------|-------|--------|------|------|------|-----|
| Conversion Tracking      | 25% | {n}/100 | 12 | {} | {} | {} | {} |
| Wasted Spend / Negatives | 20% | {n}/100 |  8 | {} | {} | {} | {} |
| Account Structure        | 15% | {n}/100 | 12 | {} | {} | {} | {} |
| Keywords & Quality Score | 15% | {n}/100 |  8 | {} | {} | {} | {} |
| Ads & Assets             | 15% | {n}/100 | 22 | {} | {} | {} | {} |
| Settings & Targeting     | 10% | {n}/100 | 18 | {} | {} | {} | {} |
| **TOTAL**                |100% | **{SCORE}/100 — {GRADE}** | 80 | {} | {} | {} | {} |
```

---

## Formato de finding detalhado (template)

Cada check que **não** for PASS entra como um bloco. PASS pode ser resumido em contagem, salvo quando o cliente pedir a lista completa.

```markdown
### {ID} — {Título do check}
- **Categoria:** {categoria} · **Severity:** {Critical|High|Medium|Low} · **Resultado:** {PASS|WARNING|FAIL}
- **Evidência:** {dado concreto extraído — nº de campanhas, % de spend, IDs, valores}
- **Impacto:** {tradução em R$/mês ou conversões, quando aplicável}
- **Ação:** {o que fazer, específico e executável}
- **Owner:** {search | pmax | tracking | creative | account}
- **ETA:** {dias}
- **GAQL usado:** ver bloco `{nome-do-bloco}` na biblioteca (`references/gaql-library.md`)
- **Notas de precisão:** {ex.: dedup por ad_group_id+keyword_text+match_type; BROAD+Manual CPC = legacy BMM, não falha}
```

### Exemplo de finding preenchido

```markdown
### G16 — Wasted spend em termos irrelevantes
- **Categoria:** Wasted Spend / Negatives · **Severity:** Critical · **Resultado:** FAIL
- **Evidência:** 22% do spend de busca (R$ 6.412 nos últimos 30d) em termos com
  >R$ 50 e 0 conversões. Top waster: "curso gratuito moda" (R$ 890, 412 cliques,
  0 conv). Ver top 10 na tabela abaixo.
- **Impacto:** ~R$ 6.400/mês de desperdício direto.
- **Ação:** Adicionar negativos exatos para os 10 maiores wasters; criar lista
  temática "grátis/curso" aplicada em nível de conta.
- **Owner:** search · **ETA:** 1 dia
- **GAQL usado:** bloco `wasted-search-terms` (search_term_view, LAST_30_DAYS).
- **Notas de precisão:** só conta como waste termos com >R$ 50 e 0 conv;
  totalVisibleSpend calculado sobre TODOS os termos antes de truncar (G19).
  Status de campanha/ad group filtrado na aplicação (search_term_view não
  aceita campaign.status/ad_group.status).
```

---

## Ordenação e agrupamento dos findings

- Agrupar por **categoria** (na ordem de peso: Tracking → Wasted Spend → Structure → Keywords → Ads/Assets → Settings).
- Dentro da categoria, ordenar por **severity DESC**, depois por **impacto DESC**.
- Findings PASS: consolidar em uma linha "N checks PASS nesta categoria: {IDs}".
- WARNING conta como meio ponto no score — sempre listar, nunca esconder.

---

## Quick wins detalhados (template)

Diferente do executivo (que só cita), aqui vai o passo a passo:

```markdown
### QW1 — {Ação} ({severity}, {tempo})
- **Check origem:** {ID}
- **Ganho estimado:** {R$/mês ou conversões}
- **Passo a passo:**
  1. {navegação exata no painel / API}
  2. ...
- **Como validar:** {o que confere que ficou correto}
```

Quick wins canônicos do Google (do catálogo):

| Check | Fix | Tempo |
|-------|-----|-------|
| G43 | Ativar Enhanced Conversions nas configurações de conversão | 5 min |
| G11 | Trocar targeting para "People in" (não "in or interested in") | 2 min |
| G14 | Criar listas de negativas temáticas iniciais | 10 min |
| G17 | Migrar Broad Match para Smart Bidding ou Exact | 5 min |
| G12 | Desativar Display Network em campanhas de Search | 2 min |
| G05 | Separar keywords de marca em campanha própria | 10 min |
| G50 | Adicionar 4+ sitelinks | 10 min |
| G-PM6 | Adicionar negativas em nível de campanha na PMax | 10 min |

---

## Diagnóstico de dados (G-SYS1)

Nunca pule check em silêncio. Reporte:

```markdown
### G-SYS1 — Cobertura de dados
- **Fontes OK:** {ex.: campaign, ad_group_criterion, search_term_view, conversion_action}
- **Fontes com falha:** {fonte} — {mensagem de erro} → checks afetados: {IDs pulados}
- **Checks manuais (fora do GAQL):** G59-G61 (landing page), Consent Mode V2 (auditoria de tag), qualidade criativa subjetiva.
```

---

## Schema JSON do resultado da auditoria

Estrutura canônica retornada pela auditoria. Alimenta os três relatórios (executivo, técnico, roadmap). Baseado no exemplo de saída do `/ads audit`, adaptado para Google standalone.

```json
{
  "ads_health_score": 63,
  "grade": "C",
  "audit_date": "2026-07-03",
  "account": {
    "customer_id": "123-456-7890",
    "client_name": "Loja Aurora",
    "currency": "BRL",
    "monthly_spend": 82000,
    "analysis_window_days": 30
  },
  "platforms": {
    "google_ads": {
      "score": 63,
      "grade": "C",
      "checks_run": 80,
      "critical": 3,
      "high": 6,
      "medium": 4,
      "low": 1,
      "results": { "pass": 61, "warning": 8, "fail": 11, "na": 0 },
      "category_scores": {
        "conversion_tracking":      { "weight": 0.25, "score": 45 },
        "wasted_spend_negatives":   { "weight": 0.20, "score": 52 },
        "account_structure":        { "weight": 0.15, "score": 74 },
        "keywords_quality_score":   { "weight": 0.15, "score": 68 },
        "ads_assets":               { "weight": 0.15, "score": 71 },
        "settings_targeting":       { "weight": 0.10, "score": 66 }
      }
    }
  },
  "top_findings": [
    {
      "id": "G43",
      "severity": "critical",
      "platform": "google",
      "title": "Enhanced Conversions não ativado",
      "impact": "~R$ 9.000/mês em receita não atribuída; decisões de lance com dados incompletos",
      "action": "Ativar Enhanced Conversions e verificar para conversões primárias",
      "owner": "tracking",
      "eta_days": 1,
      "evidence": "0 de 4 conversões primárias com Enhanced Conversions ativo",
      "gaql_block": "conversion-actions",
      "result": "fail"
    },
    {
      "id": "G16",
      "severity": "critical",
      "platform": "google",
      "title": "Wasted spend em termos irrelevantes (22%)",
      "impact": "~R$ 6.400/mês de desperdício direto",
      "action": "Adicionar negativos para top 10 wasters + lista temática de conta",
      "owner": "search",
      "eta_days": 1,
      "evidence": "R$ 6.412 em termos com >R$ 50 e 0 conversões (30d)",
      "gaql_block": "wasted-search-terms",
      "result": "fail"
    },
    {
      "id": "G-PM3",
      "severity": "high",
      "platform": "google",
      "title": "Canibalização de marca na PMax (34%)",
      "impact": "~R$ 3.100/mês de CPA inflado",
      "action": "Configurar brand exclusions na PMax; adicionar negativas de marca",
      "owner": "pmax",
      "eta_days": 3,
      "evidence": "34% das conversões PMax vêm de termos de marca",
      "gaql_block": "pmax-campaigns",
      "result": "fail"
    }
  ],
  "quick_wins": [
    { "id": "G43", "action": "Ativar Enhanced Conversions", "severity": "critical", "eta_minutes": 5, "impact": "recupera ~10% de atribuição" },
    { "id": "G14", "action": "Criar listas de negativas temáticas", "severity": "critical", "eta_minutes": 10, "impact": "corta parte de R$ 6.400/mês" },
    { "id": "G-PM6", "action": "Adicionar negativas em nível de campanha na PMax", "severity": "high", "eta_minutes": 10, "impact": "reduz canibalização" },
    { "id": "G50", "action": "Adicionar 4+ sitelinks nas campanhas sem extensões", "severity": "high", "eta_minutes": 10, "impact": "+CTR sem custo extra" }
  ],
  "data_diagnostics": {
    "sources_ok": ["campaign", "ad_group", "ad_group_criterion", "search_term_view", "conversion_action", "asset_group"],
    "sources_failed": [],
    "manual_checks": ["G59", "G60", "G61", "consent_mode_v2", "creative_subjective"]
  }
}
```

### Notas sobre o schema

- `top_findings[]` é o subconjunto acionável (Critical/High + Medium de alto impacto), não os 80 checks. Campos `id, severity, platform, title, impact, action, owner, eta_days` são obrigatórios; `evidence, gaql_block, result` são recomendados para o relatório técnico.
- `owner` ∈ {search, pmax, tracking, creative, account} — mapeia para responsáveis do time.
- `category_scores` reproduz o denominador ponderado por categoria; a soma ponderada = `ads_health_score`.
- `currency` sempre explícito; todos os valores de impacto seguem essa moeda.
- `result` por finding: `pass | warning | fail | na`. WARNING pontua 0.5.

---

## Checklist de qualidade antes de entregar

- [ ] Todo finding não-PASS tem evidência concreta (número, ID, %), não afirmação genérica.
- [ ] Todo finding referencia o bloco GAQL que o alimentou (rastreabilidade).
- [ ] Notas de precisão do gaql-notes aplicadas: dedup de keyword, legacy BMM não flagado, status filtrado na aplicação para search_term_view.
- [ ] G-SYS1 preenchido: nada foi pulado em silêncio.
- [ ] Score por categoria soma (ponderado) para o score global.
- [ ] Schema JSON válido e coerente com as tabelas do relatório.
- [ ] Checks manuais (G59-61, Consent Mode V2, criativo) marcados como tal.
