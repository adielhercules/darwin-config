## ADDED Requirements

### Requirement: Config directory naming
The repository SHALL use `config/` as the canonical directory for static configuration files consumed by Nix modules via the `files` specialArg. The previous `dotfiles/` directory SHALL NOT exist.

#### Scenario: Config directory exists
- **WHEN** the repository tree is inspected
- **THEN** a `config/` directory exists at the repository root, and no `dotfiles/` directory exists

### Requirement: Tool-specific subdirectories
Static configuration files under `config/` SHALL be organized into subdirectories named after the tool they configure. Each subdirectory SHALL contain only files relevant to that tool.

#### Scenario: Fish tool config
- **WHEN** the `config/fish/` directory is inspected
- **THEN** it contains `simple.omp.json` (Oh My Posh prompt theme) and `zz.fish` (fish shell function)

#### Scenario: Stylix tool config
- **WHEN** the `config/stylix/` directory is inspected
- **THEN** it contains `lcars.yaml` (Base16 color scheme)

#### Scenario: OpenCode tool config
- **WHEN** the `config/opencode/` directory is inspected
- **THEN** it contains `plugins/` (with `.ts` files) and `agents/` (with `.md` files) subdirectories

#### Scenario: Helix tool config
- **WHEN** the `config/helix/` directory is inspected
- **THEN** it contains `yazi-picker.sh`

### Requirement: Files specialArg propagation
All Nix modules that consume static config files from `config/` SHALL access them via the `files` specialArg (i.e., `"${files}/<tool>/<file>"`), not via relative paths to `nix/modules/home/`.

#### Scenario: Oh My Posh uses files arg
- **WHEN** `nix/modules/home/oh_my_posh.nix` is evaluated
- **THEN** it reads the Oh My Posh config from `"${files}/fish/simple.omp.json"`

#### Scenario: OpenCode uses files arg
- **WHEN** `nix/modules/home/opencode.nix` is evaluated
- **THEN** it reads plugin and agent files from `"${files}/opencode/plugins/"` and `"${files}/opencode/agents/"`

#### Scenario: Helix scripts uses files arg
- **WHEN** `nix/modules/home/helix.scripts-manager.nix` is evaluated
- **THEN** it reads `yazi-picker.sh` from `"${files}/helix/yazi-picker.sh"`

#### Scenario: Fish uses files arg
- **WHEN** `nix/modules/home/fish.nix` is evaluated
- **THEN** it reads `zz.fish` from `"${files}/fish/zz.fish"`

### Requirement: No orphaned directories
After moving files to `config/`, any directories under `nix/modules/home/` that become empty SHALL be deleted.

#### Scenario: Empty directories removed
- **WHEN** the repository tree is inspected after the change
- **THEN** no empty directories exist under `nix/modules/home/` that were created by the move
