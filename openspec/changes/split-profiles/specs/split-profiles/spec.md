## ADDED Requirements

### Requirement: Profile-based deployment via CLI argument
The system SHALL allow users to select a deployment profile (personal or work) explicitly via the --argstr profile <name> argument to nix-darwin at every deployment. There must be no automatic hostname detection or side-channel mechanism that overrides the user's explicit selection.

#### Scenario: Deploy personal profile from CLI
- WHEN the user runs darwin-rebuild switch --flake ".#" --argstr profile personal --impure
- THEN the configuration includes only personal-only brew casks, system packages, and module configurations (no work-specific entries)

#### Scenario: Deploy work profile from CLI
- WHEN the user runs darwin-rebuild switch --flake ".#" --argstr profile work --impure
- THEN the configuration includes only work-only brew casks, system packages, and module configurations (no personal-specific entries)

#### Scenario: Default profile is personal
- WHEN the user runs darwin-rebuild switch --flake ".#" --impure without specifying a profile
- THEN the configuration defaults to the personal profile

### Requirement: Shared default layer for all profiles
The system SHALL define a nix/darwin/profiles/defaults.nix module that contains all brew casks, system packages, and settings shared between personal and work machines. Per-profile modules merge on top via list-appending (no repetition of shared values).

#### Scenario: Defaults load first for personal
- WHEN deploying the personal profile
- THEN defaults.nix loads first, then personal.nix appends personal-only entries

#### Scenario: Defaults load first for work
- WHEN deploying the work profile
- THEN defaults.nix loads first, then work.nix appends work-only entries

### Requirement: Module path resolution with suffix pattern
The system SHALL resolve module file paths using a profile-aware resolver function that applies the following priority: (a) <module>.<profile>.<ext> if it exists, (b) fallback to <module>.<ext> shared base. Resolution logic lives in nix/lib/resolve-module.nix.

#### Scenario: Profile-specific module exists
- WHEN fish-personal.bindings exists alongside fish.config for profile=personal
- THEN the resolver returns fish-personal.bindings

#### Scenario: No profile-specific module, falls back to shared
- WHEN only ghostty.nix exists (no ghostty.personal.nix) for any profile
- THEN the resolver returns ghostty.nix unchanged

### Requirement: Aerospace config - shared base with per-profile diffs
The aerospace configuration SHALL use a directory structure where main.toml contains shared workspace rules that are identical between both machines, and personal.toml/work.toml contain only the differing sections to be applied on top.

#### Scenario: Shared main.toml loads for both profiles
- WHEN deploying either profile
- THEN aerospace/main.toml is always loaded as the base configuration

#### Scenario: Per-profile workspace overrides apply on shared base
- WHEN deploying work profile with work.toml containing different workspace names
- THEN the workspace name diffs from work.toml override the corresponding keys in main.toml

### Requirement: Tuna config - shared base module with near-duplicate profiles
The tuna configuration SHALL use a directory structure where default.nix contains the configurable logic (file symlinks, activation), a shared base config.toml captures 80%+ of settings, and per-profile full configs (personal/config.toml, work/config.toml) contain app combo differences (~20% of file).

#### Scenario: Shared tuna module loads with profile-specific config
- WHEN deploying personal profile
- THEN the tuna module reads tuna/personal/config.toml as the active configuration

#### Scenario: Work-specific tuna combo bindings apply
- WHEN deploying work profile
- THEN the work combo bindings replace/override the personal app targets in the tuna config

### Requirement: Fish shell - shared plugins with per-profile shell additions
The fish module SHALL share all plugins and base interactiveShellInit across profiles, while loading per-profile bindings files that add machine-specific aliases or corporate proxy settings.

#### Scenario: Shared fish modules always load
- WHEN deploying any profile
- THEN fish.config (base) with all shared plugin definitions loads without condition

### Requirement: Profile-specific shellInit additions load
- WHEN the personal profile is active
- THEN fish-personal.bindings appends personal-only aliases to interactiveShellInit

### Requirement: init.sh convenience helpers
The system SHALL provide deploy_personal and deploy_work functions in init.sh that pass the explicit --argstr profile <name> flag to nix-darwin. There must be no hostname-based detection mixed into these helpers.

#### Scenario: deploy_personal sets personal profile
- WHEN the user runs ./init.sh --personal or calls deploy_personal
- THEN darwin-rebuild switch --flake ".#" --argstr profile personal --impure is executed

#### Scenario: deploy_work sets work profile
- WHEN the user runs ./init.sh --work or calls deploy_work
- THEN darwin-rebuild switch --flake ".#" --argstr profile work --impure is executed
