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

append_path_export() {
  local rc_file=$1
  local export_line='export PATH="$HOME/.local/bin:$PATH"'

  [ -f "$rc_file" ] || touch "$rc_file"
  if grep -Fq "$export_line" "$rc_file"; then
    return 0
  fi

  {
    echo ""
    echo "# Added by Multigravity installer"
    echo "$export_line"
  } >> "$rc_file"
}

offer_path_update() {
  local shell_name rc_file
  shell_name="$(basename "${SHELL:-}")"

  case "$shell_name" in
    zsh) rc_file="$HOME/.zshrc" ;;
    bash) rc_file="$HOME/.bashrc" ;;
    *) rc_file="$HOME/.profile" ;;
  esac

  echo ""
  echo "$INSTALL_DIR is not in your PATH."
  if [ -t 0 ]; then
    read -r -p "Add it automatically to $rc_file? (y/n) " reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      append_path_export "$rc_file"
      print_step "Added PATH export to $rc_file"
      print_step "Restart your terminal or run: export PATH=\"\$HOME/.local/bin:\$PATH\""
    else
      echo "Add this manually to your shell profile:"
      echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
  else
    echo "Add this to your shell profile:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi
  echo ""
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
  if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    offer_path_update
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
