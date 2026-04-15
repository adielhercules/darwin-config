## MODIFIED Requirements

### Requirement: init.sh replaces rootPath placeholder
`init.sh` SHALL replace the `<init-required>` placeholder in `nix/flake.nix` with the absolute path of the repository root (`$SCRIPT_DIR`) using `sed`. This stage runs when `--paths` or `--all` is passed, or when no flags are given.

#### Scenario: Fresh clone path init
- **WHEN** user runs `init.sh`, `init.sh --paths`, or `init.sh --all` on a freshly cloned repo where `nix/flake.nix` contains `rootPath = "<init-required>"`
- **THEN** `nix/flake.nix` SHALL contain `rootPath = "<absolute-path-to-repo>"` with the real path substituted

### Requirement: init.sh activates git hooks
`init.sh` SHALL run `git config core.hooksPath .githooks` to activate the committed hook directory. This stage runs when `--paths`, `--git`, or `--all` is passed, or when no flags are given.

#### Scenario: Hook activation on --git flag
- **WHEN** user runs `init.sh --git`
- **THEN** `git config core.hooksPath` SHALL return `.githooks`

#### Scenario: Hook activation on --paths flag
- **WHEN** user runs `init.sh --paths`
- **THEN** `git config core.hooksPath` SHALL return `.githooks`

### Requirement: init.sh runs initial bootstrap deploy
`init.sh` SHALL run `nix run nix-darwin/master#darwin-rebuild` with `nix-command` and `flakes` experimental features to perform the bootstrap deploy. This stage runs when `--bootstrap` or `--all` is passed, or when no flags are given.

#### Scenario: Bootstrap on fresh machine
- **WHEN** `darwin-rebuild` is not yet installed and user runs `init.sh` or `init.sh --bootstrap`
- **THEN** nix-darwin SHALL be bootstrapped via `nix run` without requiring a locally installed `darwin-rebuild`

### Requirement: init.sh runs standard deploy
`init.sh` SHALL run `sudo darwin-rebuild switch --flake ".#mymbp" --impure` after bootstrap. This stage runs when `--deploy` or `--all` is passed, or when no flags are given.

#### Scenario: Deploy uses configured hostname
- **WHEN** `init.sh` or `init.sh --deploy` reaches the deploy phase
- **THEN** the flake target SHALL be `.#mymbp`
