## ADDED Requirements

### Requirement: init.sh accepts --paths flag
`init.sh` SHALL accept a `--paths` flag that runs sed path substitution and git hook activation only, without running bootstrap or deploy stages.

#### Scenario: --paths flag runs sed and git hooks
- **WHEN** user runs `init.sh --paths`
- **THEN** `nix/flake.nix` SHALL have `rootPath` substituted with the real path AND `git config core.hooksPath` SHALL return `.githooks`
- **AND** no nix build or deploy SHALL be triggered

### Requirement: init.sh accepts --git flag
`init.sh` SHALL accept a `--git` flag that runs only git hook activation, without running sed substitution, bootstrap, or deploy stages.

#### Scenario: --git flag activates hooks only
- **WHEN** user runs `init.sh --git`
- **THEN** `git config core.hooksPath` SHALL return `.githooks`
- **AND** `nix/flake.nix` SHALL NOT be modified

### Requirement: init.sh accepts --bootstrap flag
`init.sh` SHALL accept a `--bootstrap` flag that runs only the `nix run nix-darwin/master#darwin-rebuild` bootstrap deploy, without running path or git stages.

#### Scenario: --bootstrap flag triggers nix run only
- **WHEN** user runs `init.sh --bootstrap`
- **THEN** `nix run nix-darwin/master#darwin-rebuild ... -- switch` SHALL be executed
- **AND** no sed substitution or git config change SHALL occur

### Requirement: init.sh accepts --deploy flag
`init.sh` SHALL accept a `--deploy` flag that runs only `sudo darwin-rebuild switch --flake ".#mymbp" --impure`, without running other stages.

#### Scenario: --deploy flag runs darwin-rebuild only
- **WHEN** user runs `init.sh --deploy`
- **THEN** `sudo darwin-rebuild switch --flake ".#mymbp" --impure` SHALL be executed
- **AND** no path substitution, git config change, or bootstrap SHALL occur

### Requirement: init.sh accepts --all flag
`init.sh` SHALL accept an `--all` flag that runs all stages in order: paths (sed + git hooks), bootstrap deploy, then standard deploy.

#### Scenario: --all flag runs all stages
- **WHEN** user runs `init.sh --all`
- **THEN** all stages SHALL run in order: sed substitution, git hook activation, bootstrap deploy, standard deploy

### Requirement: init.sh defaults to --all when no flag is given
`init.sh` SHALL run all stages when invoked with no arguments, preserving backwards-compatible behaviour.

#### Scenario: No arguments defaults to all stages
- **WHEN** user runs `init.sh` with no arguments
- **THEN** behaviour SHALL be identical to `init.sh --all`

### Requirement: init.sh exits with usage message on unknown flag
`init.sh` SHALL exit non-zero and print a usage message when passed an unrecognised flag.

#### Scenario: Unknown flag rejected
- **WHEN** user runs `init.sh --unknown`
- **THEN** script SHALL print a usage/help message to stderr and exit with non-zero status
