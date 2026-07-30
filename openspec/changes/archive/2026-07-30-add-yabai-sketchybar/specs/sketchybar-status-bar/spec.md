## ADDED Requirements

### Requirement: Minimal, transparent, island-style status bar
The system SHALL configure `programs.sketchybar` (home-manager, bash `configType`) with a fully transparent bar background and individual capsule-shaped "island" pills per item, Stylix-themed via `config.lib.stylix.colors`.

#### Scenario: Bar background is transparent
- **WHEN** sketchybar renders its bar
- **THEN** the bar itself uses `color=0x00000000` (fully transparent), with only each item's own pill background visible

#### Scenario: Items render as capsule-shaped islands with gaps
- **WHEN** any item (workspace, wifi, battery, clock) is drawn
- **THEN** it has a background pill with `corner_radius` equal to half its height (a full capsule shape), using the Stylix-derived `COLOR_ITEM_BG`, with a small transparent gap between adjacent islands via item-level padding

#### Scenario: Colors derive from the active Stylix theme
- **WHEN** the Stylix `base16Scheme` changes
- **THEN** sketchybar's generated `colors.sh` (background, foreground, accent, item-background) is regenerated to match, without manual sketchybar configuration changes

### Requirement: WM-agnostic, self-healing workspace indicator
The system SHALL show a left-aligned workspace indicator whose underlying query command is chosen at build time based on `lcars.wm.active` (no runtime WM detection), displaying the long-form desk/workspace name (e.g. "Communications", "IDE", "Browsing"). The indicator SHALL update both on WM-signaled events and via a small periodic poll, so that a failed initial query (due to a launchd startup race between sketchybar and the WM) self-heals within a few seconds rather than staying blank indefinitely.

#### Scenario: Correct WM query baked in at build time
- **WHEN** `lcars.wm.active` is `"yabai"`
- **THEN** the generated `workspace.sh` queries `yabai -m query --spaces --space | jq -r '.label'` and maps `desk1`-`desk6` to their long names
- **WHEN** `lcars.wm.active` is `"aerospace"`
- **THEN** the generated `workspace.sh` instead queries `aerospace list-workspaces --focused` and maps AeroSpace's own letters to long names

#### Scenario: Indicator self-heals from a startup race
- **WHEN** the workspace item's initial query fails (e.g. because yabai's IPC socket was not yet ready when sketchybar's launchd agent started)
- **THEN** the item's `update_freq=2` periodic poll re-attempts the query within a few seconds and successfully populates the label, without requiring a manual restart

#### Scenario: Indicator updates on both space change and app-focus change
- **WHEN** the active yabai signal (`space_changed` or `window_focused`) or AeroSpace's `exec-on-workspace-change` fires
- **THEN** the workspace indicator refreshes immediately, in addition to its periodic poll

### Requirement: Wifi, battery, and clock items
The system SHALL show wifi (SSID or "Offline"), battery (percentage, with a plain unicode charging indicator), and clock (day/date/time) items on the right side of the bar, in that left-to-right order (matching native macOS menu-bar ordering), using plain macOS CLI tools with no extra runtime dependencies beyond `jq` (for the workspace indicator's yabai-JSON parsing).

#### Scenario: Wifi shows the real SSID
- **WHEN** the machine is connected to Wi-Fi
- **THEN** the wifi item's label shows the actual SSID, obtained via `ipconfig getsummary en0`'s `SSID :` line (not `networksetup -getairportnetwork`, which was found to be unreliable on recent macOS and could report "not associated" even while genuinely connected)

#### Scenario: Battery shows percentage and charging state
- **WHEN** the machine is on AC power
- **THEN** the battery item's label appends a plain unicode bolt (⚡, U+26A1) to the percentage

#### Scenario: Icons deliberately omitted
- **WHEN** wifi/battery items are rendered
- **THEN** they are label-only (`icon.drawing=off`) — SF Symbols/SF Pro icon glyph codepoints were deliberately not hardcoded, since they could not be confidently verified, avoiding silently rendering incorrect/garbage glyphs
