#!/bin/bash
#
# init.sh — first-time bootstrap and profile selection/switching ONLY.
#
# For regular, day-to-day deploys once a profile has been selected at least
# once, use `just deploy` (see Justfile) instead of this script.

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
  echo "NOTE: a bare, profile-less deploy is no longer supported." >&2
  echo "Use --personal or --work to select/switch a profile once, then use" >&2
  echo "'just deploy' for regular day-to-day deploys." >&2
  return 1
}

# Persists the selected profile into Justfile's flake_target variable (the
# same local-only, uncommitted convention used for rootPath in
# nix/flake.nix — see the gitskip/gitunskip aliases in nix/darwin/default.nix),
# then delegates the actual deploy to `just deploy` so darwin_rebuild/
# optimise invocation logic lives in exactly one place (the Justfile).
set_profile() {
  local profile="$1"
  echo "Selecting profile: $profile"
  sed -i '' -E "s|^flake_target := \".*\"|flake_target := \"./nix#${profile}\"|" \
    "$SCRIPT_DIR/Justfile"
  echo "flake_target set to: ./nix#${profile}"
}

deploy_personal() {
  set_profile "personal"
  (cd "$SCRIPT_DIR" && just deploy)
}

deploy_work() {
  set_profile "work"
  (cd "$SCRIPT_DIR" && just deploy)
}

run_all() {
  run_paths
  run_bootstrap
  echo "" >&2
  echo "Bootstrap and path setup complete. Deploy your machine's profile with:" >&2
  echo "  ./init.sh --personal   # or" >&2
  echo "  ./init.sh --work" >&2
  echo "" >&2
  echo "After that, use 'just deploy' for regular day-to-day deploys." >&2
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
  --personal)
    deploy_personal
    ;;
  --work)
    deploy_work
    ;;
  --all | "")
    run_all
    ;;
  *)
    echo "Usage: $0 [--paths|--git|--bootstrap|--deploy|--personal|--work|--all]" >&2
    echo "" >&2
    echo "  --paths      Set rootPath in nix/flake.nix and activate git hooks" >&2
    echo "  --git        Activate git hooks only" >&2
    echo "  --bootstrap  Run initial nix-darwin bootstrap (nix run)" >&2
    echo "  --deploy     (removed) — use --personal/--work, then 'just deploy'" >&2
    echo "  --personal   Select/switch to the personal profile and deploy once" >&2
    echo "               (sets Justfile's flake_target to './nix#personal')" >&2
    echo "  --work       Select/switch to the work profile and deploy once" >&2
    echo "               (sets Justfile's flake_target to './nix#work')" >&2
    echo "  --all        Run all stages in order (default) — bootstrap only," >&2
    echo "               does NOT deploy; run --personal/--work afterward" >&2
    echo "" >&2
    echo "After initial setup, use 'just deploy' (or 'just verbose'/'just check')" >&2
    echo "for regular day-to-day deploys — init.sh is only for first-time" >&2
    echo "bootstrap and for switching between profiles." >&2
    exit 1
    ;;
esac
