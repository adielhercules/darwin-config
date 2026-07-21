### Requirement: init.sh scaffolds the secrets directory before bootstrap
Before checking for certs, `init.sh` SHALL run `ensure_secrets_dir`, which
creates `~/.config/darwin-secrets` if missing. On machines whose hostname
resolves to the `work` profile, it SHALL additionally: (1) idempotently grant
the shared `nixbld` build group traversal rights on `$HOME` via
`chmod +a "group:nixbld allow execute,readextattr,readattr,readsecurity"
"$HOME"` — checking first (via `ls -le "$HOME" | grep nixbld`) so the ACL is
never duplicated on repeat runs — and (2) create a minimal default
`~/.config/darwin-secrets/work.nix` if one does not already exist.

This ACL grant is required because macOS home directories default to mode
`700` (owner-only traversal). Nix builds run as sandboxed `_nixbld1..N`
service users (all members of the shared `nixbld` group); without this ACL,
those users cannot traverse into `~/.config/darwin-secrets` to read corporate
cert files during the build, causing a `Permission denied` build failure
even though the cert file itself is world-readable.

#### Scenario: Secrets directory missing entirely
- **WHEN** `~/.config/darwin-secrets` does not exist and user runs
  `./init.sh --bootstrap` (or `--all`)
- **THEN** the directory SHALL be created before cert discovery runs

#### Scenario: nixbld ACL applied on first work-profile bootstrap
- **WHEN** the machine's hostname resolves to the `work` profile and `$HOME`
  does not yet have a `nixbld` group ACL entry
- **THEN** `init.sh` SHALL grant the `nixbld` group `execute` (traversal)
  rights on `$HOME`
- **AND** a confirmation message SHALL be printed

#### Scenario: nixbld ACL already present — not duplicated
- **WHEN** the machine's hostname resolves to the `work` profile and `$HOME`
  already has a `nixbld` group ACL entry (from a previous bootstrap run)
- **THEN** `init.sh` SHALL NOT attempt to add a duplicate ACL entry

#### Scenario: work.nix auto-scaffolded when missing
- **WHEN** the machine's hostname resolves to the `work` profile and
  `~/.config/darwin-secrets/work.nix` does not exist
- **THEN** `init.sh` SHALL create a minimal default `work.nix` there
- **AND** print a message confirming the file was created

#### Scenario: work.nix left untouched when already present
- **WHEN** `~/.config/darwin-secrets/work.nix` already exists
- **THEN** `init.sh` SHALL NOT overwrite it, and SHALL print a message noting
  it already exists

### Requirement: init.sh auto-detects and applies corporate certs during bootstrap
Before running the bootstrap `darwin-rebuild switch` command, `init.sh` SHALL
check `~/.config/darwin-secrets/` for any `.crt`/`.pem` files. If one or more
are found, it SHALL concatenate them into a single temporary bundle file
(made world-readable via `chmod 644`, since the bootstrap command itself runs
under `sudo` as root and must be able to read the bundle) and export
`NIX_SSL_CERT_FILE`, `SSL_CERT_FILE`, and `CURL_CA_BUNDLE` pointing at that
bundle, scoped only to the environment of the bootstrap command's child
process.

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

### Requirement: Bootstrap's darwin-rebuild switch runs under sudo with certs forwarded
`nix-darwin` requires system activation to run as root. `init.sh` SHALL
therefore invoke the bootstrap `darwin-rebuild switch` step via `sudo`,
explicitly forwarding `HOME` and the three cert-related environment variables
(`NIX_SSL_CERT_FILE`, `SSL_CERT_FILE`, `CURL_CA_BUNDLE`) as `sudo VAR=value`
prefixes on the command itself (not `sudo -E`), since `sudo -E`/`--preserve-env`
is not reliably honored under a restrictive `sudoers` `env_reset` policy,
whereas `sudo VAR=value cmd` always is. The command SHALL also pass
`--flake "$SCRIPT_DIR/nix" --impure` to `switch`, matching the `Justfile`'s
`deploy` recipe, since `darwin-rebuild switch` without an explicit `--flake`
target falls back to legacy `NIX_PATH`/channel-based resolution (looking for
`<darwin>`), which fails in this flake-only repository.

#### Scenario: Bootstrap switch runs as root with certs trusted
- **WHEN** `./init.sh --bootstrap` runs as a non-root user with corporate
  certs discovered by `with_bootstrap_certs`
- **THEN** the `darwin-rebuild switch` command SHALL be invoked via `sudo`
  with `HOME`, `NIX_SSL_CERT_FILE`, `SSL_CERT_FILE`, and `CURL_CA_BUNDLE`
  explicitly forwarded as env-var prefixes to the `sudo` invocation
- **AND** `--flake "$SCRIPT_DIR/nix" --impure` SHALL be passed to `switch`

#### Scenario: Script itself is not run with sudo
- **WHEN** the user runs `./init.sh --bootstrap` (no `sudo` prefix on the
  script invocation)
- **THEN** cert discovery and `$HOME`-dependent logic SHALL run correctly as
  the invoking user
- **AND** only the final `darwin-rebuild switch` step SHALL escalate via
  `sudo`, prompting for a password at that point
