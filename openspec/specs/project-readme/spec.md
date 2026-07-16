### Requirement: root README.md documents project purpose and prerequisites
The repository SHALL contain a root `README.md` describing what the project
is (a declarative Nix-Darwin macOS system configuration), and listing
prerequisites required before installation, including
[Lix](https://lix.systems/) with a brief note on why Lix specifically is
required (Lix-specific behavior relied on elsewhere in the repo, e.g.
`nix.enable = false` because Lix manages its own daemon).

#### Scenario: README exists and lists Lix prerequisite
- **WHEN** a new contributor opens the repository root
- **THEN** `README.md` SHALL exist
- **AND** it SHALL mention Lix as a required prerequisite with a link to
  https://lix.systems/

### Requirement: README documents first-time bootstrap steps
`README.md` SHALL document the first-time bootstrap sequence in order:
installing Lix, cloning the repo, setting the git email via
`./init.sh --email you@example.com`, the work-profile-only step of dropping
corporate certs into `~/.config/darwin-secrets/` before bootstrapping, running
`./init.sh` (or `./init.sh --all`), and finally `./init.sh --deploy` (or
`just deploy` once available).

#### Scenario: Bootstrap steps present and in order
- **WHEN** a new contributor follows `README.md`'s installation section
- **THEN** the steps SHALL appear in the order: install Lix, clone repo, set
  git email, (work only) drop certs, run `./init.sh`, run
  `./init.sh --deploy`

### Requirement: README clarifies just is not a prerequisite
`README.md` SHALL explicitly note that the `just` command runner is not a
prerequisite to install manually — it is installed automatically as part of
the system configuration during the first bootstrap.

#### Scenario: Just clarified as non-prerequisite
- **WHEN** a new contributor reads the prerequisites section
- **THEN** it SHALL state that `just` does not need to be installed manually
  beforehand

### Requirement: README documents day-to-day usage and profile system
`README.md` SHALL list common day-to-day `just` commands (`check`, `deploy`,
`verbose`, `up`, `update`, `list`, `tree`), note that destructive/system-
modifying commands require deliberate manual invocation, and explain the
`personal`/`work` profile system including hostname-based auto-selection and
the `~/.config/darwin-secrets/` convention for work-only secrets/certs.

#### Scenario: Day-to-day commands and profiles documented
- **WHEN** a contributor reads `README.md` past the installation section
- **THEN** it SHALL list the common `just` commands and describe the
  personal/work profile mechanism
