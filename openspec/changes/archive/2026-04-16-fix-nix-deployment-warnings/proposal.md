## Why

Each `darwin-rebuild switch` currently emits five classes of deprecation/migration warnings that clutter deployment output and indicate the config is not aligned with current nixpkgs/home-manager expectations. Addressing them now prevents silent behavior drift and makes it easier to spot real issues in future deploys.

## What Changes

- Replace `nixfmt-classic` with `nixfmt` in all `home.packages` declarations (2 files)
- Replace deprecated `final.system` / `prev.system` overlay references with `final.stdenv.hostPlatform.system` / `prev.stdenv.hostPlatform.system`
- Add explicit `programs.git.signing.format = null` to silence the git signing default migration warning (adopting new default — no active commit signing in use)
- Add explicit `gtk.gtk4.theme = null` to silence the GTK4 theme default migration warning (macOS-only setup, no GTK apps)
- Bump `home.stateVersion` from `"24.11"` to `"25.05"` after confirming no breaking HM behavior changes between those versions

## Capabilities

### New Capabilities

- `nix-warnings-cleanup`: Resolve all active nixpkgs/home-manager deprecation warnings in the darwin config to produce a clean deployment output.

### Modified Capabilities

<!-- No existing specs have requirement changes driven by this work. -->

## Impact

- **`nix/darwin/home.nix`**: Replace `nixfmt-classic` → `nixfmt` in packages; add `programs.git.signing.format = null`; add `gtk.gtk4.theme = null`; bump `home.stateVersion`
- **`nix/modules/home/neovim.nix`**: Replace `nixfmt-classic` → `nixfmt` in packages
- **`nix/darwin/default.nix`**: Replace `final.system` / `prev.system` with `stdenv.hostPlatform.system` equivalents in the nixpkgs-unstable overlay and zjstatus package reference
- No API or external interface changes; all changes are build-time config adjustments
- Bumping `home.stateVersion` must be treated carefully — confirms no breaking changes exist between `24.11` and `25.05` for this config
