#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Stage Functions ──────────────────────────────────────────────────────────

run_paths_sed() {
  echo "Initialising rootPath..."
  sed -i '' "s|rootPath = \"<init-required>\"|rootPath = \"$SCRIPT_DIR\"|g" \
    "$SCRIPT_DIR/nix/flake.nix"
  echo "rootPath set to: $SCRIPT_DIR"
}

run_git() {
  echo "Activating git hooks..."
  git -C "$SCRIPT_DIR" config core.hooksPath .githooks
  echo "Git hooks activated (.githooks)"
}

run_paths() {
  run_paths_sed
  run_git
}

run_bootstrap() {
  echo "Running initial deploy (bootstrap)..."
  nix run nix-darwin/master#darwin-rebuild \
    --extra-experimental-features nix-command \
    --extra-experimental-features flakes \
    -- switch
}

run_deploy() {
  echo "Running deploy..."
  sudo darwin-rebuild switch --flake ".#mymbp" --impure
}

run_all() {
  run_paths
  run_bootstrap
  run_deploy
}

# ─── CLI Dispatch ─────────────────────────────────────────────────────────────

case "${1:-}" in
  --paths)
    run_paths
    ;;
  --git)
    run_git
    ;;
  --bootstrap)
    run_bootstrap
    ;;
  --deploy)
    run_deploy
    ;;
  --all | "")
    run_all
    ;;
  *)
    echo "Usage: $0 [--paths|--git|--bootstrap|--deploy|--all]" >&2
    echo "" >&2
    echo "  --paths      Set rootPath in nix/flake.nix and activate git hooks" >&2
    echo "  --git        Activate git hooks only" >&2
    echo "  --bootstrap  Run initial nix-darwin bootstrap (nix run)" >&2
    echo "  --deploy     Run darwin-rebuild switch" >&2
    echo "  --all        Run all stages in order (default)" >&2
    exit 1
    ;;
esac
