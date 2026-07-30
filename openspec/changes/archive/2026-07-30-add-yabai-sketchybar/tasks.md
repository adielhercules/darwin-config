## 1. Yabai core module

- [x] 1.1 Create `nix/modules/home/yabai/default.nix` enabling `services.yabai` (package `pkgs.yabai`), `stack` layout, gaps/padding matching aerospace (`inner 20/20`, `outer 64`)
- [x] 1.2 Add global window rules/behavior config (mouse mode, window shadow/animation, etc.) via `services.yabai.config`
- [x] 1.3 Add space labels matching AeroSpace workspaces (`B`, `C`, `D`, `T`, `M`) via `extraConfig`/generated shell rules
- [x] 1.4 Add app-routing rules mirroring `aerospace/main.toml`'s `on-window-detected` (Ghostty→T, Xcode/Android Studio/VSCode→C, Music→M, browser→B, catch-all→floating or default space)
- [x] 1.5 Add monitor assignment mirroring `[workspace-to-monitor-force-assignment]` (`B/C/D/T`→secondary, `M`→main)
- [x] 1.6 ~~Configure yabai to start paused (disabled) by default at login~~ — superseded by section 8's build-time `lcars.wm.active` flag: exactly one of yabai/AeroSpace is ever `enable`d at deploy time, so there is no "paused at login" state to configure at all. No longer applicable.

## 2. Yabai work-profile overrides

- [x] 2.1 Create `nix/modules/home/yabai/work.nix` (or equivalent profile-merge mechanism) adding the `F` workspace + Teams/Outlook/Edge routing rules, mirroring `aerospace/work.toml`
- [x] 2.2 Wire profile selection using the existing `resolveModule`/`profile` convention

## 3. Scripting Addition (SA)

- [x] 3.1 Add declarative sudoers NOPASSWD entry for `yabai --load-sa` (nix-darwin system-level option) — handled automatically by nix-darwin's own `services.yabai.enableScriptingAddition` option (no manual sudoers stanza needed; see comment in `nix/modules/darwin/yabai/default.nix`)
- [x] 3.2 Wire SA load into yabai's startup (`yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"` + initial load) — handled automatically by nix-darwin's `launchd.daemons.yabai-sa` (RunAtLoad) when `enableScriptingAddition = true`
- [x] 3.3 Document the SIP-partial-disable prerequisite in a comment (out of scope to automate) — confirmed live this prerequisite is NOT met on the primary dev machine (`csrutil status` → SIP fully enabled), so SA-dependent features (e.g. `yabai -m space --create`) currently fail there; this is a known, accepted limitation, not a bug.

## 4. Mutual-exclusivity `wm-switch` helper — SUPERSEDED, fully removed (see section 8)

> Everything in this section describes work that was implemented, deployed, found to have a real bug in production (see design.md "Decision 3 revision"), and was **ultimately deleted entirely** once section 8's build-time `lcars.wm.active` flag replaced runtime pause/resume as the exclusivity mechanism. Kept here only as historical record of the investigation; `nix/modules/home/wm-switch.nix` no longer exists in the repo.

- [x] 4.1 Inspected/confirmed the launchd labels for both WMs (`org.nixos.yabai`, `org.nix-community.home.aerospace`, both `gui/$(id -u)` user agents) — this information remained useful/correct even after `wm-switch` itself was removed (referenced later by `launchctl kickstart` in the Tuna "Reload config" binding).
- [x] 4.2 Wrote `wm-switch` (`launchctl bootout`/`bootstrap`+`kickstart` symmetry, after an initial `aerospace enable off/on` version broke `just deploy` — see design.md). **Deleted in section 8.6.**
- [x] 4.3 Wired both WMs to start paused at login via AeroSpace's `after-startup-command`. **Removed in section 8.8** — build-time exclusivity means there's nothing to pause at login at all.

## 5. Tuna hotkey duplication

- [x] 5.1 Draft the full `key = 'y'` (Yabai) `[[comboMode.bindings]]` block in `config.shared.toml`, translating each existing `key='a'` child's `aerospace <cmd>` action to the yabai equivalent
- [x] 5.2 ~~Add `pause`/`start` children (calling `wm-switch yabai pause|start`) to the new `y` group~~ — **removed in section 8.13** along with all of `wm-switch`.
- [x] 5.3 ~~Add `pause`/`start` children to the existing `a` group~~ — **removed in section 8.13**.
- [x] 5.4 Apply the same additions to `personal/config.toml`
- [x] 5.5 Apply the same additions to `work/config.toml` (plus work-only `F`-workspace equivalents mirroring the existing `k`/`K` aerospace bindings)
- [x] 5.6 Manually verify a representative subset of yabai bindings after deploy — **confirmed by the user** across several real-deploy test sessions (workspace switches, focus, layout, resize, stack, etc. all working after the section 12 PATH/startup-race fixes).

## 6. Wire into darwin config

- [x] 6.1 Add yabai module import to `nix/darwin/home.nix`

  Note: the yabai module is a `services.yabai` (nix-darwin **system-level**)
  module, not a home-manager program, so it was actually wired into
  `nix/darwin/default.nix`'s system `modules` list as
  `../modules/darwin/yabai` (at `nix/modules/darwin/yabai/default.nix`),
  not `home.nix`. See design.md Decision 1 / proposal.md's `services.yabai`
  note.
- [x] 6.2 Add sudoers stanza to the appropriate nix-darwin system module — not needed as a separate stanza; `enableScriptingAddition = true` on `nix/modules/darwin/yabai/default.nix` triggers nix-darwin's own built-in sudoers wiring (see 3.1)

## 7. Validation

- [x] 7.1 `git add nix/`
- [x] 7.2 `nix flake check --no-build ./nix`
- [x] 7.3 `nix fmt`
- [x] 7.4 `deadnix --fail .`
- [x] 7.5 `statix check .`
- [ ] 7.6 `just check` — intentionally never run by the AI agent (requires sudo, per repo rules); run manually whenever desired. Not required — real `just deploy` runs have already validated the config multiple times across this change.

## 8. Redesign (v2): build-time WM selection, replacing `wm-switch`

- [x] 8.1 Create `nix/options/wm.nix` declaring `options.lcars.wm.active` (`enum ["yabai" "aerospace"]`, default `"yabai"`)
- [x] 8.2 Register the new option file in `nix/options/default.nix`'s imports list
- [x] 8.3 Set/confirm the default in `nix/features.nix` (`lcars.wm.active = "yabai";`, or rely on the option default)
- [x] 8.4 Gate `services.yabai.enable` on `lcars.wm.active == "yabai"` in `nix/modules/darwin/yabai/default.nix`
- [x] 8.5 Gate `programs.aerospace.enable`/`launchd.enable` on `lcars.wm.active == "aerospace"` in `nix/modules/home/aerospace/default.nix`
- [x] 8.6 Delete `nix/modules/home/wm-switch.nix`
- [x] 8.7 Remove the `wm-switch` import from `nix/darwin/home.nix`
- [x] 8.8 Remove `after-startup-command = ['exec-and-forget wm-switch yabai pause']` and its rationale comments from `nix/modules/home/aerospace/main.toml`
- [x] 8.9 Remove/reword stale `wm-switch`-related rationale comments in `nix/modules/darwin/yabai/default.nix` and `nix/modules/home/aerospace/default.nix` (keep the `onChange` override itself, reworded to stand on its own merit)
- [x] 8.10 Renumber yabai workspaces `B/C/D/T/M` → `desk1..desk5` and work-only `F` → `desk6` in `nix/modules/darwin/yabai/default.nix` and `work.nix` (space labels + app-routing rules)
- [x] 8.11 Tighten yabai gaps: `window_gap = 2`, `top_padding = 8`, `bottom_padding = 8`, `left_padding = 8`, `right_padding = 8`
- [x] 8.12 Add sentinel markers (`# WM-GROUP-BEGIN:aerospace` / `# WM-GROUP-END:aerospace`, same for `yabai`) around the `a` and `y` groups in `config.shared.toml`, `personal/config.toml`, `work/config.toml`
- [x] 8.13 Remove the Pause/Start (`x`/`o` key) children from both groups in all 3 Tuna files
- [x] 8.14 Update the `y` (Yabai) Tuna group's bindings to reference `desk1..desk6` instead of `B/C/D/T/M/F` in all 3 files
- [x] 8.15 Add line-filter logic to `nix/modules/home/tuna/default.nix` (`lib.splitString "\n"` + fold, driven by `lcars.wm.active`) that strips the inactive WM's sentinel-marked block, applied after the existing `<user>` substitution
- [x] 8.16 Re-run full validation sequence (section 7)
- [x] 8.17 Manually verify (user, post-deploy): yabai enabled by default with `desk1..desk6` labels and correct app routing, only the `y` Tuna group visible — **confirmed working by the user** after real deploys (including the desk remapping in section 11 and the PATH/startup fixes in section 12). Flipping to `"aerospace"` was verified at the Nix-eval level (both `services.yabai.enable=false`/`programs.aerospace.enable=true` and the Tuna group-hiding logic were confirmed via `nix eval` for both flag values) but not deployed/physically tested by the user, since yabai has remained the daily-driver choice throughout this change.

## 9. Yabai monitor assignment + expanded Tuna bindings

- [x] 9.1 Uncomment/activate the monitor-assignment block in `nix/modules/darwin/yabai/default.nix`: `desk2`/`desk5` → display 1 (built-in 1728x1117, confirmed primary), `desk1`/`desk3`/`desk4` → display 2 (2560x1440 external, confirmed secondary), per a live `yabai -m query --displays` on this machine (later superseded by section 11's desk remapping — see that section's table for the final assignment)
- [x] 9.2 Add `desk6` (work-only Focus) → display 2 in `nix/modules/darwin/yabai/work.nix` (later moved to be shared, see section 11)
- [x] 9.3 Expand the `y` (Yabai) Tuna group identically in `config.shared.toml`, `personal/config.toml`, `work/config.toml`:
  - Relabel `y l f` to `'Floating (window)'`
  - `y l` (Layout): add `o` (Floating space), `r` (Rotate 90/180/270 submenu), `m` (Mirror x/y submenu), `b` (Balance), `e` (Equalize), `s` (Toggle split)
  - Convert `y r` from a single leaf into a `Resize` submenu: `r`/`R`/`l`/`L`/`u`/`U`/`d`/`D` grow/shrink in all 4 directions, `+`/`-` ratio
  - New `y x` (Stack) submenu: `l`/`r`/`d`/`u` (west/east/south/north) — `x` used instead of `k` since `k` is already taken at the top level by the work profile's "Focus (work)" binding
  - `y e` (Focus window): add `n` (stack next), `p` (stack prev)
  - New top-level `y n` (Native fullscreen toggle)
  - New `y w` (Window toggles) submenu: sticky/pip/shadow/minimize/deminimize/opacity(submenu)/scratchpad assign+recover/raise/lower
  - New `y p` (Placement/Grid) submenu: left/right/top/bottom half, maximize
  - New top-level `y N` (Space management) submenu: create/destroy space
  - New top-level `y O` (Order spaces) submenu: move/swap/switch prev+next
- [x] 9.4 Audit all top-level keys in the `y` group post-change for uniqueness (personal/shared: 24 unique of 24; work: 25 unique of 25 — includes the work-only `k`)
- [x] 9.5 Re-run full validation sequence (section 7) plus a TOML-parse sanity check of the rendered `home.file."Library/Application Support/Tuna/config.toml".text` via `nix-instantiate --eval --expr 'builtins.fromTOML (builtins.readFile ...)'`

## 10. Sketchybar (last step, per original plan)

- [x] 10.1 Create `nix/modules/home/sketchybar/default.nix` enabling `programs.sketchybar` (bash `configType`, directory-`source` config; `extraPackages` includes `pkgs.jq` plus the active WM's package — see 12.3 for why the latter was needed). Confirmed from the actual home-manager `modules/programs/sketchybar.nix` source (pinned rev `3cd22efe...`) that a directory `config.source` (with `recursive = true`) must contain an entrypoint file named literally `sketchybarrc` (no extension).
- [x] 10.2 Generate `colors.sh` (via `pkgs.writeText`) from `config.lib.stylix.colors` using `config.lib.stylix.mkOpacityHexColor <color> 1.0` (8-digit `0xAARRGGBB`, required by sketchybar's `color=` flags). Palette: `COLOR_BG` (base00), `COLOR_FG` (base05), `COLOR_ACCENT` (base0D), `COLOR_ITEM_BG` (base01, used for the island-style pill backgrounds — see 12.6).
- [x] 10.3 Implemented a Nix-templated `workspace.sh` (per `lcars.wm.active`) rather than a runtime-WM-detecting script: yabai branch queries `yabai -m query --spaces --space | jq -r '.label'`; AeroSpace branch queries `aerospace list-workspaces --focused`. Name mapping was originally short codes, later changed to long names (see 12.1).
- [x] 10.4 Added clock, battery, wifi items (right side, ordered wifi/battery/clock to mirror native macOS menu-bar ordering) — label-only (no icon glyphs, see note below); wifi's underlying command was later fixed (see 12.7).
- [x] 10.5 Wired yabai (`external_bar`, `space_changed` signal — later also `window_focused`, see 12.2) and AeroSpace (`exec-on-workspace-change`) to trigger sketchybar refresh events. `sketchybarrc` registers both custom events unconditionally and subscribes the workspace item to both.
- [x] 10.6 Wired `../modules/home/sketchybar` into `nix/darwin/home.nix`'s `imports`.
- [x] 10.7 Re-ran full validation sequence (section 7).

  **Icon deferral**: SF Symbols/SF Pro private-use-area codepoints for
  battery-level and charging glyphs could not be confidently verified
  during this change, so battery/wifi items are **label-only**
  (`icon.drawing=off`) — battery shows the percentage plus a plain, safe
  unicode bolt (⚡, U+26A1) when charging; wifi shows the SSID or "Offline".
  Revisit with visual verification if icon glyphs are wanted later.

  **File layout**: `nix/modules/home/sketchybar/{default.nix,
  sketchybarrc.sh, plugins/{battery,wifi,clock}.sh}`. `default.nix` builds
  a `pkgs.runCommand "sketchybar-config"` directory merging the static
  files with two generated files (`colors.sh`, `plugins/workspace.sh`),
  wired via `programs.sketchybar.config = { source = ...; recursive = true; }`.

## 11. Desk remapping: Communications/desk1, Browsing/desk6

Renumbered desk meanings so Communications (Teams/Outlook, work-only) sits on
the primary display and Browsing (Dia, and Edge work-only) moves off desk1
onto the now-shared desk6. **This is the final/current desk scheme**,
superseding section 9's original assignment:

| Desk | Meaning | Apps routed | Monitor |
|---|---|---|---|
| desk1 | Communications | Teams, Outlook (work-only, via work.nix) | Primary (display 1) |
| desk2 | IDE | Xcode, Android Studio, VSCode | Secondary (display 2) |
| desk3 | Dev | none explicit (Simulator floats via `manage=off`) | Secondary |
| desk4 | Terminal | Ghostty | Secondary |
| desk5 | Music | Music.app | Secondary |
| desk6 | Browsing | Dia, Edge (work-only) | Secondary |

- [x] 11.1 `nix/modules/darwin/yabai/default.nix`: add shared `yabai -m space 6 --label desk6` label alongside desk1-desk5 (desk6/Browsing now shared, not work-only); update the desk-mapping comment above the labels
- [x] 11.2 `nix/modules/darwin/yabai/default.nix`: change the `Dia` app-routing rule from `space=desk1` to `space=desk6`
- [x] 11.3 `nix/modules/darwin/yabai/default.nix`: update the monitor-assignment block — `desk1` → display 1 (primary, Communications), `desk2`/`desk3`/`desk4`/`desk5`/`desk6` → display 2 (secondary)
- [x] 11.4 `nix/modules/darwin/yabai/work.nix`: remove the (now-shared) `desk6` label and monitor-assignment lines; change Teams/Outlook rules from `space=desk6` to `space=desk1`; add a dedicated Edge rule targeting `space=desk6`
- [x] 11.5 Tuna (`config.shared.toml`, `personal/config.toml`, `work/config.toml`): retarget the `y` group's `c` (Communications) binding from `desk2`→`desk1`, `b` (Browsing) from `desk1`→`desk6`, `i` (IDE, was raw space `7`) → `desk2`; mirror the same retargeting in the `s w` (Send window to workspace) submenu's Communications/Browsing/IDE children (both plain and `+focus` variants)
- [x] 11.6 `work/config.toml` only: remove the redundant top-level `k`/`K` "Focus (work)" bindings and their `s w` submenu counterparts (superseded by `c`→`desk1`, now shared across profiles)
- [x] 11.7 Re-run full validation sequence (section 7) plus the TOML-parse sanity check on the rendered Tuna config for both `darwinConfigurations` (personal + work) — confirm no `k`/`K` keys remain in either

## 12. Live-session fixes (found and fixed across several real-deploy test/feedback cycles)

- [x] 12.1 **Long workspace names**: `nix/modules/home/sketchybar/default.nix`'s `workspaceShContent` — replaced short `com/ide/dev/term/music/browse` codes with long names (`Communications/IDE/Dev/Terminal/Music/Browsing`) in both the yabai (`desk1..desk6`) and aerospace (`B/C/D/T/M/F`) branches.
- [x] 12.2 **Bar not refreshing on app-focus change**: added a second yabai signal, `event=window_focused action="sketchybar --trigger yabai_space_change"`, alongside `space_changed` — the latter alone doesn't fire when switching focus between apps on different displays that each already show their own space (no actual space change occurs, only a focus change).
- [x] 12.3 **Main fix — Tuna's broken PATH**: Tuna's GUI-process PATH (`/usr/bin:/bin:/usr/sbin:/sbin`, confirmed via `ps eww <PID>`) doesn't include where `yabai` (`/run/current-system/sw/bin/yabai`) or `aerospace` (`/etc/profiles/per-user/<user>/bin/aerospace`) live, so every bare `yabai`/`aerospace` command invoked via Tuna silently failed. Fixed in all three Tuna files by prefixing every `yabai `/`aerospace ` invocation in the `y`/`a` groups with its absolute path (including both halves of compound `&&`/`||` commands), reusing the existing `<user>` templating token for aerospace's path. Also added the active WM's package to `programs.sketchybar.extraPackages` (`default.nix`, section 10.1) since sketchybar's own launchd agent has the identical PATH problem for its `workspace.sh` plugin script. Verified via `grep` (0 remaining bare occurrences) and a live test under Tuna's exact restricted PATH (`env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin ... /run/current-system/sw/bin/yabai -m space --focus desk1` succeeded).
- [x] 12.4 **Auto-create-Spaces loop: added, found to break yabai's startup, removed**. An initial attempt added a bash loop to `nix/modules/darwin/yabai/default.nix`'s `extraConfig` that counted existing Spaces (`yabai -m query --spaces | grep -c '"index":'`, deliberately avoiding `jq` since it isn't guaranteed on yabai's launchd PATH) and ran `yabai -m space --create` until reaching `required_spaces=6`. **This broke yabai's own startup entirely** — confirmed live: after deploying it, `yabai -m rule --list` returned `[]` and all space labels were blank, meaning execution never reached the labeling/rules/monitor-assignment lines below the loop. Root cause: calling `yabai -m query` (a full IPC request/response round-trip) from *within* yabai's own synchronously-executing `-c` startup script is racy/unsafe — yabai's internal message-passing server may not be ready yet at that point, even though the same daemon answers the identical query fine moments later once fully up. **Final state: the loop was removed entirely**; creating the 6th Space (or any missing Spaces) is now a documented one-time **manual** step via Mission Control (or `yabai -m space --create` run from a normal interactive shell — never from within yabairc). Also discovered along the way: SIP is fully enabled on the primary dev machine, so yabai's Scripting Addition can't load, and `--create` fails there regardless (`"cannot create space due to an error with the scripting-addition"`) — Mission Control's native UI doesn't require the SA at all, so it remains the recommended way to add Spaces.
- [x] 12.5 Re-ran the full validation sequence (section 7) after 12.1-12.4, plus rendered/validated the real Tuna config (TOML-parse sanity check, 0 bare occurrences), built and `bash -n`-checked the sketchybar config derivation, and confirmed via direct Nix eval that the auto-create loop's code was fully removed from the generated `yabairc` (only an explanatory comment about the removal remains).
- [x] 12.6 **Transparent/island bar style**: `nix/modules/home/sketchybar/sketchybarrc.sh` — bar background set fully transparent (`color=0x00000000`); every item given a capsule-shaped background pill (`background.corner_radius=11` on a 22px `background.height`, using `COLOR_ITEM_BG`) with small `padding_left/right=4` gaps between adjacent islands.
- [x] 12.7 **Wifi always showing "Offline"**: `networksetup -getairportnetwork en0` is unreliable on recent macOS (confirmed live: reported "not associated" even though `en0` had a valid IP and was the active default-route interface). Replaced with `ipconfig getsummary en0`'s `SSID :` line in `plugins/wifi.sh`, confirmed working live.
- [x] 12.8 **Secondary display not respecting bar height** (windows placed underneath/overlapping the bar): `yabai -m config external_bar main:28:0` only reserves top padding on the *main* display. Changed to `external_bar all:28:0` so every display reserves the space.
- [x] 12.9 **Workspace indicator showing a blank pill (no text)**: root-caused to a launchd startup race — sketchybar's one-time initial `sketchybar --trigger yabai_space_change` (added so the indicator populates on bar launch) can fire before yabai's own IPC socket is ready, since both are `RunAtLoad` launchd agents starting concurrently (confirmed via `sketchybar.err.log`: `"yabai-msg: failed to connect to socket.."`). Since the `workspace` item had `update_freq=0` (purely event-driven), a failed initial attempt left it blank indefinitely. Fixed by changing `update_freq` to `2` (small periodic poll, in addition to the existing `--subscribe` events) so it self-heals within a couple seconds even if the first attempt fails. Live-verified: manually cleared the label to simulate the bug, confirmed it self-healed (showed the correct desk name again) within the 2-second poll window.

**All fixes in this section have been confirmed working by the user after real `just deploy` runs.**
</content>
