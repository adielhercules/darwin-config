## MODIFIED Requirements

### Requirement: git user.email managed via imperative config.local
`git-personal.nix` and `git-work.nix` SHALL NOT set `programs.git.settings.user.email`. Instead, home-manager's `programs.git` SHALL include `~/.config/git/config.local` via `programs.git.includes`, and `init.sh --email` SHALL write a standard git config snippet to that file.

#### Scenario: config.local present
- **WHEN** `~/.config/git/config.local` exists with `[user] email = me@example.com`
- **THEN** the resulting git config SHALL contain `user.email = "me@example.com"` for whichever profile is deployed

#### Scenario: config.local missing
- **WHEN** `~/.config/git/config.local` does not exist
- **THEN** home-manager SHALL still evaluate successfully (git silently skips missing includes)
- **AND** `init.sh` SHALL block bootstrap/deploy until the file is created

### Requirement: init.sh --email flag writes git config.local
`init.sh` SHALL accept an `--email <address>` argument, usable standalone or combined with any other stage flag, that writes a standard git config snippet to `~/.config/git/config.local`, creating the directory if needed.

#### Scenario: Standalone --email invocation
- **WHEN** user runs `./init.sh --email me@example.com`
- **THEN** `~/.config/git/config.local` SHALL be created/overwritten containing:
  ```
  [user]
  	email = me@example.com
  ```
- **AND** no other stage (bootstrap/deploy/git) SHALL run

#### Scenario: --email combined with another stage flag
- **WHEN** user runs `./init.sh --all --email me@example.com` or `./init.sh --deploy --email me@example.com`
- **THEN** `~/.config/git/config.local` SHALL be written first
- **AND** the requested stage(s) SHALL then proceed using that value

### Requirement: init.sh requires git email before bootstrap/deploy stages
`init.sh` SHALL check that `~/.config/git/config.local` exists and is non-empty before running bootstrap or deploy stages, exiting non-zero with a clear message directing the user to `./init.sh --email you@example.com` if missing.

#### Scenario: Bootstrap blocked without config.local
- **WHEN** user runs `./init.sh --bootstrap` (or `--all`) and `~/.config/git/config.local` does not exist or is empty
- **THEN** the script SHALL exit non-zero before invoking any `nix`/`darwin-rebuild` command
- **AND** it SHALL print an error directing the user to set the email first

#### Scenario: Deploy blocked without config.local
- **WHEN** user runs `./init.sh --deploy` and `~/.config/git/config.local` does not exist or is empty
- **THEN** the script SHALL exit non-zero before invoking `just deploy`
- **AND** it SHALL print an error directing the user to set the email first

#### Scenario: Bootstrap/deploy proceed with config.local present
- **WHEN** user runs `./init.sh --bootstrap` or `./init.sh --deploy` and `~/.config/git/config.local` exists and is non-empty
- **THEN** the corresponding stage SHALL proceed normally
