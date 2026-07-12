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
`init.sh` SHALL run `nix run nix-darwin/master#darwin-rebuild` with `nix-command` and `flakes` experimental features to perform the bootstrap deploy. This stage runs when `--bootstrap` or `--all` is passed, or when no flags are given.

#### Scenario: Bootstrap on fresh machine
- **WHEN** `darwin-rebuild` is not yet installed and user runs `init.sh` or `init.sh --bootstrap`
- **THEN** nix-darwin SHALL be bootstrapped via `nix run` without requiring a locally installed `darwin-rebuild`

### Requirement: init.sh no longer performs a bare, profile-less deploy
A bare `darwin-rebuild switch --flake "./nix" --impure` (without a `#personal`/`#work` attribute) is no longer valid, since darwinConfigurations are keyed by profile name rather than hostname. `init.sh` SHALL NOT run such a bare deploy as part of any stage, including `--all` or no-argument invocation. Selecting and deploying a profile is done via `init.sh --personal` / `init.sh --work` (see `init-script-flags` capability), which delegates to `just deploy` using the profile-scoped flake target persisted in `Justfile`.

#### Scenario: --all stops after bootstrap and prompts for profile selection
- **WHEN** user runs `init.sh` or `init.sh --all`
- **THEN** the paths stage and bootstrap stage SHALL run, but no `darwin-rebuild switch` targeting a specific profile SHALL be triggered automatically
- **AND** the script SHALL print instructions directing the user to run `./init.sh --personal` or `./init.sh --work` next

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
