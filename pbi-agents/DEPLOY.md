# DEPLOY — PBI Agents para OpenClaw

> Guia passo-a-passo para deploy dos agentes PBI no stack OpenClaw via Portainer.

---

## Pré-requisitos

- [ ] Stack OpenClaw rodando no Portainer (`openclaw-gw-1` + `openclaw-cli-1`)
- [ ] Repo `clawbot-fabio` commitado e atualizado no servidor
- [ ] Variáveis de ambiente configuradas no Portainer:

| Variável | Descrição |
|---|---|
| `OPENCLAW_IMAGE` | `fabioguidotti/openclaw:latest` |
| `TOKEN_1` | Token do gateway |
| `MOONSHOT_API_KEY` | API key Moonshot (Kimi K2.5) |
| `DISCORD_BOT_TOKEN` | Token do bot Discord |
| `NOTION_API_KEY` | Token API Notion (opcional) |
| `NOTION_DATABASE_ID` | ID do database Notion (opcional) |
| `TAILSCALE_IP` | IP Tailscale do host |

---

## Passo 1: Preparar os Arquivos no Servidor

Os arquivos PBI já existem no repo. Certifique-se que estão no host:

```bash
# No servidor (via SSH)
cd /caminho/para/clawbot-fabio
git pull origin main
```

Verificar que a pasta existe:
```bash
ls stack-portainer/pbi-agents/
# Deve mostrar: README.md  GLOBAL_PROTOCOLS.md  _shared/  supervisor/  data-profiler/  ...
```

---

## Passo 2: Redeploy da Stack no Portainer

1. Abrir **Portainer** → **Stacks** → **openclaw**
2. Clicar em **Editor** (ou Web editor)
3. O conteúdo de `portainer-stack.yml` já inclui:
   - Volume mount: `./pbi-agents:/home/node/.openclaw/workspace/pbi-agents`
   - 8 agentes PBI registrados em `agents.list[]`
4. Clicar **Update the stack** → **Deploy**
5. Aguardar os containers reiniciarem

---

## Passo 3: Verificar que os Agentes Foram Registrados

### Via Control UI (browser)

1. Acesse `http://<TAILSCALE_IP>:18789`
2. Faça login com o token do gateway
3. Na interface, você deve ver os agentes listados:
   - Main, Mission Control
   - PBI Supervisor, PBI Data Profiler, PBI Model Architect, etc.

### Via CLI (container)

```bash
# Entrar no container CLI
docker exec -it openclaw-cli-1 /bin/sh

# Verificar agentes registrados
cat /home/node/.openclaw/openclaw.json | node -e "
  const c=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
  console.log('Agentes registrados:');
  (c.agents?.list||[]).forEach(a => console.log('  -', a.id, '→', a.workspace));
"
```

Resultado esperado:
```
Agentes registrados:
  - main → /home/node/.openclaw/workspace
  - manager → /home/node/.openclaw/workspace/task-agentes
  - pbi-supervisor → /home/node/.openclaw/workspace/pbi-agents/supervisor
  - pbi-data-profiler → /home/node/.openclaw/workspace/pbi-agents/data-profiler
  - pbi-model-architect → /home/node/.openclaw/workspace/pbi-agents/model-architect
  - pbi-dax-specialist → /home/node/.openclaw/workspace/pbi-agents/dax-specialist
  - pbi-visual-designer → /home/node/.openclaw/workspace/pbi-agents/visual-designer
  - pbi-builder → /home/node/.openclaw/workspace/pbi-agents/builder
  - pbi-knowledge-curator → /home/node/.openclaw/workspace/pbi-agents/knowledge-curator
  - pbi-research-agent → /home/node/.openclaw/workspace/pbi-agents/research-agent
```

---

## Passo 4: Verificar Workspaces dos Agentes

Ainda dentro do container CLI:

```bash
# Verificar que SOUL.md existe em cada workspace
for agent in supervisor data-profiler model-architect dax-specialist visual-designer builder knowledge-curator research-agent; do
  echo "--- $agent ---"
  ls /home/node/.openclaw/workspace/pbi-agents/$agent/
done
```

Cada workspace deve conter: `SOUL.md`, `AGENTS.md`, `HEARTBEAT.md`

---

## Passo 5: Testar o Supervisor

### Teste 1 — Mensagem direta ao Supervisor

No Control UI ou via Discord, envie uma mensagem direcionada ao agente `pbi-supervisor`:

```
Olá Supervisor! Liste seu time de agentes e suas especialidades.
```

O Supervisor deve responder com a lista de agentes do `SOUL.md`.

### Teste 2 — Delegação (quando estiver estável)

```
Supervisor: preciso de um relatório Power BI para dados de vendas.
Primeiro passo: profile dos dados de vendas.
```

O Supervisor deve usar `sessions_send` para delegação ao `pbi-data-profiler`.

---

## Passo 6: Verificar Heartbeats

Os heartbeats estão configurados mas com `target: "none"` (não enviam para nenhum canal). Para ativar:

1. Altere `target` de `"none"` para `"discord"` (ou outro canal) no `portainer-stack.yml`
2. Redeploy a stack

Heartbeats configurados:
| Agente | Intervalo |
|---|---|
| Supervisor | 15 min |
| Especialistas (6) | 30 min |
| Knowledge Curator | 60 min |

---

## Troubleshooting

### Agentes não aparecem no UI

```bash
# Verificar se o config foi aplicado corretamente
docker logs openclaw-gw-1 | grep "Configuração aplicada"

# Verificar o JSON diretamente
docker exec openclaw-cli-1 cat /home/node/.openclaw/openclaw.json | python3 -m json.tool
```

### Workspace vazio

```bash
# Verificar que o volume foi montado
docker exec openclaw-gw-1 ls -la /home/node/.openclaw/workspace/pbi-agents/

# Se estiver vazio, verificar o mount no docker-compose
docker inspect openclaw-gw-1 | grep -A5 pbi-agents
```

### SOUL.md não carregado

O OpenClaw auto-injeta `SOUL.md` e `AGENTS.md` da **raiz do workspace** do agente. Certifique-se que:
- O workspace no `agents.list[]` aponta para o diretório correto
- Os arquivos existem na raiz desse diretório (não em subpasta)

---

## Ordem de Estabilização

> [!IMPORTANT]
> Não tente ativar todos os agentes de uma vez. Siga esta ordem:

1. **Supervisor** — garantir que responde e entende seu papel
2. **DataProfiler** — testar delegação Supervisor → DataProfiler
3. **ModelArchitect** — testar cadeia DataProfiler → ModelArchitect (via Supervisor)
4. **DAXSpecialist** — testar cadeia completa até DAX
5. **VisualDesigner** + **Builder** — completar o pipeline
6. **KnowledgeCurator** + **ResearchAgent** — ativar por último (suporte)

Estabilize cada agente antes de passar ao próximo. Use `_shared/learned/` para registrar problemas encontrados.
