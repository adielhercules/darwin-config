# Spec: nix-warnings-cleanup

Eliminate all Nix/home-manager deprecation warnings produced during `darwin-rebuild switch` by updating formatter packages, overlay expressions, and explicit option declarations.

---

### Requirement: nixfmt replaces nixfmt-classic
The system SHALL use `nixfmt` (not `nixfmt-classic`) as the Nix formatter package in all home-manager package lists.

#### Scenario: nixfmt-classic is absent from home packages
- **WHEN** the darwin configuration is evaluated
- **THEN** `nixfmt-classic` SHALL NOT appear in any `home.packages` list

#### Scenario: nixfmt is present in home packages
- **WHEN** the darwin configuration is evaluated
- **THEN** `nixfmt` SHALL appear in `home.packages` in both `nix/darwin/home.nix` and `nix/modules/home/neovim.nix`

#### Scenario: No deprecation warning for nixfmt-classic
- **WHEN** `darwin-rebuild switch` is executed
- **THEN** no warning containing "nixfmt-classic is deprecated" SHALL appear in the output

---

### Requirement: stdenv.hostPlatform.system used in overlays
The system SHALL reference `stdenv.hostPlatform.system` instead of the deprecated `system` attribute in all nixpkgs overlay expressions.

#### Scenario: nixpkgs-unstable overlay uses canonical system attribute
- **WHEN** the nixpkgs-unstable overlay in `nix/darwin/default.nix` is evaluated
- **THEN** it SHALL use `final.stdenv.hostPlatform.system` (not `final.system`) when importing nixpkgs-unstable

#### Scenario: zjstatus package reference uses canonical system attribute
- **WHEN** the zjstatus package overlay expression in `nix/darwin/default.nix` is evaluated
- **THEN** it SHALL use `prev.stdenv.hostPlatform.system` (not `prev.system`) to look up the zjstatus package

#### Scenario: No deprecation warning for system attribute
- **WHEN** `darwin-rebuild switch` is executed
- **THEN** no warning containing "'system' has been renamed" SHALL appear in the output

---

### Requirement: Git signing format explicitly set
The home-manager git configuration SHALL explicitly declare `programs.git.signing.format = null` to adopt the new default and silence the migration warning.

#### Scenario: signing.format is declared in git config
- **WHEN** the home-manager configuration in `nix/darwin/home.nix` is evaluated
- **THEN** `programs.git.signing.format` SHALL be set to `null`

#### Scenario: No deprecation warning for git signing format
- **WHEN** `darwin-rebuild switch` is executed
- **THEN** no warning containing "programs.git.signing.format" SHALL appear in the output

---

### Requirement: GTK4 theme explicitly set to null
The home-manager configuration SHALL explicitly declare `gtk.gtk4.theme = null` to adopt the new default and silence the migration warning on this macOS-only setup.

#### Scenario: gtk.gtk4.theme is declared
- **WHEN** the home-manager configuration in `nix/darwin/home.nix` is evaluated
- **THEN** `gtk.gtk4.theme` SHALL be set to `null`

#### Scenario: No deprecation warning for gtk.gtk4.theme
- **WHEN** `darwin-rebuild switch` is executed
- **THEN** no warning containing "gtk.gtk4.theme" SHALL appear in the output

---

### Requirement: home.stateVersion bumped to 25.05
The home-manager state version SHALL be set to `"25.05"` to align with current release expectations and clear version-gated warnings.

#### Scenario: stateVersion is 25.05
- **WHEN** the home-manager configuration in `nix/darwin/home.nix` is evaluated
- **THEN** `home.stateVersion` SHALL equal `"25.05"`

#### Scenario: Clean deployment output
- **WHEN** `darwin-rebuild switch` is executed after all fixes are applied
- **THEN** none of the five warning classes (nixfmt-classic, system renamed, git signing format, gtk.gtk4.theme, stateVersion) SHALL appear in the output
