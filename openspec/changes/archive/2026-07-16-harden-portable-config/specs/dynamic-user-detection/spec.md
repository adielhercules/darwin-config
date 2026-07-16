## ADDED Requirements

### Requirement: username resolved dynamically at eval time
`nix/darwin/default.nix` SHALL resolve the `username` value used throughout
the configuration by reading the `SUDO_USER` environment variable first,
falling back to `USER` if `SUDO_USER` is empty, and aborting evaluation with
a clear error message if neither is set. No literal username string SHALL
appear in this file.

#### Scenario: SUDO_USER set
- **WHEN** the flake is evaluated with `SUDO_USER=alice` in the environment
- **THEN** `username` SHALL resolve to `"alice"`

#### Scenario: SUDO_USER empty, USER set
- **WHEN** the flake is evaluated with `SUDO_USER` unset/empty and
  `USER=alice` in the environment
- **THEN** `username` SHALL resolve to `"alice"`

#### Scenario: Neither variable set
- **WHEN** the flake is evaluated with both `SUDO_USER` and `USER` empty
- **THEN** evaluation SHALL abort with an error message stating that neither
  `SUDO_USER` nor `USER` is set

### Requirement: work-profile secrets directory derived from dynamic username
`nix/darwin/profiles/work.nix` SHALL derive `secretsDir` from the dynamically
resolved `username`/home path passed in via `specialArgs`, rather than a
hardcoded literal path.

#### Scenario: secretsDir matches resolved username
- **WHEN** the flake is evaluated with a given `username`
- **THEN** `work.nix`'s `secretsDir` SHALL equal `"/Users/${username}/.config/darwin-secrets"`

### Requirement: per-user binary paths derived from home-manager username
Home-manager modules that reference per-user system paths (e.g.
`nix/modules/home/ghostty.nix`'s fish binary path) SHALL derive the username
segment from `config.home.username` rather than a hardcoded literal.

#### Scenario: ghostty fish command uses dynamic username
- **WHEN** home-manager is evaluated for a given user
- **THEN** `ghostty.nix`'s `command` value SHALL contain
  `/etc/profiles/per-user/${config.home.username}/bin/fish`

### Requirement: Tuna config home path templated at build time
`nix/modules/home/tuna/{personal,work}/config.toml`'s URL-encoded home
directory path SHALL be substituted at build time (via
`nix/modules/home/tuna/default.nix`) with the current user's actual home
directory segment, rather than shipping a hardcoded literal in the deployed
file.

#### Scenario: Deployed Tuna config reflects current user
- **WHEN** home-manager links `Library/Application Support/Tuna/config.toml`
  for a given user
- **THEN** the deployed file's URL-encoded path SHALL reference that user's
  actual username, not a hardcoded literal
