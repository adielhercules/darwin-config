## MODIFIED Requirements

### Requirement: init.sh accepts --deploy flag
`init.sh` SHALL accept a `--deploy` flag that runs `just deploy` (which
resolves the deploy target profile automatically from the machine's
hostname via `hostProfiles` in `nix/darwin/default.nix` — no explicit
profile argument is needed). This stage SHALL require a non-empty
`.local/git-email` file (see `git-email-config` capability), exiting
non-zero with guidance if it is missing, before invoking `just deploy`.

#### Scenario: --deploy flag runs just deploy
- **WHEN** user runs `init.sh --deploy` with `.local/git-email` already set
- **THEN** `just deploy` SHALL be invoked, which resolves and deploys the
  profile matching the current machine's hostname

#### Scenario: --deploy blocked without git email set
- **WHEN** user runs `init.sh --deploy` and `.local/git-email` is missing or
  empty
- **THEN** the script SHALL exit non-zero before invoking `just deploy`,
  printing guidance to run `./init.sh --email you@example.com` first

## ADDED Requirements

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

## REMOVED Requirements

### Requirement: init.sh accepts --personal flag
**Reason**: Superseded by hostname-based automatic profile selection
(`hostProfiles` map in `nix/darwin/default.nix`). There is no explicit
per-invocation profile selection flag in the current implementation;
`init.sh`/`just deploy` always resolve the profile from the current
machine's hostname.
**Migration**: No action needed — profile selection is automatic. To deploy
a specific profile, run the deploy from a machine whose hostname is mapped
to that profile in `hostProfiles`.

### Requirement: init.sh accepts --work flag
**Reason**: Same as `--personal` above — superseded by hostname-based
automatic profile selection.
**Migration**: No action needed — profile selection is automatic based on
hostname.

### Requirement: init.sh --deploy flag is a stub that always fails
**Reason**: This described an earlier design where profile-less deploys were
unsupported. The current implementation has hostname-based profile
auto-resolution, so `--deploy` is a fully functional stage (see the
`MODIFIED` `--deploy` requirement above), not a stub.
**Migration**: No action needed; use `init.sh --deploy` or `just deploy`
directly.
