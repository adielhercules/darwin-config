## Why

An audit against nix.dev best practices, the NixOS Wiki, and Determinate Systems guidelines found 14 issues in the codebase — 5 high, 5 medium, 4 low priority. These range from hardcoded paths that break portability, to duplicate packages, to missing linting guardrails. None are breaking today, but they accumulate technical debt and deviate from documented Nix idioms. This change addresses all of them in a single cohesive pass, and adds post-apply validation guardrails to prevent regression.

## What Changes

**Flake & dependency fixes:**
- Replace hardcoded `rootPath = "/Users/adielhercules/darwin-config"` with `rootPath = self` (the flake source) for portability
- Add `inputs.nixpkgs.follows = "nixpkgs"` to `nix-homebrew` input (currently the only input missing it)
- Fix path concatenation to use Nix path type instead of string interpolation (`rootPath + "/config"` not `"${rootPath}/config"`)
- Remove dead `x86_64-linux` formatter entry from flake outputs (macOS-only config)

**Identity & secrets:**
- Move git email file location from `<repo>/.local/git-email` (gitignored, breaks with `self`) to `~/.local/git-email` (user-local, impure read via `builtins.getEnv "HOME"`)
- Replace hardcoded `uid = 501` with dynamic detection via `id -p` at eval time
- Remove duplicated `"Adiel Hercules"` git user name from both git modules (parameterize or centralize)

**Module code quality:**
- Remove `lib.mkForce` from helix settings (attribute-level merging suffices; mkForce prevents other modules from contributing)
- Remove duplicate `fd` package from `home.nix`
- Remove duplicate `unstable.devenv` from `home.nix` (already in systemPackages)
- Extract ~110-line zellij plugin/zjstatus inline config block to a separate `.nix` file

**Cleanup:**
- Rename `oh_my_posh.nix` to `oh-my-posh.nix` (consistent kebab-case)
- Replace `fish-colored-man` raw `fetchFromGitHub` with nixpkgs `fishPlugins` if available
- Remove commented-out code from `helix.nix`, `home.nix`, `ghostty.nix`
- Add proper `home.stateVersion` explanation comment

**Guardrails:**
- Add mandatory post-apply validation sequence to `AGENTS.md` and `openspec/config.yaml`: `git add` → `nix flake check` → `nix fmt` → `deadnix` → `statix`
- Update validation commands section to document all checks

## Capabilities

### New Capabilities
- `post-apply-validation`: Mandatory validation sequence (flake check, formatting, deadnix, statix) that must run after every openspec change before marking tasks complete

### Modified Capabilities
- `nix-repo-hygiene`: Extend the "Deduplicated flake inputs" requirement to include `nix-homebrew`; add requirement that flake outputs have no dead/system-inapplicable entries
- `git-email-config`: Change email file location from `${rootPath}/.local/git-email` to `~/.local/git-email` (read via `builtins.getEnv "HOME"`); update `init.sh` to write to the new location
- `dynamic-user-detection`: Add requirement that UID is resolved dynamically at eval time rather than hardcoded

## Impact

- `nix/flake.nix`: rootPath changed to `self`, nix-homebrew follows added, dead formatter removed
- `nix/darwin/default.nix`: path concatenation fixed, dynamic UID
- `nix/darwin/home.nix`: duplicate packages removed, oh_my_posh import updated, commented code removed, stateVersion comment improved
- `nix/modules/home/helix.nix`: mkForce removed, commented code removed
- `nix/modules/home/zellij.nix`: plugin block extracted to separate file
- `nix/modules/home/git-personal.nix`, `git-work.nix`: rootPath arg removed, name parameterized
- `nix/modules/home/oh_my_posh.nix` → `oh-my-posh.nix`: renamed
- `nix/modules/home/fish.nix`: fish-colored-man source changed
- `nix/modules/home/ghostty.nix`: commented code removed
- `nix/lib/git-email.nix`: reads from `~/.local/git-email` via HOME
- `init.sh`: email file written to `~/.local/git-email`
- `AGENTS.md`: post-apply validation section added
- `openspec/config.yaml`: post-apply rules added
