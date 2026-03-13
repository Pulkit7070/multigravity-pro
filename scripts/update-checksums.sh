#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if command -v sha256sum >/dev/null 2>&1; then
  HASH_CMD="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  HASH_CMD="shasum -a 256"
else
  echo "Error: sha256 checksum tool not found (need sha256sum or shasum)" >&2
  exit 1
fi

write_checksum() {
  local src=$1
  local dst=$2
  local sum
  # shellcheck disable=SC2086
  sum="$($HASH_CMD "$src" | awk '{print $1}')"
  printf '%s  %s\n' "$sum" "$src" > "$dst"
}

write_checksum "multigravity" "multigravity.sha256"
write_checksum "multigravity.ps1" "multigravity.ps1.sha256"

echo "Updated checksum files:"
echo "  multigravity.sha256"
echo "  multigravity.ps1.sha256"
