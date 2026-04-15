### Requirement: init.sh substitutes hostname placeholder in nix config files
`init.sh` SHALL read the machine's macOS hostname via `scutil --get LocalHostName` and replace the `<hostname>` placeholder in `nix/darwin/default.nix` and `nix/flake.nix` using `sed`. This substitution runs as part of the paths stage (`--paths` or `--all`), or when no arguments are given.

#### Scenario: Hostname substituted in both nix files on --paths
- **WHEN** user runs `init.sh --paths` on a machine where both `nix/darwin/default.nix` and `nix/flake.nix` contain the `<hostname>` placeholder
- **THEN** both files SHALL contain the machine's actual hostname (as returned by `scutil --get LocalHostName`) in place of `<hostname>`

#### Scenario: Hostname substituted as part of --all
- **WHEN** user runs `init.sh` or `init.sh --all`
- **THEN** both `nix/darwin/default.nix` and `nix/flake.nix` SHALL have `<hostname>` replaced with the real hostname before any deploy stage runs

### Requirement: Nix config files use `<hostname>` placeholder in committed state
`nix/darwin/default.nix` and `nix/flake.nix` SHALL contain `<hostname>` (not a real hostname) as the nix-darwin configuration key in the committed version of the files.

#### Scenario: Placeholder present in committed files
- **WHEN** the change is implemented and files are committed to git
- **THEN** neither `nix/darwin/default.nix` nor `nix/flake.nix` SHALL contain the string `mymbp` or any other real hostname — they SHALL contain `<hostname>` in its place

### Requirement: pre-commit hook blocks commit of resolved hostname in nix files
`.githooks/pre-commit` SHALL exit non-zero and print an error if `nix/darwin/default.nix` or `nix/flake.nix` is staged and its staged content does not contain the `<hostname>` placeholder.

#### Scenario: Resolved hostname staged in default.nix — commit rejected
- **WHEN** user stages `nix/darwin/default.nix` containing a real hostname (e.g., `"mymac"`) instead of `<hostname>`
- **THEN** commit SHALL be rejected with an error message referencing the `<hostname>` placeholder

#### Scenario: Resolved hostname staged in flake.nix — commit rejected
- **WHEN** user stages `nix/flake.nix` containing a real hostname instead of `<hostname>`
- **THEN** commit SHALL be rejected with an error message referencing the `<hostname>` placeholder

#### Scenario: Placeholder present in both files — commit allowed
- **WHEN** user stages `nix/darwin/default.nix` and/or `nix/flake.nix` each containing `<hostname>`
- **THEN** commit SHALL proceed without error

#### Scenario: Neither nix file staged — hook silent
- **WHEN** user commits without staging `nix/darwin/default.nix` or `nix/flake.nix`
- **THEN** hook SHALL exit zero and not block the commit
