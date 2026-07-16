## MODIFIED Requirements

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

## REMOVED Requirements

### Requirement: init.sh no longer performs a bare, profile-less deploy
**Reason**: This requirement described an earlier design where
`darwinConfigurations` were keyed by explicit profile name
(`.#personal`/`.#work`) with no hostname resolution, and `init.sh --deploy`
was a stub that always failed. The current implementation resolves the
profile automatically from the machine's hostname (`hostProfiles` map in
`nix/darwin/default.nix`), so `darwin-rebuild switch --flake ./nix --impure`
(via `just deploy`, which `init.sh --deploy` delegates to) is a fully valid,
working command — there is no profile-less/bare-deploy failure mode to guard
against.
**Migration**: No action needed; `init.sh --deploy` and `just deploy` both
work today via hostname-based profile auto-selection. See the
`init-script-flags` capability's `--deploy` requirement for current behavior.
