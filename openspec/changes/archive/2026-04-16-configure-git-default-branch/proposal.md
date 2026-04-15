## Why

Industry best practice has shifted from using `master` as the default branch name to `main`, improving inclusivity and clarity. This change aligns the local git configuration with modern standards, ensuring all new repositories default to `main` instead of requiring manual branch creation or renaming.

## What Changes

- Configure git's `init.defaultBranch` to `main` via home-manager
- Apply this setting globally for all new git repositories
- No impact on existing repositories - they retain their current default branch

## Capabilities

### New Capabilities
- `git-default-branch`: Configure git's default branch name globally through home-manager activation

### Modified Capabilities

## Impact

- Affects all new git repositories initialized on this system
- No impact on existing repositories
- Home-manager programs.git configuration
