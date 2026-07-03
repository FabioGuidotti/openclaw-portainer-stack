<!-- Metodologia adaptada de claude-ads (MIT) — ads/references/scoring-system.md -->

# Google Ads Health Score (0–100)

Este arquivo define o algoritmo de pontuação que o GoogleAdsExpert usa para
transformar o resultado de uma auditoria em um número acionável de 0 a 100 e uma
nota (grade). O score é **determinístico**: mesmos inputs → mesmo resultado.

## Algoritmo ponderado

```
                Σ (C_pass × W_sev × W_cat)
S_total = ──────────────────────────────────── × 100
                Σ (C_total × W_sev × W_cat)
```

- `C_pass` — resultado do check: **PASS = 1**, **WARNING = 0.5**, **FAIL = 0**.
- `C_total` — check considerado (1). Checks marcados **N/A são excluídos** do numerador e do denominador (não penalizam nem inflam).
- `W_sev` — multiplicador de severidade do check.
- `W_cat` — peso da categoria à qual o check pertence.

O denominador usa `C_total = 1` para todo check aplicável, de modo que o score
representa "% dos pontos possíveis conquistados", ponderado por severidade e categoria.

## Multiplicadores de severidade (W_sev)

| Severidade | Multiplicador | Critério | Prazo de correção |
|---|---|---|---|
| Critical | **5.0** | Risco imediato de perda de receita/dados | Imediato |
| High | **3.0** | Perda de performance significativa | 7 dias |
| Medium | **1.5** | Oportunidade de otimização | 30 dias |
| Low | **0.5** | Boa prática, impacto menor | Backlog |

## Pontos por resultado do check

| Resultado | Pontos ganhos |
|---|---|
| PASS | 100% de `W_sev × W_cat` |
| WARNING | 50% de `W_sev × W_cat` |
| FAIL | 0 |
| N/A | excluído do total possível |

## Pesos de categoria — Google Ads

Os pesos somam **100%** para permitir comparação direta entre contas. A calibragem
prioriza **conversion tracking** porque tracking quebrado invalida toda decisão de
otimização a jusante.

| Categoria | Peso | Racional |
|---|---|---|
| Conversion Tracking | **25%** | Fundação de toda otimização; Enhanced Conv + Consent Mode V2 + CTV (12 checks) |
| Wasted Spend / Negatives | **20%** | Vazamento direto de dinheiro; search terms, negative lists (8 checks) |
| Account Structure | **15%** | Organização, separação brand/non-brand (12 checks) |
| Keywords & Quality Score | **15%** | QS como diagnóstico; alinhamento keyword-ad (8 checks) |
| Ads & Assets | **15%** | Força de RSA, PMax assets, AI Max, Demand Gen (12+6+4 checks) |
| Settings & Targeting | **10%** | Location, network, audiences, landing pages (12 checks) |

> Performance Max (G-PM1..6) e AI/Demand Gen (G-AI1, G-DG1..3) são pontuados
> **dentro de Ads & Assets**. Os checks cross-platform (X-PI1, X-CD1, X-RF1) são
> pontuados fora das categorias, a 100% de peso no agregado.

## Grades

| Grade | Score | Rótulo | Ação requerida |
|---|---|---|---|
| A | 90–100 | Excelente | Somente otimizações menores |
| B | 75–89 | Bom | Algumas oportunidades de melhoria |
| C | 60–74 | Precisa melhorar | Problemas relevantes a tratar |
| D | 40–59 | Ruim | Problemas significativos |
| F | <40 | Crítico | Intervenção urgente |

Bandas mais largas que notas acadêmicas: a saúde de contas de mídia costuma se
distribuir para baixo, então **75+ já representa uma conta genuinamente bem gerida**.

## Prioridade dos findings

- **Critical** — risco de perda de receita/dados → corrigir imediatamente.
- **High** — perda de performance relevante → corrigir em 7 dias.
- **Medium** — oportunidade de otimização → corrigir em 30 dias.
- **Low** — boa prática, impacto menor → backlog.

## Quick Wins

```
SE severity ∈ {Critical, High} E tempo_de_correção < 15 min
ENTÃO marcar como "Quick Win"
ORDENAR Quick Wins por (severity × impacto_estimado) DESC
```

Exemplos (Google): habilitar Enhanced Conversions (Critical, 5 min · G43);
adicionar negative keyword lists (Critical, 10 min · G14); trocar location
targeting para "People in" (Critical, 2 min · G11); desabilitar Display Network
em campanha de Search (High, 2 min · G12); adicionar negativas em PMax (High,
10 min · G-PM6).

## Score agregado (multi-conta / multi-plataforma)

Quando houver mais de uma conta ou plataforma, pontue cada uma e agregue por
share de budget:

```
Agregado = Σ (Score_plataforma × Share_de_budget_plataforma)

Ex.: Google (82) × 40% + Meta (71) × 35% + LinkedIn (90) × 25%
   = 32.8 + 24.85 + 22.5 = 80.15 → Grade B
```

## Exemplo de cálculo (uma categoria)

Categoria **Wasted Spend / Negatives** (W_cat = 0.20), 3 checks:

| Check | Severidade | W_sev | Resultado | C_pass | Contribuição (C_pass×W_sev×W_cat) | Possível (1×W_sev×W_cat) |
|---|---|---|---|---|---|---|
| G13 | Critical | 5.0 | WARNING | 0.5 | 0.5×5.0×0.20 = 0.50 | 1.00 |
| G16 | Critical | 5.0 | FAIL | 0 | 0 | 1.00 |
| G-WS1 | High | 3.0 | PASS | 1 | 1×3.0×0.20 = 0.60 | 0.60 |

Numerador = 1.10 · Denominador = 2.60 → contribuição desta categoria = 42% dos
pontos possíveis dela. O score final soma numerador e denominador de **todas** as
categorias antes de dividir.

## Determinismo e transparência

- Sempre reportar `checks_run`, contagem de `critical`/`high`, e quais checks
  ficaram **N/A por falta de dado** (nunca pular check em silêncio — ver
  `references/gaql-notes.md`, diagnóstico G-SYS1).
- Mesmos dados de entrada devem sempre produzir o mesmo score.
</content>
