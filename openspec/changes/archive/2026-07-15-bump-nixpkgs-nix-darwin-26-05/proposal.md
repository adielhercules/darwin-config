## Why

The flake currently pins `nixpkgs` to the rolling `nixpkgs-unstable` branch and `nix-darwin` to the rolling `master` branch independently. A prior hygiene change (`2026-07-15-improve-nix-best-practices`, tasks.md item 7.1) attempted to bump only `nix-darwin` forward and hit a hard `just deploy` failure: newer `nix-darwin` asserts that `nixpkgs` must be on a matching release branch, and the rolling `nixpkgs-unstable` pin doesn't satisfy that. The bump was reverted, and that change explicitly recommended a dedicated follow-up to move both inputs together onto a matched stable release. `nixpkgs-26.05`/`nix-darwin-26.05` is confirmed (via `git ls-remote`) as the current latest matched-stable pair, replacing the previous plan of targeting `25.11` (already the prior stable release as of now).

## What Changes

- Replace `nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"` with `github:NixOS/nixpkgs/nixpkgs-26.05-darwin` (the nix-darwin-recommended, Darwin-tested nixpkgs branch for this release).
- Replace `nix-darwin.url = "github:nix-darwin/nix-darwin/master"` with `github:nix-darwin/nix-darwin/nix-darwin-26.05`.
- Replace `home-manager.url = "github:nix-community/home-manager"` (implicit `master`) with `github:nix-community/home-manager/release-26.05`, keeping it matched to the same stable train.
- Leave the secondary `nixpkgs-unstable` input (`github:nixos/nixpkgs/nixos-unstable`, used only for the `unstable.*` overlay package set in `nix/darwin/default.nix`) unchanged — it is intentionally rolling and independent of this bump.
- Leave `stylix`, `devenv`, `zjstatus`, `nix-homebrew`, `homebrew-*` inputs unchanged; they continue to follow the primary `nixpkgs` input as today.
- Regenerate `nix/flake.lock` for the changed inputs.
- Explicitly verify the homebrew `--force-cleanup` fix (nix-darwin PR #1789) is present in the locked `nix-darwin-26.05` revision, and manually validate `onActivation.cleanup` behavior against both profiles' actual cask sets (`work.nix`: `visual-studio-code`; `personal.nix`: `herd`) before considering the bump complete — this is the specific failure mode that broke the prior attempt.
- **BREAKING**: None to deployed system behavior expected — package versions will shift as part of the normal stable-release bump, but no manual migration steps are anticipated. If the homebrew cleanup verification step surfaces an issue, it will be documented and resolved (or the bump held) rather than silently deployed.

## Capabilities

### New Capabilities
- `nixpkgs-darwin-version-pinning`: Establishes that the flake's `nixpkgs`, `nix-darwin`, and `home-manager` primary inputs are pinned to a matched stable release train (currently 26.05) rather than independently-moving rolling branches, and that homebrew activation cleanup behavior is verified compatible with the pinned `nix-darwin` revision before a bump is considered complete.

### Modified Capabilities
- None. `nix-repo-hygiene`, `nix-warnings-cleanup`, `split-profiles`, `git-default-branch`, `init-script`, `init-script-flags`, `opencode-agent-config`, `headroom-ai-install` are unaffected.

## Impact

- **Affected files**: `nix/flake.nix`, `nix/flake.lock` (regenerated).
- **Affected tooling**: none beyond the flake inputs themselves; no CI/workflow changes needed.
- **Affected dependencies**: all packages transitively sourced from the primary `nixpkgs`/`nix-darwin`/`home-manager` inputs will move to their 26.05-train versions; the secondary `nixpkgs-unstable` overlay set is unaffected.
- **Risk carried over from prior attempt**: nix-darwin's homebrew cleanup (`--force-cleanup`) behavior interacting with per-profile cask sets (`work.nix` vs `personal.nix`) during `just deploy` — explicitly called out as a required verification step in this change, not deferred.
