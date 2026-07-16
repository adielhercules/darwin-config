## ADDED Requirements

### Requirement: init.sh auto-detects and applies corporate certs during bootstrap
Before running the bootstrap `nix run nix-darwin/master#darwin-rebuild --
switch` command, `init.sh` SHALL check `~/.config/darwin-secrets/` for any
`.crt`/`.pem` files. If one or more are found, it SHALL concatenate them into
a single temporary bundle file and export `NIX_SSL_CERT_FILE`,
`SSL_CERT_FILE`, and `CURL_CA_BUNDLE` pointing at that bundle, scoped only to
the environment of the bootstrap command's child process.

#### Scenario: Certs present before bootstrap
- **WHEN** `~/.config/darwin-secrets/` contains one or more `.crt`/`.pem`
  files and user runs `./init.sh --bootstrap` (or `--all`)
- **THEN** a temporary CA bundle SHALL be created containing the concatenated
  contents of those files
- **AND** `NIX_SSL_CERT_FILE`, `SSL_CERT_FILE`, and `CURL_CA_BUNDLE` SHALL be
  set to that bundle's path for the bootstrap command only

#### Scenario: Multiple cert files present
- **WHEN** `~/.config/darwin-secrets/` contains more than one `.crt`/`.pem`
  file
- **THEN** all of them SHALL be concatenated into the single temporary bundle
  used for the bootstrap command

#### Scenario: No certs present
- **WHEN** `~/.config/darwin-secrets/` contains no `.crt`/`.pem` files (or
  does not exist) and user runs `./init.sh --bootstrap` (or `--all`)
- **THEN** no cert-related environment variables SHALL be set
- **AND** if the machine's resolved profile is `work`, a warning SHALL be
  printed before attempting bootstrap, noting that corporate certs were not
  found and the fetch may fail on networks with TLS interception
- **AND** the bootstrap command SHALL still be attempted (not blocked)

### Requirement: Temporary cert bundle is cleaned up after bootstrap
The temporary CA bundle file created for the bootstrap command SHALL be
deleted after the bootstrap command completes, regardless of whether it
succeeded or failed.

#### Scenario: Cleanup after successful bootstrap
- **WHEN** the bootstrap command completes successfully
- **THEN** the temporary CA bundle file SHALL no longer exist afterward

#### Scenario: Cleanup after failed bootstrap
- **WHEN** the bootstrap command exits non-zero
- **THEN** the temporary CA bundle file SHALL no longer exist afterward
