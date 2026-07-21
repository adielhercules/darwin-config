## Requirements

### Requirement: rtk is installed via Homebrew
The system SHALL include `rtk` in `homebrew.brews` so that the rtk binary is installed declaratively and present after every `darwin-rebuild switch`.

#### Scenario: rtk binary present after rebuild
- **WHEN** `darwin-rebuild switch` completes successfully
- **THEN** `rtk --version` returns a valid version string

#### Scenario: rtk removed when entry removed from brews
- **WHEN** `"rtk"` is removed from `homebrew.brews` and `darwin-rebuild switch` runs
- **THEN** `brew list rtk` returns non-zero (not installed), because `onActivation.cleanup = "zap"`

### Requirement: rtk OpenCode hook is initialized automatically
The system SHALL run `rtk init -g --opencode` as a Home Manager activation step so the OpenCode plugin hook is configured without any manual steps after a rebuild.

#### Scenario: Hook initialized on rebuild
- **WHEN** `darwin-rebuild switch` completes and rtk is on PATH
- **THEN** `rtk init --show` confirms the OpenCode hook is active

#### Scenario: Activation is skipped gracefully when rtk not on PATH
- **WHEN** `darwin-rebuild switch` runs but the `rtk` binary is not yet on PATH (e.g. first boot before Homebrew PATH is configured)
- **THEN** the Home Manager activation completes without error, and the hook will be initialized on the next rebuild

### Requirement: rtk GitHub Copilot hook is initialized automatically
The system SHALL run `rtk init -g --copilot` as a Home Manager activation step so the GitHub Copilot `PreToolUse` hook is configured without any manual steps after a rebuild.

#### Scenario: Copilot hook initialized on rebuild
- **WHEN** `darwin-rebuild switch` completes and rtk is on PATH
- **THEN** `rtk init --show` confirms the Copilot hook is active

#### Scenario: Activation is idempotent
- **WHEN** `darwin-rebuild switch` is run multiple times
- **THEN** `rtk init` does not produce errors on subsequent runs (init is idempotent)

### Requirement: rtk configuration is encapsulated in its own Home Manager module
The system SHALL define all rtk-related Home Manager configuration in `nix/modules/home/rtk.nix`, following the per-tool module pattern used by `helix.nix`, `neovim.nix`, and others.

#### Scenario: Module is imported in home.nix
- **WHEN** `nix/darwin/home.nix` is evaluated
- **THEN** `../modules/home/rtk.nix` is present in the `imports` list
