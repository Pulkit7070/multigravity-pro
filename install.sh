#!/bin/bash
set -euo pipefail

REPO="sujitagarwal/multigravity-cli"
BRANCH="main"
RAW="https://raw.githubusercontent.com/$REPO/$BRANCH"
INSTALL_DIR="/usr/local/bin"

# ── helpers ──────────────────────────────────────────────────────────────────
print_step () { echo "  → $1"; }
abort ()       { echo "Error: $1" >&2; exit 1; }

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
print_step "Downloading multigravity..."
curl -fsSL "$RAW/multigravity" -o "$INSTALL_DIR/multigravity"
chmod +x "$INSTALL_DIR/multigravity"

# ── download macOS icon ──────────────────────────────────────────────────────
if [ "$PLATFORM" = "darwin" ]; then
  print_step "Downloading icon..."
  curl -fsSL "$RAW/icon.icns" -o "$INSTALL_DIR/icon.icns"
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
