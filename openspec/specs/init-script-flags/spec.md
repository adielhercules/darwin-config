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

### Requirement: init.sh --deploy flag performs a real deploy
`init.sh` SHALL accept a `--deploy` flag that invokes `just deploy` to perform `darwin-rebuild switch`, relying on hostname-based auto-resolution to select the correct profile. This flag SHALL NOT fail or require any profile flag, since profile-less deploy is now the standard, always-correct path.

#### Scenario: --deploy flag performs a real deploy
- WHEN the user runs `init.sh --deploy`
- THEN `just deploy` SHALL be invoked, which runs `darwin-rebuild switch --flake ./nix ...`
- AND the deploy SHALL succeed without requiring any profile-selecting flag

### Requirement: init.sh accepts --email flag
`init.sh` SHALL accept an `--email <address>` flag/argument pair, parsed
independently of positional stage flags so it may appear standalone or
combined with any other flag in the same invocation (e.g.
`./init.sh --email you@example.com`, `./init.sh --all --email you@example.com`).
When present, it SHALL write the given address to `.local/git-email` before
any other requested stage runs.

#### Scenario: --email flag recognized standalone
- **WHEN** user runs `./init.sh --email you@example.com`
- **THEN** `.local/git-email` SHALL be written with that address
- **AND** no other stage SHALL run

#### Scenario: --email flag combined with a stage flag
- **WHEN** user runs `./init.sh --all --email you@example.com`
- **THEN** `.local/git-email` SHALL be written first
- **AND** the `--all` stage sequence SHALL then proceed

### Requirement: init.sh accepts --all flag
`init.sh` SHALL accept an `--all` flag that runs the paths stage (sed + git hooks) and the bootstrap stage, in order. It SHALL NOT perform a full profile-specific deploy itself; instead it SHALL print instructions directing the user to run `init.sh --deploy` (or `just deploy`) next, which will auto-resolve the correct profile via hostname.

#### Scenario: --all flag bootstraps only, does not deploy
- WHEN the user runs `init.sh --all`
- THEN the paths stage (sed substitution, git hook activation) and the bootstrap stage SHALL run in order
- AND no full `darwin-rebuild switch` deploy SHALL be triggered as part of `--all` itself
- AND the script SHALL print guidance to run `init.sh --deploy` or `just deploy` next

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
