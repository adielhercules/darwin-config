## ADDED Requirements

### Requirement: yabai hotkey group visible only when yabai is active
Tuna's `y` (Yabai) top-level hotkey group SHALL be present in the deployed Tuna configuration only when `lcars.wm.active == "yabai"`, achieved via sentinel-comment markers (`# WM-GROUP-BEGIN:yabai` / `# WM-GROUP-END:yabai`) around the group in each Tuna config file, stripped or kept by a line-based filter in `nix/modules/home/tuna/default.nix` driven by the flag — without a `fromTOML`/re-serialize round-trip, which would silently drop the files' hand-written comments.

#### Scenario: yabai group shown when yabai is active
- **WHEN** `lcars.wm.active` is `"yabai"` (the default) and the Tuna config is rendered
- **THEN** the rendered config contains exactly one `[[comboMode.bindings]]` entry with `key = 'y'`, and zero entries with `key = 'a'`

#### Scenario: yabai group hidden when aerospace is active
- **WHEN** `lcars.wm.active` is `"aerospace"` and the Tuna config is rendered
- **THEN** the rendered config contains zero entries with `key = 'y'`, and no stray `WM-GROUP` sentinel-marker lines remain anywhere in the output

### Requirement: All yabai commands use absolute binary paths
Every yabai command invoked from a Tuna binding SHALL be prefixed with the absolute path to the yabai binary (`/run/current-system/sw/bin/yabai`), including both halves of any compound (`&&`) command, since Tuna's own process PATH (`/usr/bin:/bin:/usr/sbin:/sbin`) does not include where yabai is installed.

#### Scenario: A workspace-focus binding succeeds under Tuna's restricted PATH
- **WHEN** a Tuna `y` group binding invoking `/run/current-system/sw/bin/yabai -m space --focus deskN` is run in an environment with only `/usr/bin:/bin:/usr/sbin:/sbin` on `$PATH`
- **THEN** the command succeeds and the target space is focused

#### Scenario: Compound commands are fully qualified
- **WHEN** a binding chains two yabai invocations with `&&` (e.g. move a window to a space and then focus that space)
- **THEN** both invocations are individually prefixed with the absolute yabai path, not just the first

### Requirement: Comprehensive yabai action coverage
The `y` group SHALL provide bindings covering: space focus (per-desk), directional window focus, join/warp, window swap, send-window-to-space (with focus variants), send-to-display, display focus, layout mode switching (bsp/stack/float, both space-level and window-level), rotate, mirror, balance, equalize, split toggle, resize (all four edges, grow and shrink, plus fine ratio nudging), window stacking and stack navigation, native and zoom fullscreen toggles, window toggles (sticky, pip, shadow, minimize/deminimize, opacity presets, scratchpad assign/recover, raise/lower), grid placement presets, space creation/destruction, and space reordering (move/swap/switch).

#### Scenario: No duplicate top-level keys
- **WHEN** the `y` group's full set of top-level keys is enumerated
- **THEN** every key is unique within the group (verified: 24 unique keys for the personal/shared profile, 25 for the work profile, which has one additional work-only key)
