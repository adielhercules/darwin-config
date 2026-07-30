## Why

AeroSpace is the only tiling window manager currently configured, driven entirely through Tuna (the leader-key hotkey app) since no native AeroSpace keybindings or skhd config exist. We want to add **yabai** as a second, fully-featured tiling window manager, and a minimal **sketchybar** status bar (last step) that shows whichever WM is active.

**Revision (v2)**: The original design used a runtime `wm-switch` helper to pause/resume yabai and AeroSpace via `launchctl`/`aerospace enable`, so both were always installed and toggled live. After real-world testing this proved too fragile/surprising (see design.md Decision 3 revision for the deploy-breaking bug this caused). The design is now **build-time exclusivity**: a single `lcars.wm.active` flag (`"yabai"` default | `"aerospace"`) determines which WM is enabled at all — no runtime pause/resume, no `wm-switch`. The inactive WM's Tuna hotkey group is also hidden from the config entirely. yabai's workspaces are additionally renumbered to match real macOS Spaces/Mission Control desktops (linkarzu-style `deskN` labels), since — per research — yabai's spaces already ARE real macOS Spaces, while AeroSpace's are a virtual/emulated concept that can't be mapped onto real desktops. AeroSpace's own config is left as-is (letters `B/C/D/T/M/F`) since renumbering it would be purely cosmetic.

## What Changes (v2 — current)

- `nix/options/wm.nix` (new): declares `lcars.wm.active` (`enum ["yabai" "aerospace"]`, default `"yabai"`), following the existing `lcars.shell.fish` pattern (threaded via `mkSpecialArgs` into both darwin-system and home-manager contexts with no extra plumbing)
- `nix/modules/darwin/yabai/default.nix`: `services.yabai.enable = lcars.wm.active == "yabai"`; workspaces renumbered from `B/C/D/T/M/F` to `desk1..desk6` (linkarzu-style, matching real macOS Space indices); gaps tightened to `window_gap = 2`, `*_padding = 8`
- `nix/modules/home/aerospace/default.nix`: `programs.aerospace.enable`/`launchd.enable = lcars.wm.active == "aerospace"`; otherwise unchanged (letters kept, monitor assignment stays commented out)
- **`nix/modules/home/wm-switch.nix` deleted entirely**, along with all its references (aerospace `after-startup-command`, Tuna Pause/Start children in both groups/all 3 files, related rationale comments)
- Tuna's inactive-WM group (`a` or `y`) is hidden at generation time via sentinel-comment markers (`# WM-GROUP-BEGIN:<wm>` / `# WM-GROUP-END:<wm>`) + a line-filter in `tuna/default.nix` driven by `lcars.wm.active` — preserves all other in-file comments/formatting (no `fromTOML`/re-serialize round-trip, which would silently drop them)
- The `y` (Yabai) Tuna group's bindings updated to reference the new `desk1..desk6` labels instead of letters

### What Changed (v1 — superseded, kept for history)

- Originally: both WMs installed, "paused" via a shared `wm-switch` helper (`launchctl bootout`/`bootstrap`+`kickstart`, `aerospace enable on/off`) invoked from new Pause/Start children added to both Tuna groups — see design.md for the full history and the deploy-breaking bug this caused.
- Sketchybar plan (last step, unchanged by this revision): `nix/modules/home/sketchybar.nix`, bash-based, Stylix-themed, minimal macOS-menu-bar-like layout (workspace indicator left, clock/battery/wifi right)

## Capabilities

### New Capabilities
- `wm-active-flag`: A build-time `lcars.wm.active` flag selecting exactly one of yabai/AeroSpace to be enabled, replacing runtime pause/resume
- `yabai-window-manager`: A declaratively configured yabai installation with real-macOS-Space-based `deskN` workspaces, app-routing rules, and SA enabled, gated on the flag
- `yabai-tuna-hotkeys`: A Tuna hotkey group (`key = 'y'`) providing workspace/window/layout commands for yabai's `deskN` scheme, shown only when yabai is active
- `sketchybar-status-bar`: A minimal, Stylix-themed sketchybar configuration showing a WM-agnostic workspace indicator plus clock/battery/wifi (unchanged, still last step)

### Modified Capabilities
- `aerospace-tuna-hotkeys`: The existing `key = 'a'` Tuna group is shown only when AeroSpace is active (via the sentinel-filter mechanism); its `pause`/`start` children are removed (no longer needed)

### Removed Capabilities
- `wm-switch-helper`: The runtime pause/resume mechanism is removed entirely, superseded by build-time exclusivity

## Impact

- **`nix/options/wm.nix`** (new): `lcars.wm.active` option declaration
- **`nix/options/default.nix`**: register the new option file
- **`nix/features.nix`**: set/confirm `lcars.wm.active` default
- **`nix/modules/darwin/yabai/default.nix`**: gate `services.yabai.enable` on the flag; renumber workspaces to `desk1..desk6`; tighten gaps (`window_gap=2`, `*_padding=8`)
- **`nix/modules/darwin/yabai/work.nix`**: renumber `F` workspace routing to `desk6`
- **`nix/modules/home/aerospace/default.nix`**: gate `programs.aerospace.enable`/`launchd.enable` on the flag
- **`nix/modules/home/aerospace/main.toml`**: remove `wm-switch`-related `after-startup-command` and rationale comments
- **`nix/modules/home/wm-switch.nix`**: deleted
- **`nix/darwin/home.nix`**: remove `wm-switch` import
- **`nix/modules/home/tuna/{config.shared.toml,personal/config.toml,work/config.toml}`**: add sentinel markers around both groups; remove Pause/Start children; update `y` group bindings to `desk1..desk6`
- **`nix/modules/home/tuna/default.nix`**: add line-filter logic driven by `lcars.wm.active`
- **`nix/modules/home/sketchybar.nix`** (new, last step, unchanged): bash-based sketchybar config + Stylix color generation + launchd wiring
- No breaking changes to AeroSpace's own behavior beyond flag-gating and `wm-switch` reference removal
