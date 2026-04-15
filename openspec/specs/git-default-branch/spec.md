## ADDED Requirements

### Requirement: Default branch name configuration
Home-manager SHALL configure git's default branch name for new repositories via the `init.defaultBranch` configuration option set to `main`.

#### Scenario: New repository uses main as default branch
- **WHEN** a new git repository is initialized with `git init`
- **THEN** the default branch SHALL be named `main` instead of `master`

### Requirement: Configuration persistence
The git default branch configuration SHALL persist across home-manager activations and system restarts.

#### Scenario: Configuration persists after home-manager activation
- **WHEN** home-manager activation completes
- **THEN** `git config --global init.defaultBranch` SHALL return `main`

### Requirement: Global scope
The default branch configuration SHALL apply globally to all git repositories initialized on the system by the user.

#### Scenario: Configuration applies to all new repositories
- **WHEN** multiple new repositories are initialized at different locations
- **THEN** each new repository SHALL use `main` as the default branch
