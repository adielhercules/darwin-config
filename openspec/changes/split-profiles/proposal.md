## Why

The current config deploys one monolithic setup with no differentiation between machine types. As you have been using both a personal laptop and a work laptop, differences are emerging that make a single config increasingly awkward to maintain:

- **System packages / Homebrew casks** differ between machines (e.g., zed/herd/postman personally vs vscodium/corporate VPN clients at work)
- **Network configuration** differs (corporate certificates affect proxy settings or cert stores)
- **Application shortcuts vary** — tuna and aerospace have different workspace layouts, app combos, and tool availability depending on the machine
- Managing diffs in git between machines requires manual cherry-picking or patching

A proper profile split removes this friction: one config repo, explicit per-machine deployment, shared base stays DRY, differences are bounded to well-scoped locations.

## What Changes

- Add two named flake outputs — `darwinConfigurations.personal` and `darwinConfigurations.work` — selected explicitly via `--flake ".#personal"` or `".#work"`. (Flake outputs are pure functions of inputs; `--argstr` has no effect on `nix build`/`darwin-rebuild switch --flake`, so profile selection cannot be a CLI argument — it must be encoded in the flake output name.)
- Remove `init.sh`'s `run_hostname_sed` bootstrap step entirely — it exists today only to rename the darwinConfiguration key to match the machine's hostname so `darwin-rebuild switch --flake .` (no explicit target) auto-resolves. Since configs are now named by profile, this hostname-matching convenience is intentionally given up in favor of always requiring an explicit `--flake ".#<profile>"` target.
- Create `nix/lib/resolve-module.nix` — a helper function that resolves module file paths with pattern matching (e.g., `fish-personal.bindings` falls back to `fish.nix`)
- Create `nix/darwin/profiles/` directory:
  - `defaults.nix` — system packages, brew casks/scripts shared by both machines (list-appending for all entries)
  - `personal.nix` — personal-only additions only (no repetition of shared values)
  - `work.nix` — work-only additions, plus conditional import of an external secrets file (see below)
- Add external secrets support for the work profile: `~/.config/darwin-secrets/work.nix` (outside the git repo, never committed) holds corporate certificates, proxy settings, and any other sensitive work-only values. `profiles/work.nix` imports it conditionally via `builtins.pathExists`; if missing, a `warnings` entry is emitted at build time (soft warning, not a failure) — only when the work profile is being built.
- Create profile-specific modules:
  - `nix/modules/home/aerospace/` — dir-based, with `main.toml` (shared workspace layout) and `personal.toml`/`work.toml` (per-profile diffs), merged via `lib.recursiveUpdate` on the parsed TOML attrsets — no custom merge logic
  - `nix/modules/home/tuna/` — dir-based with shared base config module plus two separate full configs (`personal/config.toml`, `work/config.toml`) differing in app combos (~20% diff — near-duplicate, not merged, since diffs live in deeply nested arrays)
  - `fish-personal.bindings` / `fish-work.bindings` — per-profile shellInit additions (aliases, proxies, corp settings), loaded alongside the shared `fish.nix` base
- Update `nix/darwin/home.nix` to use the module resolver for all profile-dependent imports
- Add `deploy_personal`/`deploy_work` convenience functions in `init.sh` that wrap `darwin-rebuild switch --flake ".#personal"` / `".#work"`

## Capabilities

### New Capabilities
- `split-profiles`: Profile-based multi-machine deployment via named flake outputs (`darwinConfigurations.personal` / `.work`). System packages, brew casks, and per-tool configs are resolved through directory-level or file-level pattern matching with shared bases falling back to defaults. Supports both TOML-merge overrides (aerospace, via `lib.recursiveUpdate`) and near-duplicate full configs (tuna). Includes an external, non-committed secrets file mechanism for corporate certificates/proxy settings, with a soft build-time warning if the work profile is deployed without it present.

### Modified Capabilities
<!-- No existing spec-level requirements change; the profile mechanism is additive -->

## Impact

- **`nix/flake.nix`**: Replace single `darwinConfigurations."Adiels-MacBook-Pro"` with `darwinConfigurations.personal` and `darwinConfigurations.work`, both built from the same shared module list plus their respective `profiles/*.nix`
- **`nix/darwin/default.nix`**: Accept a `profile` parameter (passed internally from flake.nix, not via CLI), import `profiles/{defaults,personal,work}.nix` accordingly
- **`nix/lib/resolve-module.nix`**: New — profile-aware module resolver with fallback logic
- **`nix/darwin/home.nix`**: Use resolver for all module imports; replace hardcoded module paths with resolved ones
- **`nix/darwin/profiles/`**: New — `defaults.nix`, `personal.nix`, `work.nix` (with external secrets import + warning)
- **`nix/modules/home/aerospace/`**: Directory restructuring with shared + per-profile TOMLs, merged via `lib.recursiveUpdate`
- **`nix/modules/home/tuna/`**: Directory restructuring with shared base module + per-profile full configs
- **`nix/modules/home/fish-personal.bindings`**: New — personal shell aliases/hooks
- **`nix/modules/home/fish-work.bindings`**: New — work corporate settings/proxies
- **`init.sh`**: Remove `run_hostname_sed` (dead code once configs are profile-named); add `deploy_personal`/`deploy_work` shortcuts targeting the named flake outputs
- **No breaking changes** to existing modules (ghostty, helix, neovim, zellij, oh_my_posh)
- **Behavioral change**: `darwin-rebuild switch --flake .` with no explicit target no longer auto-resolves — an explicit `--flake ".#personal"` or `".#work"` is required on every deploy, by design
