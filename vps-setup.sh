#!/usr/bin/env bash
# =============================================================================
# OpenClaw VPS Setup Script - Executar UMA UNICA VEZ via SSH na VPS Hostinger
# =============================================================================
# Uso: ssh root@SEU_IP_VPS < vps-setup.sh
# Ou:  scp vps-setup.sh root@SEU_IP_VPS:/tmp/ && ssh root@SEU_IP_VPS bash /tmp/vps-setup.sh
# =============================================================================
set -uo pipefail
# Nota: NAO usamos "set -e" pois alguns passos (apt) podem falhar parcialmente
# e o script tem fallbacks para cada caso.

echo "============================================="
echo " OpenClaw VPS Setup - Inicio"
echo "============================================="

# ----- A1. Instalar Tailscale -----
echo ""
echo "==> [A1] Instalando Tailscale..."
if command -v tailscale >/dev/null 2>&1; then
  echo "    Tailscale ja esta instalado."
else
  curl -fsSL https://tailscale.com/install.sh | sh
fi

echo ""
echo "==> [A1] Ativando Tailscale..."
echo "    IMPORTANTE: Siga o link que aparecera para autenticar no navegador."
sudo tailscale up

TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "NAO_DETECTADO")
echo ""
echo "    IP Tailscale da VPS: $TAILSCALE_IP"
echo "    (Anote este IP - sera usado no Portainer)"

# ----- A2. Firewall (4 camadas) -----
echo ""
echo "==> [A2] Configurando Firewall UFW..."

# Corrigir pacotes quebrados antes de instalar
echo "    Atualizando lista de pacotes e corrigindo dependencias..."
sudo apt-get update
sudo dpkg --configure -a 2>/dev/null || true
sudo apt-get -f install -y 2>/dev/null || true

# Instalar UFW (separado para isolar erros)
echo "    Instalando ufw..."
if command -v ufw >/dev/null 2>&1; then
  echo "    UFW ja esta instalado."
else
  sudo apt-get install -y ufw || {
    echo "    AVISO: falha ao instalar ufw via apt. Tentando com --fix-broken..."
    sudo apt-get install -y --fix-broken ufw
  }
fi

# Configurar UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment "SSH"
sudo ufw allow in on tailscale0 comment "Tailscale VPN"

# Habilitar UFW sem prompt interativo
echo "y" | sudo ufw enable
echo "    UFW configurado e ativo."

echo ""
echo "==> [A2] Configurando DOCKER-USER chain (impede Docker de bypassar UFW)..."

# Detectar interface de rede publica (pode ser eth0, ens3, enp1s0, etc.)
PUBLIC_IFACE=$(ip route show default 2>/dev/null | awk '{print $5}' | head -1)
if [ -z "$PUBLIC_IFACE" ]; then
  PUBLIC_IFACE="eth0"
  echo "    AVISO: nao detectou interface padrao, usando eth0"
else
  echo "    Interface publica detectada: $PUBLIC_IFACE"
fi

# Verificar se a chain DOCKER-USER existe (Docker precisa estar instalado)
if sudo iptables -L DOCKER-USER -n >/dev/null 2>&1; then
  # 1) Permitir trafego de retorno (ESTABLISHED/RELATED) - sem isso,
  #    containers nao recebem respostas de APIs externas (Moonshot, Telegram, etc.)
  if sudo iptables -C DOCKER-USER -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN 2>/dev/null; then
    echo "    Regra conntrack ESTABLISHED,RELATED ja existe."
  else
    sudo iptables -I DOCKER-USER 1 -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
    echo "    Regra conntrack ESTABLISHED,RELATED adicionada."
  fi

  # 2) Bloquear conexoes NOVAS vindas de fora da Tailscale
  if sudo iptables -C DOCKER-USER -i "$PUBLIC_IFACE" ! -s 100.64.0.0/10 -j DROP 2>/dev/null; then
    echo "    Regra DROP non-Tailscale ja existe."
  else
    sudo iptables -A DOCKER-USER -i "$PUBLIC_IFACE" ! -s 100.64.0.0/10 -j DROP
    echo "    Regra DROP non-Tailscale adicionada para interface $PUBLIC_IFACE."
  fi
else
  echo "    AVISO: Chain DOCKER-USER nao existe ainda."
  echo "    Isso e normal se Docker nao foi reiniciado recentemente."
  echo "    Criando regras que serao aplicadas quando Docker iniciar..."
  sudo iptables -N DOCKER-USER 2>/dev/null || true
  sudo iptables -I DOCKER-USER 1 -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN 2>/dev/null || true
  sudo iptables -A DOCKER-USER -i "$PUBLIC_IFACE" ! -s 100.64.0.0/10 -j DROP 2>/dev/null || true
fi

# Instalar iptables-persistent (separado, pois requer debconf)
echo ""
echo "    Instalando iptables-persistent para salvar regras..."
# Pre-configurar respostas para evitar prompt interativo
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections 2>/dev/null || true
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections 2>/dev/null || true

sudo apt-get install -y iptables-persistent 2>/dev/null || {
  echo "    AVISO: iptables-persistent falhou. Salvando regras manualmente..."
  sudo mkdir -p /etc/iptables
  sudo iptables-save | sudo tee /etc/iptables/rules.v4 >/dev/null
  echo "    Regras salvas em /etc/iptables/rules.v4"
}

# Tentar persistir se netfilter-persistent esta disponivel
if command -v netfilter-persistent >/dev/null 2>&1; then
  sudo netfilter-persistent save
  echo "    Regras iptables persistidas via netfilter-persistent."
else
  sudo mkdir -p /etc/iptables
  sudo iptables-save | sudo tee /etc/iptables/rules.v4 >/dev/null
  echo "    Regras salvas manualmente em /etc/iptables/rules.v4"
fi

# ----- A3. Criar diretorios -----
echo ""
echo "==> [A3] Criando diretorios isolados por instancia..."

mkdir -p /data/openclaw-1/.openclaw /data/openclaw-1/workspace
chown -R 1000:1000 /data/openclaw-1
chmod 700 /data/openclaw-1
echo "    /data/openclaw-1/ criado (uid 1000, modo 700)"

mkdir -p /data/openclaw-2/.openclaw /data/openclaw-2/workspace
chown -R 1000:1000 /data/openclaw-2
chmod 700 /data/openclaw-2
echo "    /data/openclaw-2/ criado (uid 1000, modo 700)"

# ----- A4. Gerar tokens -----
echo ""
echo "==> [A4] Gerando tokens de autenticacao..."

TOKEN_1=$(openssl rand -hex 32)
TOKEN_2=$(openssl rand -hex 32)

echo ""
echo "============================================="
echo " TOKENS GERADOS - SALVE EM LOCAL SEGURO"
echo "============================================="
echo ""
echo "  TOKEN_1: $TOKEN_1"
echo "  TOKEN_2: $TOKEN_2"
echo ""
echo "  TAILSCALE_IP: $TAILSCALE_IP"
echo ""
echo "============================================="
echo " Copie os valores acima para usar no Portainer"
echo "============================================="

# Salvar em arquivo protegido para referencia
cat > /data/openclaw-tokens.env <<EOF
# OpenClaw Tokens - Gerado em $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# NUNCA compartilhe este arquivo
TOKEN_1=$TOKEN_1
TOKEN_2=$TOKEN_2  
TAILSCALE_IP=$TAILSCALE_IP
EOF
chmod 600 /data/openclaw-tokens.env
echo ""
echo "  Tokens tambem salvos em /data/openclaw-tokens.env (chmod 600)"

echo ""
echo "============================================="
echo " Setup VPS Completo!"
echo "============================================="
echo ""
echo " Proximos passos:"
echo "   1. No seu PC: docker build + docker push"
echo "   2. No Portainer: criar Stack com o compose"
echo "   3. No Portainer: configurar env vars (TOKEN_1, TOKEN_2, TAILSCALE_IP)"
echo "   4. No Portainer: deploy da stack"
echo "   5. No Portainer Console: rodar onboarding em cada instancia"
echo ""
echo " Referencia rapida (aprendizados):"
echo "   - Config no host: /data/openclaw-1/.openclaw/openclaw.json (e openclaw-2)"
echo "   - Se openclaw-gw-N reiniciar em loop: edite o JSON no host (ex.: dmPolicy invalido)"
echo "   - dmPolicy (Telegram etc.): use pairing | allowlist | open | disabled (NAO \"allow\")"
echo "   - Aprovar pairing: docker exec -it openclaw-cli-N node dist/index.js pairing approve telegram <CODIGO>"
echo ""
