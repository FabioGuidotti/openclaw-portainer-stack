# Plano de Implementação — GoogleAdsExpert para OpenClaw

> Status: aprovado para execução nesta branch `claude/google-ads-expert-openclaw-97g31u`.
> Base metodológica: [`AgriciDaniel/claude-ads`](https://github.com/AgriciDaniel/claude-ads) (v1.7.1, MIT).
> Camada de execução de dados ao vivo: **Maton** (skill `google-ads-api` já presente no stack).

## 1. Objetivo

Transformar a metodologia de auditoria PPC do `claude-ads` — originalmente um
conjunto de sub-skills/agentes do Claude Code focado em **auditoria pontual** —
em um **agente OpenClaw consultor permanente de Google Ads**, capaz de:

1. **Auditar** contas (Health Score 0–100 + plano de ação priorizado);
2. **Gerenciar** continuamente (gestão semanal, pacing de budget, detecção de anomalias);
3. **Explicar** o raciocínio por trás de cada recomendação (10-Principle Thinking Framework);
4. **Aprender** com auditorias anteriores (memória de baseline + comparação temporal);
5. **Executar** mudanças via Maton **somente após confirmação explícita** do usuário.

### Decisões de escopo (confirmadas com o usuário)

| Dimensão | Decisão |
|---|---|
| Autonomia | **Read + write com confirmação** — lê ao vivo via Maton/GAQL, recomenda, e só executa mutações após "confirmo" explícito |
| Plataformas | **Google Ads em profundidade** + frameworks cross-platform reutilizáveis (scoring, thinking framework, financeiro) |
| Idioma | **PT-BR** com termos técnicos em inglês (Quality Score, PMax, bid, ROAS, learning phase…) |
| Entrega | **Fase 1 (extração) + Fase 2 (construção) juntas** nesta branch |

## 2. Restrição técnica que molda o design

Os MCP/APIs de Google Ads (incluindo o padrão usado pelo Maton) são majoritariamente
**read-only via GAQL**: leem campanhas, ad groups, keywords, budgets, conversões e
change history, mas escrita (pausar, ajustar bid/budget, negativas) pode não estar
disponível ou exigir escopo OAuth de escrita. Por isso o agente é desenhado como
**read-first**: toda mutação é (a) proposta com o comando/mutação exato, (b) gated
atrás de confirmação humana, (c) registrada na memória. Se o Maton não expuser
escrita, o agente degrada graciosamente para "gera o passo-a-passo para o humano executar".

## 3. Arquitetura no OpenClaw

O `claude-ads` usa o modelo skill+agents do Claude Code. O OpenClaw tem modelo
equivalente: **skill** (`SKILL.md` + `references/` injetados no system prompt sob demanda)
e **agent** (`agent.md`/system prompt + entrada em `agents.list`). Mapeamento:

| claude-ads | GoogleAdsExpert (OpenClaw) |
|---|---|
| `ads/SKILL.md` (orquestrador) | `SKILL.md` (roteador de playbooks + carga on-demand de knowledge) |
| `ads/references/*.md` (26 refs RAG) | `knowledge/`, `playbooks/`, `scoring/`, `reports/`, `references/` |
| 6 agentes de auditoria paralelos | Playbooks executados sequencialmente por 1 agente (adaptação p/ agente único) |
| Dados colados / MCP opcional | **Maton primeiro** (dados ao vivo via GAQL), colar como fallback |
| system prompt implícito | `system-prompt.md` (identidade de consultor permanente) |

### Estrutura de arquivos entregue

```
agents/google-ads-expert/
├── agent.yaml            # descritor OpenClaw (id, name, model, skills)
├── system-prompt.md      # identidade do consultor (→ agent.md / prompt)
├── SKILL.md              # entrypoint da skill: frontmatter + roteamento
├── knowledge/            # 10 arquivos de conhecimento (RAG)
├── playbooks/            # 10 playbooks executáveis
├── reports/              # 3 templates de relatório
├── scoring/health-score.md   # algoritmo do Health Score
├── references/
│   ├── gaql-library.md   # query GAQL por check (motor de dados ao vivo)
│   ├── gaql-notes.md     # incompatibilidades/dedup/escopo de filtro
│   ├── maton-integration.md  # como usar Maton; protocolo read/write
│   └── memory.md         # convenção de aprendizado (baseline + histórico)
├── deploy/deploy-google-ads-expert.sh   # sync p/ container
└── README.md

docs/
├── IMPLEMENTATION-PLAN.md               # este documento (passo 3)
└── claude-ads-knowledge-extraction.md   # Fase 1 — fonte da verdade (10 capítulos)
```

### Integração no stack

- `docker-compose.yml`: registrar o agente em `agents.list`, habilitar a skill
  `google-ads-expert` em `skills.entries`, e sincronizar os arquivos para o volume
  `/home/node/.openclaw/skills` na inicialização.
- `DEPLOY-GUIDE.md`: nova seção de deploy do agente.

## 4. Fase 1 — Engenharia reversa (fonte da verdade)

Documento `docs/claude-ads-knowledge-extraction.md` com 10 capítulos:
Filosofia · Framework de Auditoria · Framework de Gestão · Framework de Otimização ·
Framework de Relatórios · Regras de Decisão · Playbooks · Benchmarks · Anti-patterns ·
Prompt Strategy.

## 5. Fase 2 — Construção

Materializar a metodologia nos arquivos do agente (knowledge/playbooks/scoring/reports/
references), no system prompt de consultor, e na cola de integração OpenClaw + Maton.

## 6. Melhorias sobre o claude-ads (o "melhor")

1. **Consultor contínuo**, não só auditor: playbook `weekly-management.md`, pacing de
   budget, detecção de anomalias (CPC +30%, burn de budget, queda de CVR).
2. **Dados ao vivo por padrão** via Maton/GAQL (`gaql-library.md` mapeia check→query).
3. **Memória**: baseline de auditorias + comparação temporal (princípio GROW).
4. **Execução com confirmação**: fecha o loop recomendar→executar com segurança.
5. **Raciocínio explicável**: toda recomendação carrega o "porquê" via thinking framework.

## 7. Verificação

- Consistência de IDs de check (G01–G61 + hifenizados) entre knowledge, playbooks e gaql-library.
- Validação de `docker-compose.yml` (config Node parse) e do script de deploy.
- Coerência do algoritmo de scoring (pesos somam 100% por categoria).
</content>
</invoke>
