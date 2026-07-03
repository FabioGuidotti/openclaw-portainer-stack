# Playbook: Auditoria de Performance Max (G31-G35, G-PM1..6)

**Quando usar:** a conta roda campanhas Performance Max e o cliente quer auditar densidade de assets,
vídeo, asset groups, canibalização de brand, search themes, negativas e sinais de audience. Os checks
de PMax são pontuados **dentro da categoria Ads & Assets (peso 15%)** do audit completo.

---

## 0. Context Intake (primeiro)

Confirme os 4 itens (indústria, budget, objetivo, plataformas + `customer_id`). PMax precisa de
**30-50+ conversões/mês** para otimizar bem — se o volume é menor, PMax pode não ser adequado e boa
parte dos findings vira "dados insuficientes" (Warning), não falha de configuração. E-commerce com feed
tem checks de asset diferentes de lead gen sem feed.

---

## 1. Coleta de dados (Maton / GAQL)

Campanhas PMax:
```sql
SELECT campaign.id, campaign.name, campaign.bidding_strategy_type,
       campaign.url_expansion_opt_out, campaign_budget.amount_micros
FROM campaign
WHERE campaign.advertising_channel_type = 'PERFORMANCE_MAX'
  AND campaign.status = 'ENABLED'
```
(`campaign.url_expansion_opt_out` = TRUE significa Final URL expansion OFF → G34.)

Asset groups + ad strength (G31/G33/G-PM2):
```sql
SELECT asset_group.id, asset_group.name, asset_group.ad_strength, campaign.id
FROM asset_group
WHERE campaign.status = 'ENABLED' AND asset_group.status = 'ENABLED'
```

Assets por asset group e tipo (G31/G32 — densidade e vídeo):
```sql
SELECT asset_group_asset.asset_group, asset_group_asset.field_type,
       asset.type, asset.id
FROM asset_group_asset
WHERE asset_group_asset.status = 'ENABLED'
```
Conte por `field_type` (MARKETING_IMAGE, LOGO, YOUTUBE_VIDEO, HEADLINE, DESCRIPTION...) e por asset group.

Search themes e sinais de audience (G-PM1/G-PM4):
```sql
SELECT asset_group_signal.asset_group, asset_group_signal.resource_name
FROM asset_group_signal
WHERE asset_group.status = 'ENABLED'
```
> Nota GAQL: em `asset_group_signal` **não** selecione `audience_signal` (UNRECOGNIZED_FIELD) — use
> `resource_name`. Search themes aparecem como signals do tipo search theme; audiences como signals de audience.

Negativas de PMax campaign-level (G-PM5/G-PM6):
```sql
SELECT campaign.id, campaign_criterion.keyword.text, campaign_criterion.negative
FROM campaign_criterion
WHERE campaign_criterion.type = 'KEYWORD' AND campaign_criterion.negative = TRUE
  AND campaign.advertising_channel_type = 'PERFORMANCE_MAX' AND campaign.status = 'ENABLED'
```

Brand cannibalization (G-PM3): não há campo direto. Use o relatório de search terms/insights de PMax
(quando disponível) e classifique conversões por termos de brand. Derive tokens de brand do nome do
negócio e escaneie os termos — não confie só no naming da campanha.

---

## 2. Checks (G31-G35, G-PM1..6, + G-DG/G-AI relacionados)

| ID | Check | Severity | PASS | WARNING | FAIL |
|----|-------|----------|------|---------|------|
| G31 | Densidade de assets do asset group | Critical | ≥20 imagens, ≥5 logos, ≥5 vídeos nativos/grupo | 5-19 img, 1-4 logos ou 1-4 vídeos; OU <30 conv/mês | <5 img OU 0 logo OU 0 vídeo |
| G32 | Vídeo nativo presente | High | Vídeo nativo em todos formatos (16:9, 1:1, 9:16) | 1-2 formatos | Sem vídeo nativo (só auto-gerado) |
| G33 | Nº de asset groups | Medium | ≥2 asset groups (segmentados por intenção) | 1 asset group | N/A |
| G34 | Final URL expansion | High | Configurado intencionalmente (ON p/ discovery, OFF p/ controle) | N/A | ON por default sem revisão |
| G35 | Relevância do copy às keywords | High | Headlines com variantes da keyword primária | Inclusão parcial | Sem relevância nos headlines |
| G-PM1 | Sinais de audience configurados | High | Custom audience signals por asset group | Só sinais genéricos | Sem sinais de audience |
| G-PM2 | PMax Ad Strength | High | "Good" ou "Excellent" | "Average" | "Poor" |
| G-PM3 | Brand cannibalization | High | <15% das conv de PMax vêm de termos de brand | 15-30% | >30% |
| G-PM4 | Search themes | Medium | Search themes configurados (até 50 por asset group) | <5 search themes | Sem search themes |
| G-PM5 | Negative keywords | High | Brand + irrelevantes aplicadas (até 10.000) | Algumas negativas | Sem negativas no PMax |
| G-PM6 | Negativas campaign-level ativas | High | Negativas campaign-level configuradas (disponível p/ todos os anunciantes 2025) | Só account-level, sem campaign-level | Nenhuma negativa apesar de disponível |

Checks correlatos que impactam Ads & Assets:
- **G-DG1** (Demand Gen com vídeo E imagem), **G-DG2** (VAC migradas p/ Demand Gen — Critical, auto-upgrade
  abril/2026), **G-AI1** (AI Max avaliado se >50 conv/mês + listas de negativas robustas). Avalie se a
  conta roda o "Power Pack" (PMax + Demand Gen + AI Max).

### Notas de precisão
- **G31**: se a campanha tem <30 conv/mês, a densidade "ideal" não é atingível de forma útil → marque
  Warning (dados insuficientes), não Fail. Vídeo auto-gerado a partir de imagens = **Warning** (qualidade
  ruim, recomende upload de vídeo nativo).
- **G-PM3**: classifique conversões por termos de brand via tokens derivados do nome do negócio, não pelo
  naming. Se há Search de brand ativo, brand cannibalization alto indica falta de brand exclusions (ligado a G07).
- **G-PM5/G-PM6**: conte negativas account-level E campaign-level. Campaign-level negatives agora estão
  disponíveis para todos os anunciantes de PMax (2025) — sua ausência é oportunidade de Quick Win.

---

## 3. Quality Gates aplicáveis

- **Brand exclusions**: se existe campanha de Search de brand, PMax **deve** ter brand exclusions
  (cruza com G07). Sem isso, PMax canibaliza brand a CPA artificialmente baixo e distorce ROAS.
- **3x Kill Rule**: asset group/campanha PMax com CPA > 3x target → candidato a pausa. Cuidado: PMax é
  black-box; prefira ajustar sinais/negativas antes de pausar se estiver perto do target.
- **Learning phase**: PMax reaprende ao mexer em asset groups/sinais. **Não** recomende reestruturação de
  asset groups em campanha recém-lançada ou em aprendizado ativo.
- **Privacy infra gate**: PMax depende fortemente de sinais de conversão — valide tracking (G-CT1/G43/G45)
  antes de recomendar mudanças de bidding/target no PMax.
- **Special Ad Categories**: housing/employment/credit/finance restringem targeting/sinais no PMax — cheque.

---

## 4. Scoring

Os checks de PMax entram no cálculo da categoria **Ads & Assets** junto com G26-G35 e G-AD1/2:
```
Score_ads = Σ(C_pass × W_sev) / Σ(C_total × W_sev) × 100
```
C_pass: PASS=1, WARNING=0.5, FAIL=0, N/A=excluído. W_sev: Critical=5.0, High=3.0, Medium=1.5, Low=0.5.
No audit completo, Ads & Assets entra com W_cat=15%. Grades: A 90-100 · B 75-89 · C 60-74 · D 40-59 · F <40.

Para relatório standalone de PMax, calcule o score usando apenas os checks de PMax listados acima.

---

## 5. Saída

```json
{
  "category": "pmax",
  "scored_within": "ads_assets",
  "score": 58.0,
  "grade": "D",
  "campaigns": [
    {"id": "998877", "name": "PMax-Ecom", "asset_groups": 1, "ad_strength": "AVERAGE",
     "conv_per_month": 42, "final_url_expansion": "ON", "campaign_negatives": 0}
  ],
  "findings": [
    {"id": "G-PM6", "result": "FAIL", "severity": "High",
     "detail": "Nenhuma negativa campaign-level no PMax apesar de disponível",
     "action": "Adicionar negativas de brand + irrelevantes campaign-level",
     "owner": "media_buyer", "eta_days": 1, "quick_win": true},
    {"id": "G-PM3", "result": "FAIL", "severity": "High",
     "detail": "38% das conversões do PMax vêm de termos de brand (canibalização)",
     "action": "Ativar brand exclusions no PMax (há Search de brand ativo)",
     "owner": "media_buyer", "eta_days": 2, "quick_win": false},
    {"id": "G31", "result": "WARNING", "severity": "Critical",
     "detail": "Asset group com 8 imagens, 2 logos, 1 vídeo auto-gerado",
     "action": "Subir p/ ≥20 imagens, ≥5 logos, upload de vídeo nativo em 3 formatos",
     "owner": "designer", "eta_days": 7, "quick_win": false},
    {"id": "G33", "result": "WARNING", "severity": "Medium",
     "detail": "1 único asset group (sem segmentação por intenção)",
     "action": "Criar ≥2 asset groups segmentados", "owner": "media_buyer",
     "eta_days": 5, "quick_win": false}
  ],
  "quick_wins": ["G-PM6"],
  "kill_list": []
}
```

Feche com 1 parágrafo: nota do PMax, o risco principal (tipicamente brand cannibalization ou densidade de
assets) e a ordem de correção (Quick Win de negativas → brand exclusions → densidade/vídeo → asset groups).
Sem branding/footer.
