#!/bin/bash
set -euo pipefail

REPO="Pulkit7070/multigravity-pro"
BRANCH="main"
RAW="https://raw.githubusercontent.com/$REPO/$BRANCH"
INSTALL_DIR="/usr/local/bin"
TMP_DIR="$(mktemp -d)"

# ── helpers ──────────────────────────────────────────────────────────────────
print_step () { echo "  → $1"; }
abort ()       { echo "Error: $1" >&2; exit 1; }
cleanup_tmp () { rm -rf "$TMP_DIR"; }
trap cleanup_tmp EXIT

download_file() {
  local url=$1
  local out=$2
  local label=$3

  print_step "Downloading $label..."
  curl -fsSL "$url" -o "$out"
}

install_with_backup() {
  local src=$1
  local dest=$2
  local mode=$3
  local backup="${dest}.bak.$$"

  if [ -f "$dest" ]; then
    cp -f "$dest" "$backup"
  fi

  if install -m "$mode" "$src" "$dest"; then
    rm -f "$backup"
    return 0
  fi

  if [ -f "$backup" ]; then
    mv -f "$backup" "$dest"
  fi
  abort "failed to install $dest and previous version was restored"
}

# ── platform ─────────────────────────────────────────────────────────────────
case "$(uname -s)" in
  Darwin)
    PLATFORM="darwin"
    ;;
  Linux)
    PLATFORM="linux"
    ;;
  *)
    abort "unsupported platform. Multigravity currently supports macOS and Linux."
    ;;
esac

# ── preflight ────────────────────────────────────────────────────────────────
command -v curl &>/dev/null || abort "curl is required but not found"

# fall back to ~/.local/bin if /usr/local/bin isn't writable without sudo
if [ ! -w "$INSTALL_DIR" ]; then
  INSTALL_DIR="$HOME/.local/bin"
  mkdir -p "$INSTALL_DIR"
  # warn if not in PATH
  if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "Warning: $INSTALL_DIR is not in your PATH."
    echo "  Add this to your shell profile (~/.zshrc or ~/.bashrc):"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
  fi
fi

echo "Installing Multigravity to $INSTALL_DIR ..."

# ── download multigravity script ─────────────────────────────────────────────
script_tmp="$TMP_DIR/multigravity"
download_file "$RAW/multigravity" "$script_tmp" "multigravity"
install_with_backup "$script_tmp" "$INSTALL_DIR/multigravity" 755

# ── download macOS icon ──────────────────────────────────────────────────────
if [ "$PLATFORM" = "darwin" ]; then
  icon_tmp="$TMP_DIR/icon.icns"
  download_file "$RAW/icon.icns" "$icon_tmp" "icon.icns"
  install_with_backup "$icon_tmp" "$INSTALL_DIR/icon.icns" 644
fi

echo ""
echo "✓ Multigravity installed successfully!"
echo ""
echo "Usage:"
echo "  multigravity help"
echo "  multigravity new <profile-name>"
echo "  multigravity <profile-name>"

if [ "$PLATFORM" = "linux" ] && ! command -v antigravity &>/dev/null && [ ! -x /usr/share/antigravity/antigravity ]; then
  echo ""
  echo "Note:"
  echo "  Antigravity was not found on this machine."
  echo "  Install Antigravity for Linux and ensure 'antigravity' is on PATH,"
  echo "  or launch Multigravity with MULTIGRAVITY_APP=/path/to/antigravity."
fi
