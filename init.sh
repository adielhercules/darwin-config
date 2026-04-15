#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Part 1: Path Initialisation ─────────────────────────────────────────────

echo "Initialising rootPath..."

sed -i '' "s|rootPath = \"<init-required>\"|rootPath = \"$SCRIPT_DIR\"|g" \
  "$SCRIPT_DIR/nix/flake.nix"

git -C "$SCRIPT_DIR" config core.hooksPath .githooks

echo "rootPath set to: $SCRIPT_DIR"
echo "Git hooks activated (.githooks)"

# ─── Part 2: Initial Deploy (bootstrap — nix-darwin not yet installed) ────────

echo "Running initial deploy..."

nix run nix-darwin/master#darwin-rebuild \
  --extra-experimental-features nix-command \
  --extra-experimental-features flakes \
  -- switch

# ─── Part 3: Deploy (darwin-rebuild available) ────────────────────────────────

echo "Running deploy..."

sudo darwin-rebuild switch --flake ".#mymbp" --impure
