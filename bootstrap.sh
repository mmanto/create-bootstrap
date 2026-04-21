#!/usr/bin/env bash
set -euo pipefail

# 🏢 ADD+AI Bootstrap – Furnarius Template
# Empresa: mmanto | Template: git@github.com:mmanto/furnarius.git
# Uso: curl -fsSL <url>/bootstrap.sh | bash -s -- --name=mi-proyecto

# ── Configuración fija ────────────────────────────────────────
readonly TEMPLATE_OWNER="mmanto"
readonly TEMPLATE_REPO="furnarius"
readonly TEMPLATE_FULL="${TEMPLATE_OWNER}/${TEMPLATE_REPO}"
readonly DEFAULT_BRANCH="main"
# ─────────────────────────────────────────────────────────────

log()    { echo "🔹 [Furnarius] $*"; }
info()   { echo "ℹ️  $*"; }
error()  { echo "❌ [ERROR] $*" >&2; exit 1; }
success(){ echo "✅ $*" >&2; }

# ── Parsear argumentos ────────────────────────────────────────
PROJECT_NAME=""
IS_PRIVATE=true
CLONE_LOCAL=true

for arg in "$@"; do
  case $arg in
    --name=*)      PROJECT_NAME="${arg#*=}" ;;
    --public)      IS_PRIVATE=false ;;
    --no-clone)    CLONE_LOCAL=false ;;
    --help)
      echo "Uso: $0 --name=nombre-proyecto [--public] [--no-clone]"
      echo "  --name      (obligatorio) Nombre del nuevo repositorio"
      echo "  --public    Crear repositorio público (por defecto: privado)"
      echo "  --no-clone  No clonar localmente tras crear"
      exit 0 ;;
  esac
done

[[ -z "$PROJECT_NAME" ]] && error "Falta --name=nombre-proyecto. Usa --help para más info."

# ── Detectar SO ───────────────────────────────────────────────
OS="linux"
[[ "$(uname -s)" == "Darwin" ]] && OS="macos"
[[ "$(uname -s)" =~ MINGW|CYGWIN|MSYS ]] && OS="windows"

# ── Instalador inteligente ────────────────────────────────────
install_if_missing() {
  local cmd=$1 pkg=${2:-$1}
  command -v "$cmd" &>/dev/null && return 0
  log "Instalando dependencia: $pkg"
  case "$OS" in
    linux)
      if command -v apt &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y -qq "$pkg"
      elif command -v dnf &>/dev/null; then
        sudo dnf install -y -q "$pkg"
      elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm --quiet "$pkg"
      else
        error "Gestor de paquetes no soportado. Instala '$pkg' manualmente."
      fi ;;
    macos)
      command -v brew &>/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
      brew install -q "$pkg" ;;
    windows)
      log "⚠️ En Windows, se recomienda usar WSL2 o Git Bash para mejor compatibilidad."
      return 1 ;;
  esac
}

# ── Verificar e instalar dependencias base ────────────────────
log "Verificando entorno..."
for dep in "git:git" "curl:curl" "make:make"; do
  IFS=':' read -r cmd pkg <<< "$dep"
  install_if_missing "$cmd" "$pkg"
done

# ── GitHub CLI (gh) ───────────────────────────────────────────
if ! command -v gh &>/dev/null; then
  log "Instalando GitHub CLI (gh)..."
  case "$OS" in
    linux)
      # Intento con repositorio oficial
      if command -v dpkg &>/dev/null; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null || true
        echo "deb [arch=$(dpkg --print-architecture 2>/dev/null || echo amd64) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null 2>&1 || true
        sudo apt-get update -qq && sudo apt-get install -y -qq gh 2>/dev/null && { command -v gh &>/dev/null && return 0; } || true
      fi
      # Fallback: descarga directa del binario
      ARCH=$(uname -m); [[ "$ARCH" == "x86_64" ]] && ARCH="amd64" || ARCH="arm64"
      curl -fsSL "https://github.com/cli/cli/releases/latest/download/gh_linux_${ARCH}.tar.gz" | sudo tar xz -C /usr/local/bin --strip-components=2 "gh_linux_${ARCH}/bin/gh"
      ;;
    macos) brew install -q gh ;;
    windows)
      if command -v choco &>/dev/null; then
        choco install gh -y -q
      else
        error "Instala gh manualmente: https://cli.github.com o usa WSL/Git Bash"
      fi ;;
  esac
fi

# ── Autenticación GitHub ──────────────────────────────────────
log "Verificando autenticación con GitHub..."
if ! gh auth status &>/dev/null; then
  info "Primera vez: configurando acceso..."
  gh auth login --web --git-protocol ssh
fi

# Verificar acceso SSH al template (opcional pero útil)
if [[ "$(gh config get git_protocol)" != "ssh" ]]; then
  log "Configurando protocolo SSH para git (recomendado para empresas)..."
  gh config set git_protocol ssh
fi

# ── Crear proyecto desde template ─────────────────────────────
log "Creando proyecto: ${TEMPLATE_OWNER}/${PROJECT_NAME}"
VISIBILITY_FLAG="--private"
[[ "$IS_PRIVATE" == false ]] && VISIBILITY_FLAG="--public"

if gh repo view "${TEMPLATE_OWNER}/${PROJECT_NAME}" &>/dev/null; then
  error "El repositorio '${TEMPLATE_OWNER}/${PROJECT_NAME}' ya existe."
fi

gh repo create "${TEMPLATE_OWNER}/${PROJECT_NAME}" \
  --template "${TEMPLATE_FULL}" \
  ${VISIBILITY_FLAG} \
  ${CLONE_LOCAL:+--clone} \
  --description "Proyecto ADD+AI generado desde Furnarius"

success "🎉 Repositorio creado: https://github.com/${TEMPLATE_OWNER}/${PROJECT_NAME}"

# ── Post-creación ─────────────────────────────────────────────
if [[ "$CLONE_LOCAL" == true ]]; then
  cd "$PROJECT_NAME"
  log "📁 Proyecto clonado en: $(pwd)"
  
  # Verificar estructura esperada
  if [[ -f "docs/prompts/ai-arch-dialogue.md" ]]; then
    info "✅ Template validado: prompts de arquitectura disponibles"
  else
    log "⚠️ Estructura del template diferente a la esperada. Revisar docs/"
  fi
  
  # Sugerir primeros pasos
  echo ""
  info "🚀 Próximos pasos:"
  echo "   1. Abrir en Kiro: code .  (o tu editor preferido)"
  echo "   2. Usar prompt: docs/prompts/ai-arch-dialogue.md"
  echo "   3. Crear primer ADR: make new-adr TITLE='Inicialización'  (si existe Makefile)"
  echo "   4. Configurar secrets en GitHub: Settings → Secrets and variables"
  echo ""
fi

success "✅ Flujo Furnarius completado. ¡A desarrollar!"