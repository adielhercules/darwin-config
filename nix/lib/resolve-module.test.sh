#!/usr/bin/env bash
# Smoke test for nix/lib/resolve-module.nix
#
# Verifies:
#   (a) resolver returns the profile-specific file when it exists (fish bindings)
#   (b) resolver falls back to the shared file when no profile variant exists (ghostty)
#
# Run from the repo root: bash nix/lib/resolve-module.test.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Test (a): profile-specific file exists (fish bindings) ..."
result_a=$(nix-instantiate --eval --strict --expr '
  let
    resolver = import '"${SCRIPT_DIR}"'/resolve-module.nix { };
  in resolver.resolveModule {
    profile = "personal";
    base = '"${SCRIPT_DIR}"'/../modules/home/fish;
    ext = ".bindings";
    sep = "-";
  }
')
echo "  -> $result_a"
case "$result_a" in
  *"fish-personal.bindings"*) echo "  PASS" ;;
  *) echo "  FAIL: expected fish-personal.bindings"; exit 1 ;;
esac

echo "Test (b): no profile variant, falls back to shared (ghostty.nix) ..."
result_b=$(nix-instantiate --eval --strict --expr '
  let
    resolver = import '"${SCRIPT_DIR}"'/resolve-module.nix { };
  in resolver.resolveModule {
    profile = "work";
    base = '"${SCRIPT_DIR}"'/../modules/home/ghostty;
  }
')
echo "  -> $result_b"
case "$result_b" in
  *"ghostty.nix"*) echo "  PASS" ;;
  *) echo "  FAIL: expected fallback to ghostty.nix"; exit 1 ;;
esac

echo "All resolver smoke tests passed."
