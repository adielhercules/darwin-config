## ADDED Requirements

### Requirement: AeroSpace hotkey group visible only when AeroSpace is active
Tuna's `a` (Aerospace) top-level hotkey group SHALL be present in the deployed Tuna configuration only when `lcars.wm.active == "aerospace"`, using the same sentinel-marker line-filter mechanism as the `y` group (see the `yabai-tuna-hotkeys` capability).

#### Scenario: aerospace group hidden by default
- **WHEN** `lcars.wm.active` is `"yabai"` (the default)
- **THEN** the rendered Tuna config contains zero `[[comboMode.bindings]]` entries with `key = 'a'`

#### Scenario: aerospace group shown when active
- **WHEN** `lcars.wm.active` is `"aerospace"`
- **THEN** the rendered Tuna config contains exactly one entry with `key = 'a'`, and zero entries with `key = 'y'`

### Requirement: AeroSpace commands use absolute binary paths
Every `aerospace` command invoked from a Tuna binding SHALL be prefixed with the absolute path to the AeroSpace binary (`/etc/profiles/per-user/<user>/bin/aerospace`, using the existing `<user>` build-time templating token), for the same reason as yabai's equivalent requirement — Tuna's restricted process PATH does not include the home-manager per-user profile directory.

#### Scenario: A workspace-switch binding succeeds under Tuna's restricted PATH
- **WHEN** a Tuna `a` group binding invoking the fully-qualified `aerospace` path is run in an environment with only `/usr/bin:/bin:/usr/sbin:/sbin` on `$PATH`
- **THEN** the command succeeds

### Requirement: AeroSpace's own workspace scheme is left unchanged
Unlike yabai, AeroSpace's workspace letters (`B`/`C`/`D`/`T`/`M`, plus work-only `F`) SHALL NOT be renumbered to match yabai's `deskN` scheme, since AeroSpace workspaces are a virtual/emulated concept (inactive-workspace windows are moved off-screen, not placed on distinct real macOS Spaces) and cannot be made to correspond to real Mission Control desktops regardless of naming.

#### Scenario: AeroSpace letters remain in the `a` group's bindings
- **WHEN** the `a` group is active and rendered
- **THEN** its bindings still reference the original `B`/`C`/`D`/`T`/`M`/`F` letters, not `desk1`-`desk6`
