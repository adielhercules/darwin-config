### Requirement: git user.name hardcoded identically across profiles
`nix/modules/home/git-personal.nix` and `nix/modules/home/git-work.nix` SHALL
both set `programs.git.settings.user.name` to the literal string
`"Adiel Hercules"`.

#### Scenario: Name identical in both profiles
- **WHEN** either the personal or work profile is deployed
- **THEN** the resulting git config SHALL contain `user.name = "Adiel Hercules"`

### Requirement: git user.email sourced from local gitignored file
Both `git-personal.nix` and `git-work.nix` SHALL source
`programs.git.settings.user.email` from a shared helper
(`nix/lib/git-email.nix`) that reads and trims the contents of
`${rootPath}/.local/git-email`. This file SHALL NOT be committed to version
control (covered by a root `.gitignore` entry for `.local/`).

#### Scenario: Email file present
- **WHEN** `.local/git-email` exists and contains `me@example.com`
- **THEN** the resulting git config SHALL contain `user.email = "me@example.com"`
  for whichever profile is deployed

#### Scenario: Email file missing
- **WHEN** `.local/git-email` does not exist at evaluation time
- **THEN** evaluation SHALL abort with a clear error message instructing the
  user to run `./init.sh --email you@example.com`

### Requirement: init.sh --email flag sets the local git email file
`init.sh` SHALL accept an `--email <address>` argument, usable standalone or
combined with any other stage flag in the same invocation, that writes the
given address (trimmed, no trailing newline) to `.local/git-email`,
creating the `.local/` directory if needed and setting file permissions to
`600`.

#### Scenario: Standalone --email invocation
- **WHEN** user runs `./init.sh --email me@example.com`
- **THEN** `.local/git-email` SHALL be created/overwritten containing
  `me@example.com`
- **AND** no other stage (bootstrap/deploy/paths/git) SHALL run

#### Scenario: --email combined with another stage flag
- **WHEN** user runs `./init.sh --all --email me@example.com` or
  `./init.sh --deploy --email me@example.com`
- **THEN** `.local/git-email` SHALL be written first
- **AND** the requested stage(s) SHALL then proceed using that value

### Requirement: init.sh requires git email before bootstrap/deploy stages
`init.sh` SHALL check that `.local/git-email` exists and is non-empty before
running its bootstrap or deploy stages, exiting non-zero with a clear
message directing the user to `./init.sh --email you@example.com` if it is
missing or empty.

#### Scenario: Bootstrap blocked without email file
- **WHEN** user runs `./init.sh --bootstrap` (or `--all`) and
  `.local/git-email` does not exist or is empty
- **THEN** the script SHALL exit non-zero before invoking any `nix`/
  `darwin-rebuild` command
- **AND** it SHALL print an error directing the user to set the email first

#### Scenario: Deploy blocked without email file
- **WHEN** user runs `./init.sh --deploy` and `.local/git-email` does not
  exist or is empty
- **THEN** the script SHALL exit non-zero before invoking `just deploy`
- **AND** it SHALL print an error directing the user to set the email first

#### Scenario: Bootstrap/deploy proceed with email file present
- **WHEN** user runs `./init.sh --bootstrap` or `./init.sh --deploy` and
  `.local/git-email` exists and is non-empty
- **THEN** the corresponding stage SHALL proceed normally
