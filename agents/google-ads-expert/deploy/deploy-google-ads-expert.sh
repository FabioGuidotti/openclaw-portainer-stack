#!/bin/sh
# =============================================================================
# Deploy do agente/skill GoogleAdsExpert no OpenClaw
# =============================================================================
# Copia a skill google-ads-expert para o diretório de skills do OpenClaw e
# prepara o workspace do agente (memória/histórico). Rode no HOST da VPS a
# partir do repositório clonado, apontando para o diretório .openclaw montado.
#
# Uso:
#   sudo sh agents/google-ads-expert/deploy/deploy-google-ads-expert.sh \
#     --openclaw-dir /data/openclaw-1/.openclaw
#
# Depois: reinicie o container do gateway (Portainer > openclaw-gw-1 > Restart),
# para que o script de config do docker-compose registre o agente e a skill.
# =============================================================================
set -eu

OPENCLAW_DIR="/data/openclaw-1/.openclaw"

# --- parse args -------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --openclaw-dir)
      OPENCLAW_DIR="${2:?--openclaw-dir requer um caminho}"
      shift 2
      ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Argumento desconhecido: $1" >&2
      exit 2
      ;;
  esac
done

# --- resolve o diretório-fonte (esta skill) ---------------------------------
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SKILL_SRC=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)   # .../agents/google-ads-expert

SKILLS_DST="$OPENCLAW_DIR/skills/google-ads-expert"
WORKSPACE_DST="$OPENCLAW_DIR/workspace/google-ads-expert"

echo "==> Fonte da skill : $SKILL_SRC"
echo "==> Destino skill  : $SKILLS_DST"
echo "==> Workspace agent: $WORKSPACE_DST"

if [ ! -f "$SKILL_SRC/SKILL.md" ]; then
  echo "ERRO: SKILL.md não encontrado em $SKILL_SRC" >&2
  exit 1
fi
if [ ! -d "$OPENCLAW_DIR" ]; then
  echo "ERRO: diretório OpenClaw não existe: $OPENCLAW_DIR" >&2
  echo "      (esperado o mesmo caminho montado no container, ex.: /data/openclaw-1/.openclaw)" >&2
  exit 1
fi

# --- copia a skill (exclui deploy/ e o próprio README de repo não é necessário) --
mkdir -p "$SKILLS_DST"
for item in SKILL.md system-prompt.md agent.yaml knowledge playbooks reports scoring references; do
  if [ -e "$SKILL_SRC/$item" ]; then
    cp -R "$SKILL_SRC/$item" "$SKILLS_DST/"
  fi
done

# --- prepara o workspace/memória do agente ----------------------------------
mkdir -p "$WORKSPACE_DST/history" "$WORKSPACE_DST/changes" "$WORKSPACE_DST/baseline"

# system-prompt.md também como agent.md no workspace (identidade do agente)
cp "$SKILL_SRC/system-prompt.md" "$WORKSPACE_DST/agent.md"

# --- permissões (o container roda como usuário 'node', uid 1000 tipicamente) --
if id node >/dev/null 2>&1; then
  chown -R node:node "$SKILLS_DST" "$WORKSPACE_DST" 2>/dev/null || true
else
  chown -R 1000:1000 "$SKILLS_DST" "$WORKSPACE_DST" 2>/dev/null || true
fi

echo ""
echo "OK. Skill e workspace instalados."
echo "Próximo passo: reinicie o container do gateway (openclaw-gw-1) para aplicar a config."
</content>
