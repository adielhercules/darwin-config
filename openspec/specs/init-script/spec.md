### Requirement: init.sh activates git hooks
`init.sh` SHALL run `git config core.hooksPath .githooks` to activate the committed hook directory. This stage runs when `--git` or `--all` is passed, or when no flags are given.

#### Scenario: Hook activation on --git flag
- **WHEN** user runs `init.sh --git`
- **THEN** `git config core.hooksPath` SHALL return `.githooks`

#### Scenario: Hook activation on --all flag / no flags
- **WHEN** user runs `init.sh --all` or `init.sh` with no arguments
- **THEN** `git config core.hooksPath` SHALL return `.githooks`

### Requirement: init.sh runs initial bootstrap deploy
`init.sh` SHALL run `sudo ... nix run nix-darwin/master#darwin-rebuild` with
`nix-command` and `flakes` experimental features, `-- switch --flake
"$SCRIPT_DIR/nix" --impure`, to perform the bootstrap deploy. This stage runs
when `--bootstrap` or `--all` is passed, or when no flags are given. Before
invoking `darwin-rebuild`, this stage SHALL first require a non-empty
`~/.config/git/config.local` file (see `git-email-config` capability), then
run `ensure_secrets_dir` and auto-detect/export any corporate certs found in
`~/.config/darwin-secrets/` (see `work-profile-cert-bootstrap` capability),
scoped only to this bootstrap command's environment. The `sudo` invocation
SHALL explicitly forward `HOME` and the cert-related env vars as `VAR=value`
prefixes so that root's `darwin-rebuild switch` activation trusts the same
corporate certs and resolves the correct `$HOME`.

#### Scenario: Bootstrap on fresh machine
- **WHEN** `darwin-rebuild` is not yet installed and user runs `init.sh` or
  `init.sh --bootstrap`, with `~/.config/git/config.local` already set
- **THEN** nix-darwin SHALL be bootstrapped via `nix run` without requiring a
  locally installed `darwin-rebuild`
- **AND** the final `switch` step SHALL run under `sudo` (prompting for a
  password), while the fetch/build phase runs as the invoking user

#### Scenario: Bootstrap blocked without git email set
- **WHEN** user runs `init.sh` or `init.sh --bootstrap` and
  `~/.config/git/config.local` is missing or empty
- **THEN** the script SHALL exit non-zero before invoking any `nix`/
  `darwin-rebuild` command, printing guidance to run
  `./init.sh --email you@example.com` first

### Requirement: Dead scripts and sub-flake removed
`initialize_paths.sh`, `initial-deploy.sh`, `deploy.sh`, `nix/paths/flake.nix`, and `paths/flake.nix` SHALL be deleted from the repository.

#### Scenario: Scripts absent after change
- **WHEN** change is implemented
- **THEN** none of the above files SHALL exist in the repository
