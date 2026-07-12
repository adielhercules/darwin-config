## Why

The current config deploys one monolithic setup with no differentiation between machine types. As you have been using both a personal laptop and a work laptop, differences are emerging that make a single config increasingly awkward to maintain:

- **System packages / Homebrew casks** differ between machines (e.g., zed/herd/postman personally vs vscodium/corporate VPN clients at work)
- **Network configuration** differs (corporate certificates affect proxy settings or cert stores)
- **Application shortcuts vary** — tuna and aerospace have different workspace layouts, app combos, and tool availability depending on the machine
- Managing diffs in git between machines requires manual cherry-picking or patching

A proper profile split removes this friction: one config repo, explicit per-machine deployment, shared base stays DRY, differences are bounded to well-scoped locations.

## What Changes

- Add a `profile` argument (`personal` | `work`) to the flake, defaulting to `"personal"`
- Remove all hostname detection logic — profile selection is purely via `--argstr profile` on CLI or convenience functions in `init.sh`
- Create `nix/lib/resolve-module.nix` — a helper function that resolves module file paths with pattern matching (e.g., `fish-personal.bindings` falls back to `fish.config`)
- Create `nix/darwin/profiles/` directory:
  - `defaults.nix` — system packages, brew casks/scripts shared by both machines (list-appending for all entries)
  - `personal.nix` — personal-only additions only (no repetition of shared values)
  - `work.nix` — work-only additions only
- Create profile-specific modules:
  - `nix/modules/home/aerospace/` — dir-based, with `main.toml` (shared workspace layout) and `personal.toml`/`work.toml` (per-profile diffs)
  - `nix/modules/home/tuna/` — dir-based with shared base config module plus two separate full configs (`personal/config.toml`, `work/config.toml`) differing in app combos (~20% diff)
  - `fish-personal.bindings` / `fish-work.bindings` — per-profile shellInit additions (aliases, proxies, corp settings)
- Update `nix/darwin/home.nix` to use the module resolver for all profile-dependent imports
- Add `deploy_personal`/`deploy_work` convenience functions in `init.sh`

## Capabilities

### New Capabilities
- `split-profiles`: Profile-based multi-machine deployment via a `--argstr profile` argument. System packages, brew casks, and per-tool configs are resolved through directory-level or file-level pattern matching with shared bases falling back to defaults. Supports both TOML-suffix overrides (aerospace) and near-duplicate full configs (tuna).

### Modified Capabilities
<!-- No existing spec-level requirements change; the profile mechanism is additive -->

## Impact

- **`nix/flake.nix`**: Add `profile` argument to flake outputs; pass to darwinConfigurations
- **`nix/darwin/default.nix`**: Accept `profile` parameter, import `profiles/{defaults,personal,work}.nix`, remove or bypass hostname detection
- **`nix/lib/resolve-module.nix`**: New — profile-aware module resolver with fallback logic
- **`nix/darwin/home.nix`**: Use resolver for all module imports; replace hardcoded module paths with resolved ones
- **`nix/darwin/profiles/`**: New — `defaults.nix`, `personal.nix`, `work.nix`
- **`nix/modules/home/aerospace/`**: Directory restructuring with shared + per-profile TOMLs
- **`nix/modules/home/tuna/`**: Directory restructuring with shared base module + per-profile full configs
- **`nix/modules/home/fish-personal.bindings`**: New — personal shell aliases/hooks
- **`nix/modules/home/fish-work.bindings`**: New — work corporate settings/proxies
- **`init.sh`**: Add `deploy_personal`/`deploy_work` shortcuts with explicit profile flag
- **No breaking changes** to existing modules (ghostty, helix, neovim, zellij, oh_my_posh)
