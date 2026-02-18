#!/bin/bash
# =============================================================================
# Deploy task-agentes + stack para VPS via SCP
# =============================================================================
# Uso: bash deploy.sh
# Ajuste VPS_HOST, VPS_USER e VPS_PATH abaixo.
# =============================================================================

VPS_USER="root"
VPS_HOST="100.124.187.27"       # IP Tailscale da VPS
VPS_PATH="/data/openclaw-1/workspace/task-agentes"
STACK_PATH="/data/stacks/openclaw"

LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 Deploying task-agentes to $VPS_USER@$VPS_HOST..."

# 1. Criar diretórios na VPS
ssh "$VPS_USER@$VPS_HOST" "mkdir -p $VPS_PATH $STACK_PATH"

# 2. Copiar task-agentes (skills + prompts)
scp -r "$LOCAL_DIR/task-agentes/"* "$VPS_USER@$VPS_HOST:$VPS_PATH/"

# 3. Copiar o stack
scp "$LOCAL_DIR/portainer-stack.yml" "$VPS_USER@$VPS_HOST:$STACK_PATH/"

echo "✅ Deploy concluído!"
echo ""
echo "Arquivos enviados:"
ssh "$VPS_USER@$VPS_HOST" "find $VPS_PATH -type f && echo '---' && ls -la $STACK_PATH/portainer-stack.yml"
