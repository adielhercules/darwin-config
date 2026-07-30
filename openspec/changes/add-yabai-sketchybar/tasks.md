## 1. Yabai core module

- [x] 1.1 Create `nix/modules/home/yabai/default.nix` enabling `services.yabai` (package `pkgs.yabai`), `stack` layout, gaps/padding matching aerospace (`inner 20/20`, `outer 64`)
- [x] 1.2 Add global window rules/behavior config (mouse mode, window shadow/animation, etc.) via `services.yabai.config`
- [x] 1.3 Add space labels matching AeroSpace workspaces (`B`, `C`, `D`, `T`, `M`) via `extraConfig`/generated shell rules
- [x] 1.4 Add app-routing rules mirroring `aerospace/main.toml`'s `on-window-detected` (Ghostty→T, Xcode/Android Studio/VSCode→C, Music→M, browser→B, catch-all→floating or default space)
- [x] 1.5 Add monitor assignment mirroring `[workspace-to-monitor-force-assignment]` (`B/C/D/T`→secondary, `M`→main)
- [ ] 1.6 Configure yabai to start paused (disabled) by default at login (deferred — depends on the `wm-switch` helper in section 4, not implemented in this pass)

## 2. Yabai work-profile overrides

- [x] 2.1 Create `nix/modules/home/yabai/work.nix` (or equivalent profile-merge mechanism) adding the `F` workspace + Teams/Outlook/Edge routing rules, mirroring `aerospace/work.toml`
- [x] 2.2 Wire profile selection using the existing `resolveModule`/`profile` convention

## 3. Scripting Addition (SA)

- [x] 3.1 Add declarative sudoers NOPASSWD entry for `yabai --load-sa` (nix-darwin system-level option) — handled automatically by nix-darwin's own `services.yabai.enableScriptingAddition` option (no manual sudoers stanza needed; see comment in `nix/modules/darwin/yabai/default.nix`)
- [x] 3.2 Wire SA load into yabai's startup (`yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"` + initial load) — handled automatically by nix-darwin's `launchd.daemons.yabai-sa` (RunAtLoad) when `enableScriptingAddition = true`
- [x] 3.3 Document the SIP-partial-disable prerequisite in a comment (out of scope to automate)

## 4. Mutual-exclusivity `wm-switch` helper

- [x] 4.1 Inspect the actual nix-darwin-generated launchd label for the yabai service — resolved by reading nix-darwin's actual `modules/services/yabai/default.nix` source directly from the flake's `/nix/store` checkout (no deploy needed): yabai is `launchd.user.agents.yabai`, a **per-user** agent, labeled `org.nixos.yabai` (`launchd.labelPrefix` defaults to `org.nixos`; see `modules/launchd/default.nix`). Being a user agent (not a system daemon), it lives in the `gui/$(id -u)` domain and can be targeted with plain `launchctl` — no sudo required. AeroSpace's own launchd agent is labeled `org.nix-community.home.aerospace` (from home-manager's `programs.aerospace.launchd.enable`). Both labels/plist paths (`~/Library/LaunchAgents/<label>.plist`) were confirmed directly against the deployed system. See the comment in `nix/modules/home/wm-switch.nix`.
- [x] 4.2 Write `wm-switch` shell script (packaged via `pkgs.writeShellScriptBin`, wired into `home.packages` via `nix/modules/home/wm-switch.nix`) implementing `yabai start|pause` and `aerospace start|pause` mutual-exclusivity logic.
  - **Revised after a real deploy failure** (see design.md "Decision 3 revision"): the initial version used `aerospace enable off/on` as the pause primitive, which broke `just deploy` because home-manager's aerospace module runs a fatal, unconditional `aerospace reload-config` on any config-content change, and a disabled AeroSpace process rejects *all* commands including that reload. Fixed by switching both yabai and AeroSpace to symmetric `launchctl bootout` (pause) / `launchctl bootstrap` + `kickstart -k` (start) — a paused WM is now a fully stopped process for both, never a "running but rejecting commands" one. Also fixed a related latent bug: `kickstart -k` alone doesn't work after a `bootout` without a preceding `bootstrap`.
  - Defense-in-depth: `nix/modules/home/aerospace/default.nix` now overrides home-manager's fatal `onChange` reload hook with a `|| true`-guarded version, so this class of failure can't recur even if AeroSpace is left in an unexpected state.
- [x] 4.3 Wire both WMs to start paused at login — nix-darwin's `services.yabai` module has no "start paused" override (`RunAtLoad`/`KeepAlive` are hardcoded `true`), so this is achieved pragmatically via AeroSpace's `after-startup-command` (`nix/modules/home/aerospace/main.toml`) running `wm-switch yabai pause` directly as its first action (**not** `wm-switch aerospace start`, which was corrected — see design.md — since AeroSpace bootout+bootstrap-restarting itself from within its own already-running startup command would risk a self-restart loop). Documented in both `main.toml` and `nix/modules/darwin/yabai/default.nix`.

## 5. Tuna hotkey duplication

- [x] 5.1 Draft the full `key = 'y'` (Yabai) `[[comboMode.bindings]]` block in `config.shared.toml`, translating each existing `key='a'` child's `aerospace <cmd>` action to the yabai equivalent
- [x] 5.2 Add `pause`/`start` children (calling `wm-switch yabai pause|start`) to the new `y` group (keys `x`/`o`, since `p`/`s` were already taken)
- [x] 5.3 Add `pause`/`start` children (calling `wm-switch aerospace pause|start`) to the existing `a` group (same `x`/`o` keys, for consistency)
- [x] 5.4 Apply the same additions to `personal/config.toml`
- [x] 5.5 Apply the same additions to `work/config.toml` (plus work-only `F`-workspace equivalents mirroring the existing `k`/`K` aerospace bindings)
- [ ] 5.6 Manually verify a representative subset of yabai bindings (workspace switch, focus, layout toggle, resize, join) after deploy — deferred to the user, requires an actual deploy + physical keypresses

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
- [ ] 7.6 `just check` only on explicit user request

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
- [ ] 8.17 Manually verify (user, post-deploy): yabai enabled by default with `desk1..desk6` labels and correct app routing, only the `y` Tuna group visible; flipping `lcars.wm.active` to `"aerospace"` and redeploying switches cleanly with only the `a` group visible

## 10. Yabai monitor assignment + expanded Tuna bindings

- [x] 10.1 Uncomment/activate the monitor-assignment block in `nix/modules/darwin/yabai/default.nix`: `desk2`/`desk5` → display 1 (built-in 1728x1117, confirmed primary), `desk1`/`desk3`/`desk4` → display 2 (2560x1440 external, confirmed secondary), per a live `yabai -m query --displays` on this machine
- [x] 10.2 Add `desk6` (work-only Focus) → display 2 in `nix/modules/darwin/yabai/work.nix`
- [x] 10.3 Expand the `y` (Yabai) Tuna group identically in `config.shared.toml`, `personal/config.toml`, `work/config.toml`:
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
- [x] 10.4 Audit all top-level keys in the `y` group post-change for uniqueness (personal/shared: 24 unique of 24; work: 25 unique of 25 — includes the work-only `k`)
- [x] 10.5 Re-run full validation sequence (section 7) plus a TOML-parse sanity check of the rendered `home.file."Library/Application Support/Tuna/config.toml".text` via `nix-instantiate --eval --expr 'builtins.fromTOML (builtins.readFile ...)'`

## 9. Sketchybar (last step)

- [ ] 9.1 Create `nix/modules/home/sketchybar.nix` enabling `programs.sketchybar` (bash config, wrapped binary for PATH/env per corintho's pattern)
- [ ] 9.2 Generate `colors.sh` from `config.lib.stylix.colors`
- [ ] 9.3 Implement workspace-indicator script that detects whichever WM (yabai/aerospace) is currently active and shows its current workspace
- [ ] 9.4 Add clock, battery, wifi items (right side)
- [ ] 9.5 Wire yabai signals (`yabai -m signal --add event=... action="sketchybar --trigger ..."`) and/or aerospace's `exec-on-workspace-change` to refresh the indicator
- [ ] 9.6 Wire module import into `nix/darwin/home.nix`
- [ ] 9.7 Re-run full validation sequence (section 7)

## 11. Desk remapping: Communications/desk1, Browsing/desk6

Renumbered desk meanings so Communications (Teams/Outlook, work-only) sits on
the primary display and Browsing (Dia, and Edge work-only) moves off desk1
onto the now-shared desk6:

| Desk | Meaning | Apps routed | Monitor |
|---|---|---|---|
| desk1 | Communications | Teams, Outlook (work-only, via work.nix) | Primary (display 1) |
| desk2 | IDE | Xcode, Android Studio, VSCode (unchanged) | Secondary (display 2) |
| desk3 | Dev | none explicit (Simulator floats via manage=off, unchanged) | Secondary |
| desk4 | Terminal | Ghostty (unchanged) | Secondary |
| desk5 | Music | Music.app (unchanged) | Secondary |
| desk6 | Browsing (moved from desk1) | Dia (moved from desk1), Edge (work-only, moved from desk1's old Focus routing) | Secondary |

- [x] 11.1 `nix/modules/darwin/yabai/default.nix`: add shared `yabai -m space 6 --label desk6` label alongside desk1-desk5 (desk6/Browsing now shared, not work-only); update the desk-mapping comment above the labels
- [x] 11.2 `nix/modules/darwin/yabai/default.nix`: change the `Dia` app-routing rule from `space=desk1` to `space=desk6`
- [x] 11.3 `nix/modules/darwin/yabai/default.nix`: update the monitor-assignment block — `desk1` → display 1 (primary, Communications), `desk2`/`desk3`/`desk4`/`desk5`/`desk6` → display 2 (secondary)
- [x] 11.4 `nix/modules/darwin/yabai/work.nix`: remove the (now-shared) `desk6` label and monitor-assignment lines; change Teams/Outlook rules from `space=desk6` to `space=desk1`; add a dedicated Edge rule targeting `space=desk6`
- [x] 11.5 Tuna (`config.shared.toml`, `personal/config.toml`, `work/config.toml`): retarget the `y` group's `c` (Communications) binding from `desk2`→`desk1`, `b` (Browsing) from `desk1`→`desk6`, `i` (IDE, was raw space `7`) → `desk2`; mirror the same retargeting in the `s w` (Send window to workspace) submenu's Communications/Browsing/IDE children (both plain and `+focus` variants)
- [x] 11.6 `work/config.toml` only: remove the redundant top-level `k`/`K` "Focus (work)" bindings and their `s w` submenu counterparts (superseded by `c`→`desk1`, now shared across profiles)
- [x] 11.7 Re-run full validation sequence (section 7) plus the TOML-parse sanity check on the rendered Tuna config for both `darwinConfigurations` (personal + work) — confirm no `k`/`K` keys remain in either

