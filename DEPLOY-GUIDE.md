# OpenClaw Deploy Guide - VPS Hostinger + Portainer

Guia passo a passo para deploy de 2 instancias OpenClaw isoladas.

## Arquivos criados automaticamente

| Arquivo | Descricao | Onde usar |
|---|---|---|
| `vps-setup.sh` | Script de setup do host (Tailscale, firewall, diretorios, tokens) | Executar via SSH na VPS |
| `portainer-stack.yml` | Docker Compose para o Portainer | Colar no editor de Stack do Portainer |

---

## Passo 1: Imagem Oficial do OpenClaw

O OpenClaw distribui sua imagem oficial e estavel atraves do GitHub Container Registry.
Voce nao precisa fazer build local. A imagem a ser utilizada é:

`ghcr.io/openclaw/openclaw:latest`

---

## Passo 2: Setup da VPS via SSH (uma unica vez)

```bash
ssh root@SEU_IP_VPS

# Opcao A: Executar script automatizado
curl -o /tmp/vps-setup.sh https://...  # ou copie o arquivo
bash /tmp/vps-setup.sh

# Opcao B: Copiar e colar os comandos do vps-setup.sh manualmente
```

Ao final, anote os valores que aparecem:
- `TOKEN_1`
- `TOKEN_2`
- `TAILSCALE_IP`

---

## Passo 3: Criar Stack no Portainer

1. Abra o Portainer: `https://SEU_IP_VPS:9443`
2. Va em **Stacks** > **Add Stack**
3. Nome: `openclaw`
4. Cole o conteudo de `portainer-stack.yml` no editor
5. Em **Environment variables**, adicione:

| Name | Value |
|---|---|
| OPENCLAW_IMAGE | ghcr.io/openclaw/openclaw:latest |
| TAILSCALE_IP | (IP do passo 2) |
| TOKEN_1 | (token do passo 2) |
| TOKEN_2 | (token do passo 2) |

6. Clique **Deploy the stack**

---

## Passo 4: Onboarding (Portainer Console)

### Instancia 1:
1. Portainer > Containers > `openclaw-cli-1` > **Console** > Connect (shell: `/bin/sh`)
2. Execute:
```sh
node dist/index.js onboard --no-install-daemon
```
3. Siga o wizard:
   - Gateway bind: **lan**
   - Gateway auth: **token**
   - Gateway token: **(cole TOKEN_1)**
   - Tailscale exposure: **Off**
   - Install Gateway daemon: **No**

### Instancia 2:
1. Portainer > Containers > `openclaw-cli-2` > **Console** > Connect
2. Execute:
```sh
node dist/index.js onboard --no-install-daemon
```
3. Mesmo wizard, com **TOKEN_2**

---

## Passo 5: Configurar API Keys (Portainer Console)

### Instancia 1:
1. Portainer > Containers > `openclaw-cli-1` > **Console**
2. Execute:
```sh
cat >> /home/node/.openclaw/.env <<'EOF'
ANTHROPIC_API_KEY=sk-ant-SUA_CHAVE_USUARIO_A
EOF
```

### Instancia 2:
1. Portainer > Containers > `openclaw-cli-2` > **Console**
2. Execute:
```sh
cat >> /home/node/.openclaw/.env <<'EOF'
ANTHROPIC_API_KEY=sk-ant-SUA_CHAVE_USUARIO_B
EOF
```

---

## Passo 6: Reiniciar e Verificar

### Reiniciar gateways:
1. Portainer > Containers > `openclaw-gw-1` > **Restart**
2. Portainer > Containers > `openclaw-gw-2` > **Restart**

### Verificar logs:
- Portainer > Containers > `openclaw-gw-1` > **Logs**
  - Esperado: `[gateway] listening on ws://0.0.0.0:18789`
- Portainer > Containers > `openclaw-gw-2` > **Logs**
  - Esperado: `[gateway] listening on ws://0.0.0.0:19789`

### Health check (via Console):
1. Portainer > Containers > `openclaw-gw-1` > **Console**
```sh
node dist/index.js health --token "$OPENCLAW_GATEWAY_TOKEN"
```
2. Repetir para `openclaw-gw-2`

---

## Passo 7: Acessar

| Usuario | URL |
|---|---|
| A | `http://TAILSCALE_IP:18789` |
| B | `http://TAILSCALE_IP:19789` |

Requisito: Tailscale instalado e conectado no dispositivo do usuario.

---

## Passo 8: GoogleAdsExpert (agente consultor de Google Ads)

Agente OpenClaw que audita e gerencia contas de Google Ads continuamente,
usando o **Maton** (skill `google-ads-api`) para dados ao vivo. Metodologia e
documentacao completas em `agents/google-ads-expert/` e `docs/`.

### Metodo recomendado: auto-install pelo stack (sem SSH)

O `docker-compose.yml` **baixa a skill do repositorio no boot** do gateway (igual
faz com `notion`/`google-ads-api`) e registra o agente + habilita a skill. Voce so
precisa **atualizar e redeployar a stack no Portainer**:

1. **Merge o PR na `main`** (a skill precisa estar na branch que o gateway vai baixar).
2. Portainer > **Stacks** > `openclaw` > **Editor**: cole a versao atualizada do
   `docker-compose.yml` (a que contem o bloco de auto-install).
3. (Opcional) Em **Environment variables**, ajuste se necessario:
   | Name | Quando usar | Default |
   |---|---|---|
   | `GAE_REF` | testar antes do merge → use o nome da branch | `main` |
   | `GITHUB_TOKEN` | **so se o repo for privado** (GitHub PAT, scope `repo`) | vazio |
4. **Update the stack** (o Portainer recria o `openclaw-gw-1`, que baixa a skill no boot).
5. Nos **Logs** do container do gateway, procure: `google-ads-expert: skill instalada`.

> **Nome do container.** O servico do gateway nao fixa `container_name`, entao o
> nome real e prefixado pela stack (ex.: `openclaw-openclaw-gw-1-1`). Para achar:
> `docker ps --format '{{.Names}}' | grep gw`. No Portainer, use o botao **Restart**
> na tela do container (nao precisa do nome).

### Alternativa: deploy manual via SSH (host)

Se preferir instalar a partir de um clone no host (em vez do auto-install):
```bash
# No HOST da VPS (via SSH), no repo clonado:
sudo sh agents/google-ads-expert/deploy/deploy-google-ads-expert.sh \
  --openclaw-dir /data/openclaw-1/.openclaw   # confirme o path real do volume
```
Depois reinicie o gateway pelo Portainer. Confira no host:
`ls /data/openclaw-1/.openclaw/skills/google-ads-expert/`.

### Usar
Fale com o agente **GoogleAdsExpert** (Telegram/Discord/Control UI):
- "Audita a conta 123-456-7890" (auditoria completa + Health Score)
- "Onde invisto os proximos R$ 10.000?" / "Qual campanha pausar hoje?"
- "Por que meu CPA subiu?" / "Gera o relatorio executivo"

> **Autonomia:** o agente le dados e recomenda livremente; **toda mudanca
> (pausar, ajustar bid/budget, negativas) exige confirmacao explicita** antes de
> ser aplicada via Maton. Se o Maton nao expuser escrita, o agente entrega o
> passo-a-passo para execucao manual.

---

## Passo 9: GitHub Skill (skill local, API REST)

Skill que permite ao agente **main** interagir com o GitHub (repositorios,
issues, PRs, commits, CI/Actions). Como o `clawhub` **nao funciona nesta stack**
(o mesmo motivo pelo qual `google-ads-api` falha no boot), a skill e **escrita
localmente no boot** (mesmo padrao do fallback do Notion) e instrui o agente a
usar a **API REST do GitHub via `curl` + `GITHUB_TOKEN`** — sem depender do `gh`
CLI nem de rede para ClawHub. Se o binario `gh` existir no PATH, tambem funciona
(ele autentica sozinho via `GITHUB_TOKEN`/`GH_TOKEN`; **nao precisa de
`gh auth login`**).

### Metodo recomendado: auto-install pelo stack (sem SSH)

O `docker-compose.yml` ja escreve a skill `github` no boot, habilita
`skills.entries.github` e a disponibiliza para o agente `main`. Basta
**atualizar e redeployar a stack no Portainer**:

1. Portainer > **Stacks** > `openclaw` > **Editor**: garanta que o
   `docker-compose.yml` esta atualizado (com o bloco `INSTALAR GITHUB SKILL`).
2. Em **Environment variables**, adicione (necessario para operacoes autenticadas):
   | Name | Value | Quando usar |
   |---|---|---|
   | `GITHUB_TOKEN` | GitHub PAT (scope `repo`) | operacoes autenticadas (ler repo privado, criar PR/issue, comentar, ver CI) |
3. **Update the stack** (o Portainer recria o gateway, que escreve a skill no boot).
4. Nos **Logs** do container do gateway, procure por:
   `Instalando GitHub skill (local, API REST)` (primeira vez) ou
   `GitHub skill já existe`.

> **Sem `gh auth login`.** A autenticacao vem da env `GITHUB_TOKEN` (injetada em
> `skills.entries.github` e tambem como `GH_TOKEN`). Nao rode `sudo apt install
> gh` dentro do container: nao persiste entre deploys e o container e nao-root/
> endurecido (`no-new-privileges`, `cap_drop: ALL`). Sem `GITHUB_TOKEN`, a skill
> so faz leitura publica (rate limit menor).

### Usar
Fale com o agente **Main** (Telegram/Discord/Control UI):
- "Liste as issues abertas do repo X"
- "Abra um PR da branch Y" / "Comente na PR #123"
- "Resuma os ultimos commits do repo Z"

> Sem `GITHUB_TOKEN`, a skill fica limitada a operacoes publicas/nao autenticadas
> (e sujeita a rate limit menor).

---

## Verificacao de Seguranca

De uma maquina EXTERNA (sem Tailscale), execute:

```bash
nmap -p 18789,19789 SEU_IP_PUBLICO_VPS
```

Resultado esperado: **filtered** ou **closed** (NAO open).

---

## Aprendizados e correcoes

### 1. Firewall (iptables) — trafego de retorno para os containers

A regra DOCKER-USER que bloqueia conexoes de fora da Tailscale **também bloqueava o trafego de RETORNO** (respostas de APIs externas). Resultado: `TypeError: fetch failed` para Moonshot, Telegram, Discord, Brave, etc.

**Correcao ja aplicada no `vps-setup.sh`:** insercao da regra de conntrack **antes** do DROP:

- `ESTABLISHED,RELATED` → RETURN (permite respostas de conexoes iniciadas pelos containers).

Se a VPS foi configurada **antes** dessa correcao, aplique manualmente e persista:

```bash
sudo iptables -I DOCKER-USER 1 -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
docker restart openclaw-gw-1
```

### 2. Device pairing — CLI no container exige aprovacao na primeira vez

O comando `node dist/index.js devices list` (e outros que chamam o gateway) envia **identidade de dispositivo**. O gateway exige que esse dispositivo esteja pareado. Na primeira vez:

- O comando falha com: `gateway closed (1008): pairing required`.
- O gateway **ja registrou** um pedido de pairing em disco.

**Como resolver:**

1. Abra a Control UI no navegador **com o token na URL**:  
   `http://TAILSCALE_IP:18789/__openclaw__/control/?token=TOKEN_1`
2. Va em **Devices** no menu lateral.
3. Em **Pending**, clique em **Approve** no pedido do CLI.
4. Rode de novo no container: `node dist/index.js devices list --url ws://openclaw-gw-1:18789 --token TOKEN_1` — a partir daqui o dispositivo fica pareado.

O bypass `dangerouslyDisableDeviceAuth` no stack so dispensa device **para a Control UI** (navegador); o CLI continua precisando de pairing.

### 3. Modelo (Moonshot), canais (Discord), ferramentas (Brave)

- **Moonshot:** no console do container: `node dist/index.js onboard --auth-choice moonshot-api-key` (ou config manual em `openclaw.json` → `models.providers.moonshot`).
- **Discord:** habilitar plugin em `plugins.entries.discord` e config em `channels.discord`; token do bot em [Discord Developer Portal](https://discord.com/developers/applications). Primeiro use `channels add --channel discord --token "..."` apos garantir que o plugin esteja em `plugins.entries`.
- **Brave (web_search):** API key em [brave.com/search/api](https://brave.com/search/api/) (plano "Data for Search"); config em `tools.web.search` ou env `BRAVE_API_KEY` no container do gateway.

Documentacao oficial: [docs.openclaw.ai](https://docs.openclaw.ai) (providers, channels, tools/web).
