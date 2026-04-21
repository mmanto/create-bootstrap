# bootstrap.ps1 – Furnarius Template Bootstrap (Windows)
# Empresa: mmanto | Template: git@github.com:mmanto/furnarius.git
# Uso: irm <url>/bootstrap.ps1 | iex -args "--name=mi-proyecto"

param(
    [Parameter(Mandatory=$true)][string]$name,
    [switch]$public,
    [switch]$noClone
)

$ErrorActionPreference = "Stop"
$TEMPLATE_OWNER = "mmanto"
$TEMPLATE_REPO = "furnarius"
$TEMPLATE_FULL = "${TEMPLATE_OWNER}/${TEMPLATE_REPO}"

function Log-Info    { param($m) Write-Host "🔹 [Furnarius] $m" -ForegroundColor Cyan }
function Log-Error   { param($m) Write-Host "❌ [ERROR] $m" -ForegroundColor Red; exit 1 }
function Log-Success { param($m) Write-Host "✅ $m" -ForegroundColor Green }

Log-Info "Iniciando bootstrap para: $name"

# ── Verificar winget ─────────────────────────────────────────
if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Log-Error "winget no encontrado. Actualiza Windows o instálalo desde Microsoft Store."
}

# ── Instalar dependencias ────────────────────────────────────
$deps = @{ "git" = "Git.Git"; "gh" = "GitHub.cli"; "make" = "GnuWin32.Make" }
foreach ($tool in $deps.Keys) {
    if (!(Get-Command $tool -ErrorAction SilentlyContinue)) {
        Log-Info "Instalando $($deps[$tool])..."
        winget install --id $($deps[$tool]) --accept-source-agreements --accept-package-agreements --silent
    }
}

# Recargar PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# ── Verificar gh ─────────────────────────────────────────────
if (!(Get-Command gh -ErrorAction SilentlyContinue)) {
    Log-Error "gh no disponible. Reinicia la terminal e intenta de nuevo."
}

# ── Auth GitHub ──────────────────────────────────────────────
Log-Info "Verificando autenticación con GitHub..."
try { gh auth status 2>$null } catch { gh auth login --web --git-protocol ssh }
gh config set git_protocol ssh 2>$null | Out-Null

# ── Crear repositorio ────────────────────────────────────────
$visibility = if ($public) { "--public" } else { "--private" }
$cloneFlag = if ($noClone) { "" } else { "--clone" }

Log-Info "Creando: ${TEMPLATE_OWNER}/${name} desde ${TEMPLATE_FULL}"
try {
    gh repo create "${TEMPLATE_OWNER}/${name}" `
      --template "$TEMPLATE_FULL" `
      $visibility `
      $cloneFlag `
      --description "Proyecto ADD+AI generado desde Furnarius"
} catch {
    Log-Error "Error al crear repositorio: $_"
}

Log-Success "🎉 Repositorio creado: https://github.com/${TEMPLATE_OWNER}/${name}"

# ── Post-creación ────────────────────────────────────────────
if (!$noClone) {
    Set-Location $name
    Log-Info "📁 Proyecto en: $(Get-Location)"
    
    if (Test-Path "docs/prompts/ai-arch-dialogue.md") {
        Write-Host "✅ Template validado: prompts de arquitectura disponibles" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "🚀 Próximos pasos:" -ForegroundColor Yellow
    Write-Host "   1. Abrir en Kiro: code ."
    Write-Host "   2. Usar: docs/prompts/ai-arch-dialogue.md"
    Write-Host "   3. Configurar secrets: GitHub → Settings → Secrets"
    Write-Host ""
}

Log-Success "✅ Flujo Furnarius completado."