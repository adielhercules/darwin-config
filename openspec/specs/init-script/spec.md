### Requirement: init.sh replaces rootPath placeholder
`init.sh` SHALL replace the `<init-required>` placeholder in `nix/flake.nix` with the absolute path of the repository root (`$SCRIPT_DIR`) using `sed`. This stage runs when `--paths` or `--all` is passed, or when no flags are given. `nix/darwin/default.nix` and `nix/flake.nix` no longer contain any hostname placeholder — darwinConfigurations are keyed by profile name (`personal`/`work`), not by machine hostname.

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
`init.sh` SHALL run `nix run nix-darwin/master#darwin-rebuild` with
`nix-command` and `flakes` experimental features to perform the bootstrap
deploy. This stage runs when `--bootstrap` or `--all` is passed, or when no
flags are given. Before invoking `darwin-rebuild`, this stage SHALL first
require a non-empty `.local/git-email` file (see `git-email-config`
capability) and SHALL auto-detect/export any corporate certs found in
`~/.config/darwin-secrets/` (see `work-profile-cert-bootstrap` capability),
scoped only to this bootstrap command's environment.

#### Scenario: Bootstrap on fresh machine
- **WHEN** `darwin-rebuild` is not yet installed and user runs `init.sh` or
  `init.sh --bootstrap`, with `.local/git-email` already set
- **THEN** nix-darwin SHALL be bootstrapped via `nix run` without requiring a
  locally installed `darwin-rebuild`

#### Scenario: Bootstrap blocked without git email set
- **WHEN** user runs `init.sh` or `init.sh --bootstrap` and `.local/git-email`
  is missing or empty
- **THEN** the script SHALL exit non-zero before invoking any `nix`/
  `darwin-rebuild` command, printing guidance to run
  `./init.sh --email you@example.com` first

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
