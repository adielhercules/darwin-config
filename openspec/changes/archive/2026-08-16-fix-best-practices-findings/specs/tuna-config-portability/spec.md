## ADDED Requirements

### Requirement: No hardcoded personal paths in tracked Tuna config source
`nix/modules/home/tuna/config.shared.toml` (and any per-profile
`<profile>/config.delta.toml` files) SHALL NOT contain a literal username segment in an
absolute path. Any path under `/Users/<username>/` SHALL use the file's existing `<user>`
placeholder token, which `nix/modules/home/tuna/default.nix` substitutes with
`config.home.username` at build time.

#### Scenario: Android Studio path uses placeholder
- **WHEN** `config.shared.toml` is inspected
- **THEN** the Android Studio binding's `url` field SHALL contain `/Users/<user>/Applications/`
  rather than a literal username

#### Scenario: New paths added under $HOME follow the same convention
- **WHEN** a future edit adds a new absolute path under a user's home directory to
  `config.shared.toml` or a per-profile delta file
- **THEN** that path SHALL use the `<user>` placeholder token rather than a hardcoded username
