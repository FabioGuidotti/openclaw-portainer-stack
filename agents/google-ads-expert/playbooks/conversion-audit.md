# Playbook: Conversion Audit — Saúde de Tracking

## Quando usar
- **SEMPRE antes de qualquer otimização.** Este é o gate "tracking OK antes de otimizar" (Quality Gate). Se o tracking está quebrado, todo CPA/ROAS/decisão de bid é lixo.
- O gestor pergunta "por que meus números não batem com o GA4/CRM?" ou "estou contando conversão duplicada?".
- Onboarding de conta nova; re-auditoria 30/90d.

Cobre checks **G42-G49, G-CT1/2/3, G-CTV1** (peso de 25% no Health Score — a categoria mais pesada).

---

## Passo 1 — OBSERVE: puxar conversion actions (Maton/GAQL)

```sql
SELECT
  conversion_action.id,
  conversion_action.name,
  conversion_action.status,
  conversion_action.type,
  conversion_action.category,
  conversion_action.origin,
  conversion_action.primary_for_goal,
  conversion_action.counting_type,
  conversion_action.attribution_model_settings.attribution_model,
  conversion_action.value_settings.default_value,
  conversion_action.value_settings.always_use_default_value,
  conversion_action.enhanced_conversions_for_leads_enabled,
  conversion_action.click_through_lookback_window_days
FROM conversion_action
WHERE conversion_action.status = 'ENABLED'
```

Volume real por action (para separar as que importam):

```sql
SELECT
  segments.conversion_action_name,
  segments.conversion_action_category,
  metrics.all_conversions,
  metrics.conversions
FROM customer
WHERE segments.date DURING LAST_30_DAYS
```

> **Regras de precisão**: só avalie actions **ENABLED** para duplicidade (HIDDEN/REMOVED não contam). **Exclua conversões system-managed de Smart Campaign** (ex.: "Smart campaign map clicks to call") — attribution e counting type são travados pelo Google.

Consent Mode / Enhanced Conversions e status do Google Tag em geral não vêm por GAQL — verificar na UI (Conversions > Settings, Diagnostics) ou via GA4/GTM. Registrar como verificação manual.

---

## Passo 2 — Checks e regras (G42-G49, G-CT*)

| Check | Sev | PASS | WARNING | FAIL |
|---|---|---|---|---|
| G42 Actions definidas | Critical | ≥1 conversão primária ativa | — | Nenhuma action ativa |
| G43 Enhanced Conversions | Critical | Ativa E verificada (~10% uplift, grátis) | Ativa não verificada | Não ativada |
| G44 Server-side tracking | High | sGTM ou API import ativo | Planejado, não implantado | Nenhum |
| G45 Consent Mode v2 | Critical | Advanced CMv2 implementado (recupera 15-25%) | Basic mode (perda enorme) | Não implementado |
| G46 Janela de conversão | Medium | Bate com ciclo (7d ecom, 30-90d B2B, 30d lead) | Default 30d sem validar | Descasada do ciclo |
| G47 Micro vs macro | High | Só macro (Purchase/Lead) como Primary | Alguns micro como Primary | Todos (incl. micro) como Primary |
| G48 Modelo de atribuição | Medium | DDA selecionado | Last Click (intencional, documentar) | Rule-based legado ativo |
| G49 Valor de conversão | High | Valores dinâmicos (ecom) / value rules (lead) | Valores estáticos | Sem valores |
| G-CT1 Sem duplicidade | Critical | GA4 + Google Ads não contam a mesma conversão 2x | — | GA4 import E tag nativa contando a mesma action |
| G-CT2 GA4 linkado | High | Property linkada, dados fluindo | Linkado com discrepâncias | Não linkado |
| G-CT3 Google Tag firing | Critical | gtag/GTM disparando em todas as páginas | >90% das páginas | Faltando/quebrado em páginas-chave |
| G-CTV1 CTV Floodlight | High | CTV usa medição não-Floodlight (GA4/Google Ads) | CTV ativo, medição não verificada | CTV dependendo de Floodlight (não captura CTV) |

Health Score: `Σ(C_pass × W_sev × W_cat)/Σ(...) × 100`, PASS=1/WARNING=0.5/FAIL=0. Categoria Conversion Tracking pesa 25%. Severidades: Critical 5.0, High 3.0, Medium 1.5, Low 0.5.

---

## Passo 3 — Enhanced Conversions (G43) — Quick Win

- Envia dados first-party hasheados (SHA-256: email, telefone, endereço, nome).
- ~10% mais conversões medidas; setup grátis em ~5 min via gtag.js ou GTM.
- Essencial para acurácia de Smart Bidding em ambiente cookie-degradado.
- PASS exige **ativado E verificado** (checar verification status em Settings). Ativado-não-verificado = WARNING.

---

## Passo 4 — Consent Mode v2 (G45) — Critical

- Enforcement começou 21/jul/2025 para EEA/UK; recomendado globalmente para signal recovery.
- **Advanced mode** obrigatório (Basic = perda enorme de dados). Advanced + Enhanced Conversions + server-side recupera 30-50% das conversões perdidas.
- Modelagem comportamental ativa exige 700+ ad clicks/dia por 7 dias por país/domínio.
- Sem implementação: quedas de 90-95% nas métricas em EEA/UK. Só ~31% dos usuários aceitam cookies globalmente.

---

## Passo 5 — Micro vs Macro e Duplicidade (G47, G-CT1)

**Micro vs macro (G47)**: só conversões **macro** (Purchase, Lead) devem ser Primary/"para lances". Micro (AddToCart, TimeOnSite, PageView) como Primary faz o Smart Bidding otimizar para o evento errado — infla "conversões" e destrói o CPA real.

**Duplicidade (G-CT1)**: nunca contar a mesma conversão pela tag nativa do Google Ads E pelo import do GA4. Regra: usar tag nativa como PRIMARY para lances (real-time); importar GA4 só para observação. Ao reportar duplicata, incluir para cada action: id, type, origin, category, status, primary/secondary, counting type e attribution model — para resolução direta.

**Atribuição (G48)**: DDA é o default mandatório (set/2025). Só restam DDA e Last Click; todos os rule-based (first-click, linear, time-decay, position-based) foram auto-migrados — qualquer rule-based remanescente é misconfiguração legada = FAIL.

**Value assignment (G49)**: ecom precisa de valores dinâmicos por transação; lead gen usa value rules (ex.: SQL vale mais que MQL). Sem valores → tROAS impossível.

---

## Passo 6 — O GATE de otimização

Antes de liberar `optimization.md`, `bidding-audit.md` ou `budget-audit.md` para agir, o tracking precisa passar o gate mínimo:

```
GATE tracking-OK (todos obrigatórios):
[ ] G42 PASS  — existe conversão primária
[ ] G-CT3 PASS — Google Tag disparando (>90%)
[ ] G-CT1 PASS — sem duplo-contagem
[ ] G47 PASS  — só macro como Primary
[ ] G45 não-FAIL (se serve EEA/UK) — Consent Mode implementado

SE qualquer um FAIL → NÃO otimizar bids/budget.
A recomendação #1 vira "corrigir tracking". CPA/ROAS reportados são não-confiáveis.
```

Este gate é inviolável: otimizar sobre tracking quebrado é o erro mais caro de todos (princípio OBSERVE — puxe os dados reais antes de diagnosticar).

---

## Passo 7 — WRITE com confirmação

A maioria dos fixes de tracking (Consent Mode, Enhanced Conversions, GTM) é feita fora do Google Ads e vira passo-a-passo manual. O que é editável via API (ex.: marcar action como secondary, mudar attribution model, atribuir default value) segue o protocolo:

```
MUTAÇÃO PROPOSTA (aguardando confirmação)
Action: "AddToCart" (id: 987)
Ação: primary_for_goal true → false (rebaixar micro-conversão de Primary)
Motivo: G47 FAIL — micro-conversão inflando lances. Só Purchase deve ser Primary.
Impacto: Smart Bidding volta a otimizar para conversão macro real. CPA reportado vai subir (correção, não piora).
Medição (GROW): comparar conversões macro e CPA real em 14/30d contra baseline.
Confirma?
```

Fixes fora da plataforma: entregar checklist manual (habilitar Enhanced Conversions em Settings, upgrade para Consent Mode Advanced no CMP, corrigir tag em página X).

---

## Formato de saída

```
CONVERSION AUDIT — [conta] — [data]
Score de tracking: XX/100 (peso 25%)
GATE tracking-OK: [PASSA / BLOQUEIA otimização]

FAILS CRÍTICOS:
- G45: Consent Mode ausente, serve EEA → estimativa 90-95% de sub-contagem
- G-CT1: "Purchase" contado por GA4 import E tag nativa → duplo-contagem

MICRO COMO PRIMARY (G47):
- [action]: AddToCart marcada Primary → rebaixar

QUICK WINS:
- G43 Enhanced Conversions: habilitar (5 min, ~10% uplift)

MUTAÇÕES / CHECKLIST MANUAL: [lista]
```
