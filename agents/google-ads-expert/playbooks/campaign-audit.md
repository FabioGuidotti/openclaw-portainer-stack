# Playbook: Auditoria de Campanha & Estrutura (G01-G12)

**Quando usar:** o cliente quer revisar a estrutura de uma conta/campanha específica — naming,
organização de ad groups, separação brand vs non-brand, alocação de budget, settings de geo/network,
ad schedule. Cobre a categoria **Account Structure (peso 15%)**. Não cobre keywords, search terms nem
PMax em profundidade (ver playbooks dedicados).

---

## 0. Context Intake (primeiro)

Confirme os 4 itens do Context Intake (indústria, budget mensal, objetivo primário, plataformas +
`customer_id`). Estrutura ideal depende do objetivo: E-commerce → Shopping/PMax + Search non-brand;
Local Service → geo apertado + call assets; B2B → funil segmentado, CPA alto tolerado.

Anote se a conta é multi-location: ao contar objetivos (G04), **remova identificadores geográficos**
(cidades, estados, "North"/"South", CEP) dos nomes de campanha antes de contar objetivos únicos.

---

## 1. Coleta de dados (Maton / GAQL)

Filtrar `campaign.status = 'ENABLED'` (nunca `!= 'REMOVED'`).

```sql
SELECT campaign.id, campaign.name, campaign.advertising_channel_type,
       campaign.advertising_channel_sub_type, campaign.bidding_strategy_type,
       campaign_budget.amount_micros, campaign.budget_id,
       campaign.network_settings.target_search_network,
       campaign.network_settings.target_search_partners,
       campaign.network_settings.target_content_network,
       campaign.geo_target_type_setting.positive_geo_target_type,
       campaign.start_date
FROM campaign
WHERE campaign.status = 'ENABLED'
```

Budget vs spend (para G08/G09):
```sql
SELECT campaign.id, campaign.name, campaign_budget.amount_micros,
       metrics.cost_micros, metrics.conversions, metrics.cost_per_conversion,
       campaign_budget.has_recommended_budget, metrics.search_budget_lost_impression_share
FROM campaign
WHERE campaign.status = 'ENABLED' AND segments.date DURING LAST_30_DAYS
```

Ad groups (para G02/G03 naming e single-theme):
```sql
SELECT ad_group.id, ad_group.name, campaign.id, campaign.name, ad_group.status
FROM ad_group
WHERE campaign.status = 'ENABLED' AND ad_group.status = 'ENABLED'
```

Ad schedule (G10):
```sql
SELECT campaign.id, campaign_criterion.ad_schedule.day_of_week,
       campaign_criterion.ad_schedule.start_hour, campaign_criterion.ad_schedule.end_hour
FROM campaign_criterion
WHERE campaign_criterion.type = 'AD_SCHEDULE' AND campaign.status = 'ENABLED'
```

Para G05/G07 (brand): derive tokens de brand do nome do negócio e **escaneie o texto real das keywords**
(não confie só no nome da campanha). Campanha com >50% de keywords de brand = brand campaign.

---

## 2. Checks (G01-G12)

| ID | Check | Severity | PASS | WARNING | FAIL |
|----|-------|----------|------|---------|------|
| G01 | Naming de campanha | Medium | Padrão consistente `[Brand]_[Type]_[Geo]_[Target]` | Parcial | Sem convenção |
| G02 | Naming de ad group | Medium | Segue padrão da campanha | Parcial | Sem convenção |
| G03 | Single-theme ad groups | High | 1 tema por ad group (≤10 kw) | 11-20 kw, tema consistente | 20+ kw não relacionadas (theme drift) |
| G04 | Nº campanhas por objetivo | High | ≤5 por funil/objetivo | 6-8 | >8 (fragmentado) |
| G05 | Brand vs non-brand | Critical | Separados em campanhas distintas | N/A | Misturados na mesma campanha |
| G06 | PMax presente (se elegível) | Medium | PMax ativo com histórico de conv | Testado mas pausado | Não testado apesar de elegível |
| G07 | Overlap Search + PMax | High | Brand exclusions no PMax quando há Search de brand | Exclusões parciais | Sem brand exclusions |
| G08 | Budget alinhado à prioridade | High | Top performers não limitados por budget | Restrição leve | Top performers severamente limitados |
| G09 | Budget diário vs spend | Medium | Nenhuma campanha bate cap antes das 18h | 1-2 batem cap cedo | Várias capped antes do meio-dia |
| G10 | Ad schedule configurado | Low | Schedule setado se há horário comercial | N/A | Sem schedule apesar de horário claro |
| G11 | Geo targeting accuracy | High | "People in" (não "in or interested in") p/ local | N/A | "in or interested in" p/ negócio local |
| G12 | Network settings | High | Search Partners ON; Display OFF em Search | Search Partners OFF (reach perdido) | Display Network ON em Search |

### Notas de precisão (evitar falso-positivo)
- **G03**: só conte keywords com impressions > 0; dedup por texto (BROAD+PHRASE = 1 keyword); exclua ad
  groups pausados; ignore stopwords isoladas ("advogado", "lawyers") na coerência temática.
- **G04**: multi-location → tire o geo do nome antes de contar objetivos únicos. "Divórcio - SP",
  "Divórcio - Campinas" = 1 objetivo em 2 geos, não 2 objetivos.
- **G05/G07**: classifique por composição de keywords, não só pelo naming (pega campanhas mal rotuladas).
- **G12**: Search Partners OFF é **Warning** (oportunidade perdida), não Fail. Display ON em Search é **Fail**.

---

## 3. Quality Gates aplicáveis

- **3x Kill Rule**: se qualquer campanha/ad group tem CPA > 3x target → recomendar pausa (kill list).
- **Nunca** Broad Match sem Smart Bidding — se G05/estrutura sugere reorganizar match types, cheque
  a bidding strategy antes.
- **Learning phase**: se `campaign.bidding_strategy_type` mudou <7 dias ou está em aprendizado,
  **não** recomendar edições estruturais que resetem o aprendizado.
- **Special Ad Categories**: se housing/employment/credit/finance, restrições de geo/targeting mudam — cheque.

---

## 4. Scoring (categoria isolada)

```
Score_estrutura = Σ(C_pass × W_sev) / Σ(C_total × W_sev) × 100
```
C_pass: PASS=1, WARNING=0.5, FAIL=0, N/A=excluído. W_sev: Critical=5.0, High=3.0, Medium=1.5, Low=0.5.
(No audit completo, esta categoria entra com W_cat=15%.)

Grades: A 90-100 · B 75-89 · C 60-74 · D 40-59 · F <40.

---

## 5. Saída

```json
{
  "category": "account_structure",
  "score": 72.0,
  "grade": "C",
  "findings": [
    {"id": "G05", "result": "FAIL", "severity": "Critical",
     "detail": "Campanha 'Search-Geral' tem 61% keywords de brand misturadas com non-brand",
     "action": "Split: mover brand para campanha dedicada com budget e tCPA próprios",
     "owner": "media_buyer", "eta_days": 1, "quick_win": true},
    {"id": "G12", "result": "FAIL", "severity": "High",
     "detail": "Display Network ON em 3 campanhas de Search",
     "action": "Desabilitar Display Network nas 3 campanhas", "owner": "media_buyer",
     "eta_days": 1, "quick_win": true},
    {"id": "G03", "result": "WARNING", "severity": "High",
     "detail": "2 ad groups com 14-18 keywords de temas mistos", "action": "Segmentar por tema",
     "owner": "media_buyer", "eta_days": 5, "quick_win": false}
  ],
  "quick_wins": ["G05", "G12"],
  "kill_list": []
}
```

Feche com 1 parágrafo: nota da estrutura, o problema estrutural mais caro, e a reorganização recomendada
(ordem: Quick Wins → splits estruturais → naming). Sem branding/footer.
