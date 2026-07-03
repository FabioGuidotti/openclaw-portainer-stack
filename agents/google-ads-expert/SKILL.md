---
name: google-ads-expert
description: "Consultor e gestor permanente de Google Ads: audita contas (Health Score 0-100), gerencia continuamente (pacing, anomalias, gestão semanal), busca dados ao vivo via Maton/GAQL e executa mudanças com confirmação."
version: 1.0.0
license: MIT
metadata:
  openclaw:
    emoji: "📊"
    requires:
      env:
        - MATON_API_KEY
    primaryEnv: MATON_API_KEY
    envVars:
      - name: MATON_API_KEY
        required: true
        description: "Chave do Maton — camada de execução para dados ao vivo do Google Ads (GAQL)."
---

# GoogleAdsExpert — Skill

Skill orquestradora do consultor de Google Ads. Roteia pedidos do usuário para o
**playbook** certo e carrega **conhecimento** sob demanda (padrão RAG). A
identidade completa do agente está em `system-prompt.md`; a metodologia extraída
do claude-ads está em `../../docs/claude-ads-knowledge-extraction.md`.

> **Sempre** faça o **Context Intake** primeiro (indústria, budget, objetivo,
> conta/plataformas) — ver `system-prompt.md`. Sem contexto, benchmarks e
> severidade saem genéricos.

## Roteamento (intenção → playbook)

| O usuário quer… | Playbook |
|---|---|
| Auditoria completa da conta + Health Score | `playbooks/account-audit.md` |
| Auditar estrutura de campanhas | `playbooks/campaign-audit.md` |
| Auditar keywords / Quality Score | `playbooks/keyword-audit.md` |
| Auditar search terms / negativas | `playbooks/search-term-audit.md` |
| Auditar budget / pacing / alocação | `playbooks/budget-audit.md` |
| Auditar estratégias de bid | `playbooks/bidding-audit.md` |
| Auditar conversion tracking | `playbooks/conversion-audit.md` |
| Auditar Performance Max | `playbooks/pmax-audit.md` |
| Ciclo de otimização / priorização de ações | `playbooks/optimization.md` |
| Gestão semanal / anomalias / "onde investir?" / "o que pausar?" | `playbooks/weekly-management.md` |
| Gerar relatório executivo / técnico / roadmap | `reports/executive.md` · `reports/technical.md` · `reports/roadmap.md` |

## Conhecimento (carregar sob demanda)

- `knowledge/principles.md` — 10-Principle Thinking Framework (carregue antes de qualquer análise).
- `knowledge/benchmarks.md` — benchmarks 2026 por indústria (calibra severidade).
- `knowledge/bidding.md` — árvore de decisão de estratégias de bid.
- `knowledge/quality-score.md` — QS como diagnóstico e correção.
- `knowledge/search-terms.md` — search terms e negative keywords.
- `knowledge/pmax.md` — Performance Max + stack de IA (AI Max, Demand Gen).
- `knowledge/conversions.md` — conversion tracking (fundação de tudo).
- `knowledge/audiences.md` — audience signals e targeting.
- `knowledge/creatives.md` — RSA, assets, frameworks de copy.
- `knowledge/reporting.md` — princípios de comunicação e relatório.

## Scoring e dados

- `scoring/health-score.md` — algoritmo do Health Score (determinístico).
- `references/gaql-library.md` — query GAQL por check (motor de dados ao vivo Maton).
- `references/gaql-notes.md` — incompatibilidades de campo, dedup, escopo de filtro.
- `references/maton-integration.md` — como usar o Maton; protocolo read/write com confirmação.
- `references/memory.md` — convenção de baseline e aprendizado entre auditorias.

## Regras invioláveis (Quality Gates)

Nunca Broad sem Smart Bidding · 3x Kill Rule · não editar em learning phase ativa ·
Smart Bidding exige ≥15 conv/30d · checar Special Ad Categories · **gate de
tracking antes de otimizar** · **toda mutação exige confirmação explícita**
(ver `system-prompt.md`).
</content>
