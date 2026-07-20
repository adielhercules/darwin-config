#!/bin/bash
#
# init.sh — first-time bootstrap and profile selection/switching ONLY.
#
# For regular, day-to-day deploys once a profile has been selected at least
# once, use `just deploy` (see Justfile) instead of this script.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_LOCAL="$HOME/.config/git/config.local"
SECRETS_DIR="$HOME/.config/darwin-secrets"

# ─── Stage Functions ──────────────────────────────────────────────────────────

run_git() {
  echo "Activating git hooks..."
  git -C "$SCRIPT_DIR" config core.hooksPath .githooks
  echo "Git hooks activated (.githooks)"
}

run_set_email() {
  local email="$1"
  if [ -z "$email" ]; then
    echo "Usage: $0 --email you@example.com" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$GIT_LOCAL")"
  cat > "$GIT_LOCAL" << EOF
[user]
	email = $email
EOF
  echo "Git email written to $GIT_LOCAL"
}

require_email() {
  if [ ! -s "$GIT_LOCAL" ]; then
    echo "Git email not set. Run: $0 --email you@example.com" >&2
    exit 1
  fi
}

# Detects whether this machine's hostname maps to the "work" profile, by
# parsing the same hostProfiles mapping nix/darwin/default.nix uses. Best
# effort only — used solely to decide whether to print a non-blocking
# warning about missing corporate certs.
current_hostname_is_work_profile() {
  local hostname
  hostname="$(scutil --get LocalHostName 2>/dev/null || hostname -s 2>/dev/null || echo "")"
  [ -n "$hostname" ] && grep -q "\"$hostname\" = \"work\";" "$SCRIPT_DIR/nix/darwin/default.nix" 2>/dev/null
}

# Auto-discovers any *.crt/*.pem files already dropped into
# ~/.config/darwin-secrets/ (the same convention profiles/work.nix reads
# post-activation) and exports them as a temporary CA bundle for the
# duration of the bootstrap command only. This solves the chicken-and-egg
# problem where the very first flake/store fetch happens before nix-darwin
# has ever activated (so security.pki.certificateFiles can't help yet).
with_bootstrap_certs() {
  local cert_files=()
  if [ -d "$SECRETS_DIR" ]; then
    while IFS= read -r -d '' f; do
      cert_files+=("$f")
    done < <(find "$SECRETS_DIR" -maxdepth 1 \( -name '*.crt' -o -name '*.pem' \) -type f -print0 2>/dev/null)
  fi

  if [ "${#cert_files[@]}" -gt 0 ]; then
    local cert_bundle
    cert_bundle="$(mktemp)"
    cat "${cert_files[@]}" >"$cert_bundle"
    trap 'rm -f "$cert_bundle"' EXIT
    export NIX_SSL_CERT_FILE="$cert_bundle"
    export SSL_CERT_FILE="$cert_bundle"
    export CURL_CA_BUNDLE="$cert_bundle"
    echo "Found ${#cert_files[@]} cert file(s) in $SECRETS_DIR — using them to trust TLS for this bootstrap."
  elif current_hostname_is_work_profile; then
    echo "Warning: profile=work but no corporate certs found in $SECRETS_DIR." >&2
    echo "If this network intercepts TLS, the bootstrap fetch may fail. See" >&2
    echo "nix/darwin/profiles/work.nix.example for how to add certs." >&2
  fi
}

run_bootstrap() {
  require_email
  with_bootstrap_certs

  echo "Running initial deploy (bootstrap)..."
  nix run nix-darwin/master#darwin-rebuild \
    --extra-experimental-features nix-command \
    --extra-experimental-features flakes \
    -- switch
}

run_deploy() {
  require_email
  echo "Running deploy..."
  (cd "$SCRIPT_DIR" && just deploy)
}

run_all() {
  run_git
  run_bootstrap
  echo "" >&2
  echo "Bootstrap and path setup complete. Deploy your machine's profile with:" >&2
  echo "  ./init.sh --deploy   # or" >&2
  echo "  just deploy" >&2
  echo "" >&2
  echo "Profile selection is automatic, based on this machine's hostname." >&2
}

# ─── Argument Parsing ─────────────────────────────────────────────────────────
#
# --email <address> is parsed independently of the positional stage flag, so
# it may appear standalone (just sets the email and exits) or combined with
# any other flag (sets the email, then continues with the requested stage).

ORIG_ARGC=$#
EMAIL_VALUE=""
REMAINING=()

while [ $# -gt 0 ]; do
  case "$1" in
    --email)
      EMAIL_VALUE="${2:-}"
      if [ $# -ge 2 ]; then
        shift 2
      else
        shift
      fi
      ;;
    *)
      REMAINING+=("$1")
      shift
      ;;
  esac
done

if [ -n "$EMAIL_VALUE" ]; then
  run_set_email "$EMAIL_VALUE"
  if [ "${#REMAINING[@]}" -eq 0 ]; then
    exit 0
  fi
fi

set -- "${REMAINING[@]}"

# ─── CLI Dispatch ─────────────────────────────────────────────────────────────

case "${1:-}" in
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
    if [ "$ORIG_ARGC" -eq 0 ] || [ "${1:-}" = "--all" ]; then
      run_all
    fi
    ;;
  *)
    echo "Usage: $0 [--git|--bootstrap|--deploy|--all] [--email <address>]" >&2
    echo "" >&2
    echo "  --git        Activate git hooks only" >&2
    echo "  --bootstrap  Run initial nix-darwin bootstrap (nix run)" >&2
    echo "  --deploy     Run 'just deploy' (profile auto-selected by hostname)" >&2
    echo "  --all        Run all stages in order (default) — bootstrap only," >&2
    echo "               does NOT deploy; run --deploy afterward" >&2
    echo "  --email <address>" >&2
    echo "               Write the given address to ~/.config/git/config.local" >&2
    echo "               as git's user.email. May be combined with any other" >&2
    echo "               flag above, or used standalone." >&2
    echo "" >&2
    echo "After initial setup, use 'just deploy' (or 'just verbose'/'just check')" >&2
    echo "for regular day-to-day deploys — init.sh is only for first-time" >&2
    echo "bootstrap. Profile selection is automatic, based on the machine's" >&2
    echo "hostname." >&2
    echo "" >&2
    echo "A git email must be set (via --email) before --bootstrap or --deploy" >&2
    echo "will run." >&2
    exit 1
    ;;
esac
