## ADDED Requirements

### Requirement: headroom-ai is installed globally via uv
The system SHALL install `headroom-ai[all]` as a global uv tool so that the `headroom` CLI is available on `$PATH` for all interactive sessions after `darwin-rebuild switch`.

#### Scenario: headroom CLI available after rebuild
- **WHEN** user runs `darwin-rebuild switch` on a fresh machine
- **THEN** `headroom --version` exits 0 and prints a version string

#### Scenario: installation is idempotent
- **WHEN** `darwin-rebuild switch` is run on a machine where headroom is already installed
- **THEN** the activation script completes without error and does not downgrade or reinstall unnecessarily

#### Scenario: uv not available
- **WHEN** `uv` is not found on `$PATH` during activation
- **THEN** the activation script skips silently and `darwin-rebuild switch` succeeds

### Requirement: uv is available at user-level
The system SHALL declare `pkgs.uv` in `home.packages` so that `uv` is available to the user without requiring system-level installation.

#### Scenario: uv on PATH after rebuild
- **WHEN** user opens a new shell after `darwin-rebuild switch`
- **THEN** `uv --version` exits 0

### Requirement: headroom module follows established module pattern
The headroom Home Manager module SHALL follow the same structural pattern as `rtk.nix`: a standalone file under `nix/modules/home/`, imported in `home.nix`, using `lib.hm.dag.entryAfter [ "writeBoundary" ]` for activation.

#### Scenario: module is importable
- **WHEN** `nix flake check` or `darwin-rebuild build` is run
- **THEN** the config evaluates without errors related to the headroom module
