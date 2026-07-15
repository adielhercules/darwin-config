## Why

A best-practices review of the Nix flake (`nix/`) found that despite an otherwise clean, pure flake-only setup (no channels, no `with lib;`, correct `stateVersion`/`hostPlatform`, correct home-manager-as-darwin-module wiring), several concrete gaps remain: there is no automated formatting/linting/CI enforcement despite the tools (`nixfmt`, `deadnix`, `statix`) already being installed; two flake inputs (`devenv`, `zjstatus`) pull in their own independent `nixpkgs` closures instead of following the primary one; and iterative development has left behind dead code (an orphaned duplicate module, a broken `just` recipe, stale commented-out blocks) and a hand-rolled option pattern that could use the standard `lib.mkEnableOption` helper plus a safety guard against typo'd profile names. Addressing these now keeps the repo maintainable and aligned with community conventions before it grows further.

## What Changes

- Add a `formatter` output to `nix/flake.nix` (nixfmt-rfc-style) so `nix fmt` works repo-wide.
- Add a GitHub Actions CI workflow that runs `nix flake check`, a format check (`nix fmt -- --check` or equivalent), `deadnix`, and `statix` on push/PR.
- Add `inputs.nixpkgs.follows = "nixpkgs";` to the `devenv` and `zjstatus` flake inputs to deduplicate nixpkgs instances. If adding `follows` to either input breaks `nix flake check` (incompatible pinned versions), that specific input's `follows` addition is reverted and the reason documented in `tasks.md`/commit — the other input's fix still proceeds independently.
- Remove the orphaned/unused `nix/home/fish.nix` (the actually-imported module is `nix/modules/home/fish.nix`).
- Fix the broken `just up-secrets` recipe in `Justfile`, which references a nonexistent `secrets` flake input — either remove the recipe or correct it to match the actual secrets mechanism (external `~/.config/darwin-secrets/` directory, no flake input involved). Given no `secrets` input exists or is planned, the recipe will be removed.
- Clean up accumulated dead/stale code:
  - `darwin/home.nix`: remove the stale commented-out `leader_key` import along with the now-unused `modules/home/leader_key.nix` module and its `leader_key/config.json` asset (unless still desired, in which case re-enable instead of deleting); remove the stale commented-out `zsh` config block; remove the vague stale comment referencing the nonexistent `modules/home/darwin` path.
  - `modules/home/fish.nix`: remove the stale commented-out `mr.fish` `xdg.configFile` entry (no corresponding file exists).
- Refactor `nix/options/shell.nix` to use `lib.mkEnableOption` instead of a hand-rolled boolean option, reducing boilerplate while preserving current behavior/defaults.
- Add an explicit assertion/guard in `nix/darwin/default.nix` so building an unknown/typo'd profile name produces a clear error message instead of an opaque "path does not exist" eval failure.

**BREAKING**: None — all changes are internal tooling/hygiene improvements with no change to deployed system behavior (aside from possibly disabling the `leader_key` module if it's removed rather than re-enabled; this will be confirmed during implementation by checking whether it's actively used).

## Capabilities

### New Capabilities
- `nix-repo-hygiene`: Establishes automated formatting, linting, and CI enforcement for the Nix flake, plus flake-input hygiene (nixpkgs deduplication) and dead-code/consistency guarantees (no orphaned modules, no broken tooling recipes, no dangling comments referencing nonexistent paths) and safer profile-selection error handling.

### Modified Capabilities
- None. `init-script`, `split-profiles`, `git-default-branch`, `init-script-flags`, and `nix-warnings-cleanup` specs are unaffected — this change does not alter their documented requirements/behavior.

## Impact

- **Affected files**: `nix/flake.nix`, `nix/flake.lock` (regenerated), `nix/options/shell.nix`, `nix/darwin/default.nix`, `nix/darwin/home.nix`, `nix/home/fish.nix` (removed), `nix/modules/home/fish.nix`, `nix/modules/home/leader_key.nix` (possibly removed), `nix/modules/home/leader_key/config.json` (possibly removed), `Justfile`, new `.github/workflows/nix-check.yml`.
- **Affected tooling**: adds a CI dependency on GitHub Actions runners capable of running Nix (e.g., `cachix/install-nix-action`); no impact on production deploy path (`just deploy`, `init.sh`).
- **Affected dependencies**: `nix/flake.lock` will be updated for `devenv`/`zjstatus` if their `follows` changes are kept.
- **No impact** on secrets handling design, profile-split architecture, or deployment commands beyond the `up-secrets` recipe removal.
