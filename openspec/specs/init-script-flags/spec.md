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

### Requirement: init.sh --deploy flag is a stub that always fails
`init.sh` SHALL accept a `--deploy` flag, but it SHALL always fail (non-zero exit) and print a message directing the user to `--personal`/`--work` and then `just deploy`, since a bare, profile-less deploy is no longer supported.

#### Scenario: --deploy flag always fails with guidance
- **WHEN** user runs `init.sh --deploy`
- **THEN** the script SHALL exit non-zero without performing any deploy
- **AND** it SHALL print a message directing the user to use `--personal` or `--work` to select a profile, then `just deploy` for subsequent day-to-day deploys

### Requirement: init.sh accepts --personal flag
`init.sh` SHALL accept a `--personal` flag that persists `personal` as the selected profile into `Justfile`'s `flake_target` variable (setting it to `./nix#personal`) and then invokes `just deploy` to perform the actual `darwin-rebuild switch`.

#### Scenario: --personal flag sets flake_target and deploys
- **WHEN** user runs `init.sh --personal`
- **THEN** `Justfile`'s `flake_target` SHALL be set to `./nix#personal`
- **AND** `just deploy` SHALL be invoked immediately afterward

### Requirement: init.sh accepts --work flag
`init.sh` SHALL accept a `--work` flag that persists `work` as the selected profile into `Justfile`'s `flake_target` variable (setting it to `./nix#work`) and then invokes `just deploy` to perform the actual `darwin-rebuild switch`.

#### Scenario: --work flag sets flake_target and deploys
- **WHEN** user runs `init.sh --work`
- **THEN** `Justfile`'s `flake_target` SHALL be set to `./nix#work`
- **AND** `just deploy` SHALL be invoked immediately afterward

### Requirement: init.sh accepts --all flag
`init.sh` SHALL accept an `--all` flag that runs the paths stage (sed + git hooks) and the bootstrap stage, in order. It SHALL NOT perform any profile-specific deploy; instead it SHALL print instructions directing the user to run `init.sh --personal` or `init.sh --work` next.

#### Scenario: --all flag bootstraps only, does not deploy
- **WHEN** user runs `init.sh --all`
- **THEN** the paths stage (sed substitution, git hook activation) and the bootstrap stage SHALL run in order
- **AND** no `darwin-rebuild switch` targeting a profile SHALL be triggered
- **AND** the script SHALL print guidance to run `--personal` or `--work` next

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
