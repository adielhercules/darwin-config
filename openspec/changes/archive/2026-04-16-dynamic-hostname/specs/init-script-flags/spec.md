## MODIFIED Requirements

### Requirement: init.sh accepts --deploy flag
`init.sh` SHALL accept a `--deploy` flag that runs only `sudo darwin-rebuild switch --flake "./nix" --impure`, without running other stages. `darwin-rebuild` automatically resolves the flake attribute from the machine's hostname.

#### Scenario: --deploy flag runs darwin-rebuild only
- **WHEN** user runs `init.sh --deploy`
- **THEN** `sudo darwin-rebuild switch --flake "./nix" --impure` SHALL be executed
- **AND** no path substitution, git config change, or bootstrap SHALL occur
