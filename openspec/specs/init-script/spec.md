### Requirement: init.sh replaces rootPath placeholder
`init.sh` SHALL replace the `<init-required>` placeholder in `nix/flake.nix` with the absolute path of the repository root (`$SCRIPT_DIR`) using `sed`, AND replace the `<hostname>` placeholder in `nix/darwin/default.nix` and `nix/flake.nix` with the machine's hostname from `scutil --get LocalHostName`. This stage runs when `--paths` or `--all` is passed, or when no flags are given.

#### Scenario: Fresh clone path init
- **WHEN** user runs `init.sh`, `init.sh --paths`, or `init.sh --all` on a freshly cloned repo where `nix/flake.nix` contains `rootPath = "<init-required>"` and both nix files contain `<hostname>`
- **THEN** `nix/flake.nix` SHALL contain `rootPath = "<absolute-path-to-repo>"` with the real path substituted, AND both `nix/darwin/default.nix` and `nix/flake.nix` SHALL contain the machine's actual hostname in place of `<hostname>`

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
`init.sh` SHALL run `sudo darwin-rebuild switch --flake "./nix" --impure` after bootstrap. `darwin-rebuild` automatically resolves the flake attribute from the machine's hostname via `scutil --get LocalHostName`. This stage runs when `--deploy` or `--all` is passed, or when no flags are given.

#### Scenario: Deploy resolves hostname automatically
- **WHEN** `init.sh` reaches the deploy phase (via `init.sh` or `init.sh --deploy`)
- **THEN** `sudo darwin-rebuild switch --flake "./nix" --impure` SHALL be executed and `darwin-rebuild` SHALL automatically select the flake attribute matching the machine's `scutil --get LocalHostName`

### Requirement: pre-commit hook blocks real rootPath commit
`.githooks/pre-commit` SHALL exit non-zero and print an error if `nix/flake.nix` is staged and its staged content does not contain the string `<init-required>`.

#### Scenario: Real path staged
- **WHEN** user stages `nix/flake.nix` containing `rootPath = "/some/real/path"`
- **THEN** commit SHALL be rejected with message referencing `<init-required>`

#### Scenario: Placeholder present — commit allowed
- **WHEN** user stages `nix/flake.nix` containing `rootPath = "<init-required>"`
- **THEN** commit SHALL proceed without error

#### Scenario: nix/flake.nix not staged — hook silent
- **WHEN** user commits without staging `nix/flake.nix`
- **THEN** hook SHALL exit zero and not block the commit

### Requirement: Dead scripts and sub-flake removed
`initialize_paths.sh`, `initial-deploy.sh`, `deploy.sh`, `nix/paths/flake.nix`, and `paths/flake.nix` SHALL be deleted from the repository.

#### Scenario: Scripts absent after change
- **WHEN** change is implemented
- **THEN** none of the above files SHALL exist in the repository
