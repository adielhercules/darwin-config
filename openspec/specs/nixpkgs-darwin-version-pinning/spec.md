## Requirements

### Requirement: Matched stable release trio for primary flake inputs
The flake's primary `nixpkgs`, `nix-darwin`, and `home-manager` inputs SHALL be pinned to the same matched stable release train (Darwin-specific `nixpkgs-<ver>-darwin` branch, `nix-darwin-<ver>` branch, and `release-<ver>` branch respectively) rather than independently-moving rolling branches, so that `nix-darwin`'s release-branch compatibility assertion is satisfied.

#### Scenario: Inputs pinned to the 26.05 trio
- **WHEN** `nix/flake.nix` is inspected
- **THEN** `nixpkgs.url` resolves to `github:NixOS/nixpkgs/nixpkgs-26.05-darwin`, `nix-darwin.url` resolves to `github:nix-darwin/nix-darwin/nix-darwin-26.05`, and `home-manager.url` resolves to `github:nix-community/home-manager/release-26.05`

#### Scenario: Flake evaluates cleanly with matched inputs
- **WHEN** `nix flake check` is run against the repo after the version bump
- **THEN** evaluation succeeds for both the `personal` and `work` darwin configurations with no version-mismatch assertion errors from `nix-darwin`

#### Scenario: Secondary unstable overlay input remains independent
- **WHEN** the flake inputs are inspected after the bump
- **THEN** the secondary `nixpkgs-unstable` input (used for the `unstable.*` overlay package set) remains pinned to `github:nixos/nixpkgs/nixos-unstable`, unaffected by the primary-input version pinning

### Requirement: Homebrew activation cleanup verified compatible with pinned nix-darwin revision
Before a nixpkgs/nix-darwin version bump is considered complete, the homebrew `onActivation.cleanup` behavior SHALL be verified against the actual per-profile cask sets to confirm the pinned `nix-darwin` revision includes the `--force-cleanup` flag fix (nix-darwin PR #1789) required by current Homebrew CLI semantics.

#### Scenario: Force-cleanup flag present in locked nix-darwin source
- **WHEN** the locked `nix-darwin` revision's homebrew module source is inspected after `nix flake lock`
- **THEN** the `brew bundle cleanup`/`--zap` invocation includes the `--force-cleanup` (or `--force`) flag required by current Homebrew CLI versions for cask removal during `onActivation.cleanup = "zap"`

#### Scenario: Profile switch does not fail cleanup unexpectedly
- **WHEN** deploying the `personal` profile via `just deploy` (or an equivalent dry-run) while the `work` profile's cask (`visual-studio-code`) may still be installed, or vice versa with `personal`'s `herd` cask
- **THEN** the homebrew activation step completes without an unhandled cleanup failure, correctly removing/retaining casks per the active profile's declared `homebrew.casks` list

### Requirement: Stylix input pinning posture is deliberate and documented
The `stylix` flake input SHALL either be pinned to a specific release branch/tag consistent with
the matched stable trio (`nixpkgs`, `nix-darwin`, `home-manager`), or, if no such aligned
branch/tag exists upstream, `nix/flake.nix` SHALL carry an explicit comment adjacent to
`stylix.url` stating that the input intentionally tracks its default branch and that updates to
it should be performed deliberately (e.g. via a scoped `nix flake lock --update-input stylix`)
rather than incidentally via a broad `nix flake update`/`just up`.

#### Scenario: Stylix pinned to an aligned branch
- **WHEN** an upstream `nix-community/stylix` branch or tag aligned with the pinned 26.05 trio
  exists
- **THEN** `stylix.url` in `nix/flake.nix` SHALL reference that branch/tag rather than the bare
  repository default

#### Scenario: Stylix intentionally floating, documented
- **WHEN** no upstream branch/tag aligned with 26.05 exists for `stylix`
- **THEN** `nix/flake.nix` SHALL contain a comment immediately adjacent to `stylix.url` stating
  that the input intentionally floats on its default branch and describing how a deliberate
  update should be performed
