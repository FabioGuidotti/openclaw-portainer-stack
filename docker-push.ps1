# =============================================================================
# OpenClaw Docker Push Script
# =============================================================================
# Uso: .\docker-push.ps1 -User SEU_USUARIO_DOCKERHUB
# =============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$User
)

$ImageName = "$User/openclaw:latest"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " OpenClaw Docker Push" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Tag da imagem
Write-Host "==> Tagueando imagem como $ImageName ..."
docker tag openclaw:local $ImageName
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao taguear imagem" -ForegroundColor Red
    exit 1
}
Write-Host "    OK" -ForegroundColor Green

# Login
Write-Host ""
Write-Host "==> Fazendo login no Docker Hub..."
Write-Host "    (Digite sua senha/token quando solicitado)"
docker login -u $User
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha no login" -ForegroundColor Red
    exit 1
}
Write-Host "    OK" -ForegroundColor Green

# Push
Write-Host ""
Write-Host "==> Fazendo push de $ImageName ..."
Write-Host "    (Isso pode demorar dependendo da sua internet)"
docker push $ImageName
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha no push" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host " Push concluido com sucesso!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host " Imagem: $ImageName" -ForegroundColor Yellow
Write-Host ""
Write-Host " Proximo passo:" -ForegroundColor Yellow
Write-Host "   Use '$ImageName' como valor de OPENCLAW_IMAGE no Portainer"
Write-Host ""
Write-Host " Se aparecer erro de config (ex.: dmPolicy invalido):" -ForegroundColor Yellow
Write-Host "   No host, edite /data/openclaw-N/.openclaw/openclaw.json"
Write-Host "   dmPolicy deve ser: pairing | allowlist | open | disabled (nao use 'allow')"
Write-Host ""
