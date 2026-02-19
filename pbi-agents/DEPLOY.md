# DEPLOY — PBI Agents para OpenClaw

> Deploy dos workspaces PBI agents no volume persistente da VPS.

---

## Como funciona

O Portainer faz deploy do `docker-compose.yml` via Git, mas **bind mounts relativos (`./`) não funcionam** com Portainer Git-based stacks para pastas de workspace. Por isso, os arquivos de workspace (pbi-agents, task-agentes) vivem no **volume persistente** `/data/openclaw-1/workspace/` e são copiados via SSH.

---

## Deploy (VPS via SSH)

```bash
ssh root@100.124.187.27
```

### Opção A: Copiar do clone do Portainer (recomendado)

O Portainer já clonou o repo no host. Copie os arquivos do clone:

```bash
# Encontrar clone do Portainer
CLONE=$(find /data -path "*/compose/*/pbi-agents" -type d 2>/dev/null | head -1)

if [ -n "$CLONE" ]; then
  echo "Clone encontrado: $CLONE"
  
  # Copiar pbi-agents
  cp -r "$CLONE/"* /data/openclaw-1/workspace/pbi-agents/
  
  # Copiar task-agentes (se necessário)
  TASK=$(dirname "$CLONE")/task-agentes
  [ -d "$TASK" ] && cp -r "$TASK/"* /data/openclaw-1/workspace/task-agentes/
  
  echo "✅ Arquivos copiados"
else
  echo "❌ Clone não encontrado. Use Opção B."
fi

# Corrigir permissões (root → node uid 1000)
chown -R 1000:1000 /data/openclaw-1/workspace/pbi-agents
chown -R 1000:1000 /data/openclaw-1/workspace/task-agentes

# Reiniciar
docker restart openclaw-gw-1
```

### Opção B: Clone manual no host

```bash
cd /tmp
git clone --depth 1 <URL_DO_SEU_REPO> openclaw-stack
cp -r openclaw-stack/pbi-agents/* /data/openclaw-1/workspace/pbi-agents/
cp -r openclaw-stack/task-agentes/* /data/openclaw-1/workspace/task-agentes/
chown -R 1000:1000 /data/openclaw-1/workspace/pbi-agents
chown -R 1000:1000 /data/openclaw-1/workspace/task-agentes
rm -rf /tmp/openclaw-stack
docker restart openclaw-gw-1
```

---

## Verificar

Após restart, no Portainer → Container `openclaw-gw-1` → Console:

```bash
ls -la /home/node/.openclaw/workspace/pbi-agents/supervisor/
# Deve mostrar: SOUL.md  AGENTS.md  HEARTBEAT.md
```

Ou no OpenClaw UI → Agents → PBI Supervisor → Files → todos devem estar ✅

---

## Atualizar arquivos

Quando alterar arquivos no repo Git, repita o deploy:

```bash
ssh root@100.124.187.27

# Pull and redeploy no Portainer (atualiza o clone)
# Depois copiar novamente:
CLONE=$(find /data -path "*/compose/*/pbi-agents" -type d 2>/dev/null | head -1)
cp -r "$CLONE/"* /data/openclaw-1/workspace/pbi-agents/
chown -R 1000:1000 /data/openclaw-1/workspace/pbi-agents
docker restart openclaw-gw-1
```

---

## Ordem de estabilização

1. **Supervisor** → garantir que responde e entende seu papel
2. **DataProfiler** → testar delegação Supervisor → DataProfiler  
3. **ModelArchitect** → testar cadeia via Supervisor
4. **DAXSpecialist** → completar pipeline analítico
5. **VisualDesigner** + **Builder** → pipeline completo
6. **KnowledgeCurator** + **ResearchAgent** → suporte (ativar por último)
