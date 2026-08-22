## Requirements

### Requirement: yabai enabled conditionally via the build-time WM flag
The system SHALL configure `services.yabai` (nix-darwin, `nix/modules/darwin/yabai/default.nix`) with `enable = lcars.wm.active == "yabai"`, using `pkgs.yabai`, `float` global layout, and `enableScriptingAddition = true` (which nix-darwin itself wires to a declarative sudoers NOPASSWD entry and a `launchd.daemons.yabai-sa` job — no manual sudoers stanza required).

#### Scenario: yabai enabled by default
- **WHEN** `lcars.wm.active` is `"yabai"` (the default)
- **THEN** yabai's launchd agent (`org.nixos.yabai`) is active with `float` layout, `mouse_follows_focus = off`, `window_gap = 2`, and `{top,bottom,left,right}_padding = 8`
- **AND** individual spaces can still be manually switched to `stack` or `bsp` later via `yabai -m space --layout <mode>` without affecting the global default

#### Scenario: Scripting Addition sudoers wired automatically
- **WHEN** `enableScriptingAddition = true`
- **THEN** a `sudoers.d/yabai` entry scoped to a sha256 hash of the yabai binary permits `yabai --load-sa` NOPASSWD, without any hand-authored sudoers configuration
- **AND** if SIP is not partially disabled on the host, the scripting addition fails to load — this is a documented, accepted host-level prerequisite, not something the Nix config can enforce

### Requirement: Six-desk workspace scheme mapped to real macOS Spaces
The system SHALL label yabai spaces 1 through 6 as `desk1` through `desk6`, matching real, numbered macOS Mission Control desktops (unlike AeroSpace's virtual workspace model). The scheme SHALL be: `desk1`=Communications, `desk2`=IDE, `desk3`=Dev, `desk4`=Terminal, `desk5`=Music, `desk6`=Browsing.

#### Scenario: Space labels applied on yabai start
- **WHEN** yabai starts (or restarts) with at least 6 macOS Spaces already existing
- **THEN** `yabai -m query --spaces` reports spaces 1-6 labeled `desk1`-`desk6` respectively

#### Scenario: Fewer than 6 Spaces exist
- **WHEN** fewer than 6 real macOS Spaces exist on the target machine
- **THEN** labeling of the missing desks fails (`"value 'deskN' is not a valid option for SPACE_SEL"`) until the user manually creates the missing Space(s) via Mission Control — this is a documented manual one-time step; auto-creation via a synchronous `yabai -m query`/`--create` loop inside yabai's own startup config was tried and found to break yabai's startup entirely (a query issued from within yabai's own synchronously-executing `-c` config script races against the daemon's own IPC readiness), so it is intentionally NOT implemented

### Requirement: App-routing rules with retroactive application
The system SHALL route specific applications to their assigned desk via `yabai -m rule --add app="..." space=deskN`, mirroring the app-routing intent of the existing AeroSpace configuration, and SHALL call `yabai -m rule --apply` after all rules are declared so the rules also apply to windows that were already open before yabai (re)started.

#### Scenario: Ghostty routes to Terminal
- **WHEN** Ghostty is launched (or was already running before yabai started)
- **THEN** its window ends up on `desk4` (Terminal) after `yabai -m rule --apply` runs

#### Scenario: Xcode, Android Studio, and VSCode route to IDE
- **WHEN** any of these three apps is running
- **THEN** their windows end up on `desk2` (IDE)

#### Scenario: Music routes to Music desk, Dia routes to Browsing
- **WHEN** Music.app or Dia is running
- **THEN** their windows end up on `desk5` (Music) and `desk6` (Browsing) respectively

#### Scenario: Simulator and Finder float by default
- **WHEN** Simulator or Finder windows are open
- **THEN** they are excluded from tiling (`manage=off`) and float freely, unaffected by whichever layout mode their current space uses, and are not assigned to any specific desk
- **AND** these explicit `manage=off` rules remain in place even though `float` is now the global layout, so Simulator/Finder still float if a given space's layout is later manually switched to `stack`/`bsp`

#### Scenario: Work-profile-only routing
- **WHEN** the work profile is deployed
- **THEN** Microsoft Teams and Outlook route to `desk1` (Communications) and Microsoft Edge routes to `desk6` (Browsing), in addition to the shared rules above

### Requirement: Monitor assignment
The system SHALL assign `desk1` (Communications) to the primary display and all other desks (`desk2`-`desk6`) to the secondary display, using explicit `yabai -m space deskN --display N` commands with display indices confirmed live via `yabai -m query --displays` on the target hardware.

#### Scenario: Communications on primary, everything else on secondary
- **WHEN** yabai starts with the monitor-assignment commands applied
- **THEN** `desk1` is on the primary display and `desk2`-`desk6` are on the secondary display

### Requirement: sketchybar integration
The system SHALL reserve top screen padding for sketchybar via `yabai -m config external_bar all:28:0` (applied to every display, not just the main one) and SHALL notify sketchybar to refresh its workspace indicator via `yabai -m signal` on both `space_changed` and `window_focused` events.

#### Scenario: Bar space reserved on all displays
- **WHEN** yabai is configured with `external_bar all:28:0`
- **THEN** tiled windows on both the primary and secondary displays leave room for a 28px top bar, with no window placed underneath/overlapping it

#### Scenario: Bar refreshes on both space change and app-focus change
- **WHEN** the user either switches the active macOS Space or focuses a different app/window (including across displays, where no actual space change occurs)
- **THEN** `sketchybar --trigger yabai_space_change` fires in both cases, keeping the workspace indicator in sync
