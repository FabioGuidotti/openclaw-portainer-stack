# GoogleAdsExpert — Agente OpenClaw

Consultor e gestor permanente de **Google Ads** para OpenClaw. Audita contas
(Health Score 0–100 + plano priorizado), gerencia continuamente (pacing,
detecção de anomalias, rotina semanal), explica o raciocínio (10-Principle
Thinking Framework), aprende com auditorias anteriores (baseline/memória) e
executa mudanças via **Maton** somente após confirmação explícita.

Metodologia derivada de [`AgriciDaniel/claude-ads`](https://github.com/AgriciDaniel/claude-ads)
(MIT). A extração conceitual está em [`../../docs/claude-ads-knowledge-extraction.md`](../../docs/claude-ads-knowledge-extraction.md).

## Estrutura

```
google-ads-expert/
├── agent.yaml            # descritor do agente OpenClaw (id/name/model/skills)
├── system-prompt.md      # identidade do consultor (→ agent.md / prompt do agente)
├── SKILL.md              # entrypoint da skill: frontmatter + roteamento de playbooks
├── knowledge/            # 10 arquivos de conhecimento (RAG, carga sob demanda)
├── playbooks/            # 10 playbooks executáveis
├── reports/              # 3 templates de relatório (executive/technical/roadmap)
├── scoring/health-score.md   # algoritmo do Health Score (determinístico)
├── references/
│   ├── gaql-library.md   # query GAQL por check (motor de dados ao vivo via Maton)
│   ├── gaql-notes.md     # incompatibilidades de campo, dedup, escopo de filtro
│   ├── maton-integration.md  # protocolo read/write com confirmação
│   └── memory.md         # baseline + aprendizado entre auditorias
├── deploy/deploy-google-ads-expert.sh
└── README.md
```

## Como mapeia para o OpenClaw

| Conceito OpenClaw | Aqui |
|---|---|
| **Skill** (`SKILL.md` + refs injetadas no prompt sob demanda) | Esta pasta é a skill `google-ads-expert` |
| **Agent** (`agent.md`/prompt + entrada em `agents.list`) | `agent.yaml` + `system-prompt.md` |
| **Skills do agente** (allowlist) | `google-ads-expert`, `google-ads-api` (Maton), `notion` |
| **Workspace** (memória/histórico) | `/home/node/.openclaw/workspace/google-ads-expert` |

## Dependências

- **Maton** (`google-ads-api` skill) — camada de execução de dados ao vivo (GAQL).
  Requer `MATON_API_KEY` no container. **Sem Maton**, o agente opera com dados
  colados/exportados e entrega o passo-a-passo manual para o humano executar.
- **Autonomia:** read livre; **toda mutação exige confirmação explícita** (ver
  `references/maton-integration.md`). Se o Maton não expuser escrita, degrada para
  modo consultor puro.
- **Notion** (opcional) — publicar relatórios/histórico fora do container.

## Deploy

**Método recomendado — auto-install pelo stack (sem SSH):** o `docker-compose.yml`
baixa esta skill do repositório no boot do gateway (via `GAE_REPO`/`GAE_REF`, com
`GITHUB_TOKEN` opcional para repo privado) e registra o agente em `agents.list` +
habilita a skill em `skills.entries`. Basta **mergear o PR na `main`** e **atualizar/
redeployar a stack no Portainer**. Nos logs do gateway: `google-ads-expert: skill instalada`.

**Alternativa — deploy manual via SSH no host:**
```bash
sudo sh agents/google-ads-expert/deploy/deploy-google-ads-expert.sh \
  --openclaw-dir /data/openclaw-1/.openclaw
```

Passo a passo completo (incluindo variáveis e como achar o nome real do container)
na seção **GoogleAdsExpert** do `DEPLOY-GUIDE.md`.

> **Nota de versão do OpenClaw.** Os nomes de campo de `agent.yaml`/`agents.list`
> (ex.: `promptFile`, `skills`, `workspace`) seguem a convenção documentada do
> OpenClaw. Ajuste conforme a versão da sua imagem se a Control UI reportar campo
> desconhecido — a metodologia (knowledge/playbooks/scoring) é independente disso.

## Uso

No canal (Telegram/Discord) ou Control UI, fale com o agente **GoogleAdsExpert**:

- "Audita a conta 123-456-7890" → `playbooks/account-audit.md`
- "Onde invisto os próximos R$ 10.000?" → `playbooks/weekly-management.md`
- "Por que meu CPA subiu?" → `playbooks/weekly-management.md`
- "Revisa os search terms da última semana" → `playbooks/search-term-audit.md`
- "Gera o relatório executivo" → `reports/executive.md`
</content>
