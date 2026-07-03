# Memória e Aprendizado (baseline entre auditorias)

O que separa um auditor de um **gestor permanente** é a memória. O GoogleAdsExpert
persiste o resultado de cada auditoria e cada mudança aplicada, e compara o estado
atual com o baseline anterior. Isto materializa o princípio **GROW** do thinking
framework: medir, aprender e ajustar a cada ciclo.

## Onde a memória vive

Workspace dedicado do agente (montado no container — ver `docker-compose.yml`):

```
/home/node/.openclaw/workspace/google-ads-expert/
├── history/
│   └── <customer_id>/
│       ├── 2026-07-03_audit.json     # snapshot de auditoria (score + findings)
│       ├── 2026-07-10_audit.json
│       └── ...
├── changes/
│   └── <customer_id>/
│       └── 2026-07-03_changes.jsonl  # mutações aplicadas (uma por linha)
└── baseline/
    └── <customer_id>.json            # baseline corrente (última auditoria consolidada)
```

Opcionalmente, publique o resumo no **Notion** (skill `notion` está no allowlist
do agente) para o cliente/gestor acompanhar histórico fora do container.

## Schema — snapshot de auditoria (`history/.../*_audit.json`)

```json
{
  "customer_id": "123-456-7890",
  "audit_date": "2026-07-03",
  "industry": "ecommerce",
  "monthly_spend": 42000,
  "ads_health_score": 73,
  "grade": "C",
  "categories": {
    "conversion_tracking": { "score": 68, "critical": 1, "high": 2 },
    "wasted_spend": { "score": 55, "critical": 2, "high": 1 }
  },
  "top_findings": [
    { "id": "G16", "severity": "critical", "title": "...", "impact": "...", "action": "...", "owner": "search", "eta_days": 2 }
  ],
  "quick_wins": ["G43: habilitar Enhanced Conversions (~5 min)"],
  "data_source": "maton",
  "checks_na": ["G59", "G45"]
}
```

## Schema — mudança aplicada (`changes/.../*.jsonl`, uma por linha)

```json
{"ts": "2026-07-03T14:20:00Z", "customer_id": "123-456-7890", "resource": "campaign/123456789", "field": "status", "before": "ENABLED", "after": "PAUSED", "reason": "3x Kill Rule (CPA 3.03x target)", "confirmed_by": "usuario", "related_check": "G-KILL"}
```

## Fluxo de uso

1. **Antes de auditar:** carregue o `baseline/<customer_id>.json` se existir.
2. **Ao concluir a auditoria:** grave um novo snapshot em `history/` e atualize o `baseline/`.
3. **Comparação temporal (delta):** reporte a variação vs baseline:
   - Score: `73 → 81 (+8)`; findings resolvidos vs novos; quick wins ainda abertos.
   - "O que foi recomendado no ciclo anterior e foi feito? Moveu o ponteiro?"
4. **Ao aplicar mudança (com confirmação):** append no `changes/`.
5. **Re-auditoria (princípio GROW):** cadência sugerida 30/90 dias (ou semanal
   para gestão contínua — ver `playbooks/weekly-management.md`). Compare sempre
   contra o baseline, não só o snapshot isolado. Rastreie **trajetória**, não foto.

## Aprender de fato

- Se uma recomendação foi aplicada e **não** moveu a métrica na janela de medição,
  registre isso e **não repita** a mesma receita (princípio ACCEPT). Ajuste a hipótese.
- Carregue adiante o que funcionou: padrões que melhoraram o score desta conta
  viram atalho no próximo ciclo, mas **sempre** revalidados contra o dado atual.
- Mantenha o histórico de mudanças como trilha de auditoria para o cliente.
</content>
