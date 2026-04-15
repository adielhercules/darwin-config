## Why

Three separate shell scripts (`initialize_paths.sh`, `initial-deploy.sh`, `deploy.sh`) handle what is conceptually a single workflow: initialise the repo on a new machine and deploy. Consolidating them into one `init.sh` reduces cognitive overhead and eliminates dead code (`initialize_paths.sh` is already redundant since the paths sub-flake was removed).

## What Changes

- **New**: `init.sh` — single entry-point script combining path init, initial deploy, and standard deploy phases
- **New**: `.githooks/pre-commit` — blocks commits where `nix/flake.nix` staged without `<init-required>` placeholder (prevents real path leaking into git history)
- **Remove**: `initialize_paths.sh` — replaced by path-init section in `init.sh`
- **Remove**: `initial-deploy.sh` — replaced by initial-deploy section in `init.sh`
- **Remove**: `deploy.sh` — replaced by deploy section in `init.sh`
- **Remove**: `nix/paths/flake.nix` and `paths/flake.nix` — no longer needed
- **Modify**: `nix/flake.nix` — hardcoded `rootPath` string replaced with `<init-required>` placeholder; `init.sh` substitutes real path on first run
- `darwin-rebuild` called without full path in deploy section (assumes nix-darwin already installed)
- Hostname detected dynamically (`$(hostname -s)`) for `--flake .#<host>` argument
- `init.sh` sets `core.hooksPath = .githooks` to activate the pre-commit hook

## Capabilities

### New Capabilities

- `init-script`: Single consolidated `init.sh` covering path initialisation, bootstrapped initial deploy, and standard deploy; plus a committed pre-commit hook protecting the `<init-required>` placeholder

### Modified Capabilities

(none)

## Impact

- `nix/flake.nix`: rootPath literal → `<init-required>` placeholder
- `nix/paths/flake.nix`, `paths/flake.nix`: deleted
- `initialize_paths.sh`, `initial-deploy.sh`, `deploy.sh`: deleted
- `init.sh`: new file at repo root
- `.githooks/pre-commit`: new committed hook
- No changes to Nix module logic; `paths.rootPath` propagation unchanged
