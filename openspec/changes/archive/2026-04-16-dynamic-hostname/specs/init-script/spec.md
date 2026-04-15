## MODIFIED Requirements

### Requirement: init.sh runs standard deploy
`init.sh` SHALL run `sudo darwin-rebuild switch --flake "./nix" --impure` after bootstrap. `darwin-rebuild` automatically resolves the flake attribute from the machine's hostname via `scutil --get LocalHostName`. This stage runs when `--deploy` or `--all` is passed, or when no flags are given.

#### Scenario: Deploy resolves hostname automatically
- **WHEN** `init.sh` reaches the deploy phase (via `init.sh` or `init.sh --deploy`)
- **THEN** `sudo darwin-rebuild switch --flake "./nix" --impure` SHALL be executed and `darwin-rebuild` SHALL automatically select the flake attribute matching the machine's `scutil --get LocalHostName`

### Requirement: init.sh replaces rootPath placeholder
`init.sh` SHALL replace the `<init-required>` placeholder in `nix/flake.nix` with the absolute path of the repository root (`$SCRIPT_DIR`) using `sed`, AND replace the `<hostname>` placeholder in `nix/darwin/default.nix` and `nix/flake.nix` with the machine's hostname from `scutil --get LocalHostName`. This stage runs when `--paths` or `--all` is passed, or when no flags are given.

#### Scenario: Fresh clone path init
- **WHEN** user runs `init.sh`, `init.sh --paths`, or `init.sh --all` on a freshly cloned repo where `nix/flake.nix` contains `rootPath = "<init-required>"` and both nix files contain `<hostname>`
- **THEN** `nix/flake.nix` SHALL contain `rootPath = "<absolute-path-to-repo>"` with the real path substituted, AND both `nix/darwin/default.nix` and `nix/flake.nix` SHALL contain the machine's actual hostname in place of `<hostname>`
