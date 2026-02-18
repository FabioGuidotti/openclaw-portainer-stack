#!/bin/bash
# =============================================================================
# Deploy pbi-agents + stack para VPS via SCP
# =============================================================================
# Uso: bash deploy-pbi-agents.sh
#
# Envia os workspaces dos PBI agents para a VPS e atualiza a stack.
# Os arquivos ficam dentro do volume persistente do workspace,
# assim o OpenClaw encontra SOUL.md, AGENTS.md, HEARTBEAT.md em cada workspace.
# =============================================================================

VPS_USER="root"
VPS_HOST="100.124.187.27"       # IP Tailscale da VPS
VPS_PATH="/data/openclaw-1/workspace/pbi-agents"
STACK_PATH="/data/stacks/openclaw"

LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 Deploying pbi-agents to $VPS_USER@$VPS_HOST..."

# 1. Criar diretórios na VPS
ssh "$VPS_USER@$VPS_HOST" "mkdir -p $VPS_PATH"

# 2. Copiar pbi-agents (todos os workspaces + shared)
echo "📦 Enviando arquivos pbi-agents..."
scp -r "$LOCAL_DIR/pbi-agents/"* "$VPS_USER@$VPS_HOST:$VPS_PATH/"

# 3. Copiar o stack atualizado (docker-compose.yml)
echo "📋 Enviando docker-compose.yml..."
scp "$LOCAL_DIR/docker-compose.yml" "$VPS_USER@$VPS_HOST:$STACK_PATH/docker-compose.yml"

echo ""
echo "✅ Deploy concluído!"
echo ""
echo "📁 Arquivos enviados:"
ssh "$VPS_USER@$VPS_HOST" "find $VPS_PATH -type f | head -60"
echo ""
echo "⚠️  Próximos passos:"
echo "  1. No Portainer, faça 'Update the stack' (ou redeploy)"
echo "  2. Verifique em Agents que os arquivos não estão mais 'Missing'"
echo "  3. Teste o Supervisor: envie uma mensagem para pbi-supervisor"
