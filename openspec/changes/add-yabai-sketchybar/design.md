## Context

This repo manages AeroSpace via `nix/modules/home/aerospace/` (`default.nix` reads `main.toml` + profile-specific `work.toml`, merges with `lib.recursiveUpdate` plus explicit array-concatenation for `on-window-detected`, and sets `programs.aerospace.settings`). All AeroSpace hotkeys are driven through **Tuna**, a leader-key launcher app configured via TOML at `~/Library/Application Support/Tuna/config.toml`, deployed per-profile from `nix/modules/home/tuna/{personal,work}/config.toml` (with `config.shared.toml` kept only as a human-authoring reference, not read programmatically). The Tuna "Aerospace" group (`key = 'a'`) has ~40 nested children invoking `aerospace <subcommand>` via `tuna://run/text.<url-encoded-cmd>/Run%20Text%20as%20Shell%20Command` (spaces double-URL-encoded as `%2520`).

`yabai`, `sketchybar`, and `skhd` are all plain nixpkgs packages with first-class nix-darwin/home-manager option modules (`services.yabai`, `programs.sketchybar`, `services.skhd`). We are **not** using skhd — Tuna remains the sole hotkey manager, consistent with the existing convention.

Reference prior art reviewed:
- `linkarzu/dotfiles-latest/yabai` — real yabai config content: `stack` layout, per-space labels, opacity/signal patterns, per-app space rules, dynamic multi-display handling (kept as inspiration, not copied verbatim, since our workspace scheme differs)
- `corintho/dotfiles` `sketchybar.nix` — Nix wiring pattern: wrap the sketchybar binary via `writeShellScriptBin` to fix PATH/env for launchd, assemble config via a `pkgs.runCommand` derivation, generate a theme file from `config.lib.stylix.colors` at build time (we adapt this to bash instead of Lua)

## Goals / Non-Goals

**Goals:**
- Mirror AeroSpace's exact workspace scheme (`B/C/D/T/M`, work-only `F`) and app-routing rules in yabai, so switching between WMs is transparent to daily workflow
- Keep only one WM actively tiling at a time (mutual exclusivity), both installed and togglable
- Duplicate the entire Tuna "Aerospace" hotkey group as a new "Yabai" group (`key = 'y'`) with equivalent commands
- Add `pause`/`start` hotkey children to both groups for switching
- Enable yabai's Scripting Addition via a declarative sudoers entry (no manual `visudo`)
- Ship a minimal, Stylix-themed sketchybar bar (last step) showing a WM-agnostic workspace indicator + clock/battery/wifi

**Non-Goals:**
- Introducing skhd or any new hotkey manager — Tuna remains canonical
- Replicating linkarzu's or corintho's full bar feature set (mic, CPU, DND, brew updates, etc.) — sketchybar here is intentionally minimal
- Building a generic/portable multi-monitor auto-detection system (aerospace's monitor assignment is static; yabai's will be too, matching it)
- Lua/SbarLua for sketchybar — bash only, per decision below

## Decisions

### Decision 1: yabai config authored as a generated shell script, not a TOML-merge like AeroSpace

Unlike AeroSpace, nix-darwin's `services.yabai` module takes `.config` (an attrset yabai renders as `yabai -m config <k> <v>` lines) and `.extraConfig` (raw shell/yabai-CLI lines) — there is no native TOML format for yabai. Window rules, space labels, and app-routing are all `yabai -m rule --add ...` / `yabai -m space N --label ...` shell invocations. We will:
- Use `services.yabai.config` for global settings (layout, gaps, padding, mouse/window behavior)
- Use `services.yabai.extraConfig` (or an equivalent `home.file`-templated shell block) for space labels, app-routing rules, and monitor assignment — built from Nix so shared vs. work-only rules can still be composed similarly to `main.toml`/`work.toml`, but as string concatenation rather than TOML merge

**Alternative considered**: Hand-parse a custom `.yabairc`-style file with `builtins.readFile`, mimicking aerospace's TOML approach. Rejected — yabai has no native declarative format; shell-generation via Nix is more idiomatic and matches nix-darwin's own `services.yabai` option shape.

### Decision 2: Layout mode = `stack` (not `bsp`)

Per user preference, yabai runs in `stack` mode globally (single focused app per space), matching linkarzu's style rather than classic BSP tiling. Individual spaces can still be overridden to `bsp` later if needed (not in initial scope).

### Decision 3: Mutual exclusivity via a shared `wm-switch` helper script, not skhd/launchd-only

**Revised after a real deploy failure** (see "Decision 3 revision" below) — the original plan of using AeroSpace's native `aerospace enable off/on` toggle as the pause mechanism was implemented, tested, and found to break `just deploy`. The design was corrected in place; this section documents the final, working mechanism.

Both yabai and AeroSpace are nix-darwin/home-manager-managed **launchd user agents** (`gui/$(id -u)` domain, no sudo needed):
- yabai: label `org.nixos.yabai` (from nix-darwin's `services.yabai` → `launchd.user.agents.yabai`, `labelPrefix` = `org.nixos`)
- AeroSpace: label `org.nix-community.home.aerospace` (from home-manager's `programs.aerospace.launchd.enable`)

Both are paused/started **symmetrically** via `launchctl`, exposed through a single shared script (`nix/modules/home/wm-switch.nix`, `pkgs.writeShellScriptBin "wm-switch"`, installed via `home.packages`):
- `wm-switch <yabai|aerospace> pause` → `launchctl bootout gui/$(id -u)/<label>` (fully unloads the job — a "paused" WM is a stopped process, not a "running but disabled" one)
- `wm-switch <yabai|aerospace> start` → `launchctl bootstrap gui/$(id -u) <plist-path>` (re-registers the job; safe/idempotent if already loaded) followed by `launchctl kickstart -k gui/$(id -u)/<label>` (ensures it's actually running)
- `wm-switch yabai start` also pauses aerospace afterward; `wm-switch aerospace start` also pauses yabai afterward — enforcing mutual exclusivity

At login, only `wm-switch yabai pause` is invoked (from AeroSpace's own `after-startup-command`, since AeroSpace is already running via its own `KeepAlive` agent — see Decision 3 revision below for why the naive `wm-switch aerospace start` was wrong here).

#### Decision 3 revision: why `aerospace enable off/on` was rejected

Initial implementation used AeroSpace's native `enable off`/`enable on` toggle for pausing, since it disables tiling without killing the process. This was deployed and **broke `just deploy`**:
```
AeroSpace config changed, reloading...
AeroSpace server is disabled and doesn't accept commands. You can use 'aerospace enable on' to enable the server
error: recipe `deploy` failed on line 23 with exit code 1
```
Root cause (confirmed by reading home-manager's actual `modules/programs/aerospace.nix`): the module sets a synchronous, fatal `onChange` hook on the generated config file — `${aerospace} reload-config`, with no error tolerance — that fires on *any* `darwin-rebuild switch` where the rendered TOML content changed. `aerospace enable off` disables **all** commands on the running process, including `reload-config`, and this disabled state persists indefinitely (it's an in-memory toggle with no restart-based reset). So: pause via `enable off` → any later deploy that also touches `aerospace.toml` → fatal failure.

A related latent bug was also found and fixed: `launchctl kickstart -k` only works on an already-bootstrapped job; after a `bootout`, restarting requires `launchctl bootstrap` first.

The fix (implemented): switch AeroSpace's pause/start primitive to `launchctl bootout`/`bootstrap`+`kickstart`, mirroring yabai exactly (a paused WM is fully stopped, never "running but rejecting commands"). As defense-in-depth, `nix/modules/home/aerospace/default.nix` also overrides the fatal `onChange` hook (`home.file.".aerospace.toml".onChange = lib.mkForce "aerospace reload-config || true"`) so a future `just deploy` can never be broken by this hook again, regardless of AeroSpace's runtime state.

Login-time wiring was also corrected: `after-startup-command` now calls `wm-switch yabai pause` directly rather than `wm-switch aerospace start` — the latter would have made AeroSpace bootout+bootstrap **itself** from within its own already-running startup command, risking a self-restart loop.

### Decision 4: Scripting Addition sudoers entry declared via nix-darwin's `security.sudo.extraConfig` (or equivalent) at the system level, but authored inside the yabai module for cohesion

Per user preference, SA is enabled. The NOPASSWD rule for `yabai --load-sa` (referenced from `nix-darwin`'s own yabai module docs) will be added declaratively — avoiding any manual `visudo` step — using nix-darwin's system-level sudoers extension option, imported/referenced from the yabai module file so all yabai-related config lives together even though the sudoers stanza is technically system-scope.

### Decision 5: Tuna duplication is a straight structural copy across all 3 files, not a shared/templated block

Consistent with the existing repo convention (each Tuna profile file is independently authored/maintained; `config.shared.toml` is not read programmatically), the new `key = 'y'` group and the `pause`/`start` additions to both groups will be hand-duplicated into `config.shared.toml` (reference), `personal/config.toml`, and `work/config.toml` — no new merge/templating mechanism introduced.

### Decision 6: Sketchybar is bash-based and Stylix-themed, deferred to last

Per user preference: bash (not Lua/SbarLua, avoiding an extra binding package/overlay). Colors generated from `config.lib.stylix.colors` similar to corintho's `colors.sh` pattern, adapted to plain bash `0xAARRGGBB` hex construction. The bar shows only: workspace indicator (left, queries whichever WM is currently active) + clock, battery, wifi (right). This step is implemented and validated only after yabai + Tuna wiring are confirmed working.

### Decision 7 (v2 — supersedes Decisions 3 and 5's runtime-toggle premise): Build-time WM selection via `lcars.wm.active`, no runtime pause/resume

After deploying and testing the `wm-switch`-based mutual-exclusivity mechanism (Decisions 3/3-revision), the user found the runtime pause/resume UX "too strange" and requested a simpler, build-time approach instead, following the existing `lcars.*` feature-flag convention already used for `lcars.shell.fish`.

**New mechanism:**
- `nix/options/wm.nix` declares `options.lcars.wm.active = lib.mkOption { type = lib.types.enum [ "yabai" "aerospace" ]; default = "yabai"; ... };`, registered in `nix/options/default.nix`'s imports list (mirroring `shell.nix`'s registration)
- `nix/features.nix` sets/confirms the default (`lcars.wm.active = "yabai";`, or relies on the option's own default — equivalent)
- `services.yabai.enable` (`nix/modules/darwin/yabai/default.nix`) and `programs.aerospace.enable`/`launchd.enable` (`nix/modules/home/aerospace/default.nix`) are both gated on `lcars.wm.active == "yabai"` / `== "aerospace"` respectively — mutually exclusive by construction, no runtime coordination needed
- `lcars` is already threaded as a module arg into **both** the darwin system-module context and the home-manager context via the existing `mkSpecialArgs` function (`nix/darwin/default.nix`) — confirmed via source inspection, zero additional plumbing required beyond the option file itself, exactly matching the precedent set by `lcars.shell.fish`

**`wm-switch` is deleted entirely** (`nix/modules/home/wm-switch.nix`), along with:
- Its import in `nix/darwin/home.nix`
- AeroSpace's `after-startup-command = ['exec-and-forget wm-switch yabai pause']` and its rationale comments in `main.toml`
- The Pause/Start (`x`/`o` key) children added to both the `a` and `y` Tuna groups in all 3 Tuna files
- Stale rationale comments referencing the pause-at-login mechanism in `yabai/default.nix`/`aerospace/default.nix`

The `onChange` defense-in-depth override in `aerospace/default.nix` (making `reload-config` failures non-fatal) is **kept**, reworded to stand on its own merit — it's still useful protection against home-manager's fatal reload hook independent of any pause/resume mechanism, since config content can change on any deploy regardless.

**Tuna group hiding**: since only one WM is ever enabled, showing both `a` and `y` groups in Tuna would be confusing/non-functional for the disabled one. Rather than converting the Tuna config to a `builtins.fromTOML`-parse-and-filter-and-`pkgs.formats.toml.generate`-re-serialize pipeline (which would silently drop ~10 existing in-file comment blocks — confirmed via inspection, since nixpkgs' TOML tooling has no comment-preservation), each group is wrapped in sentinel line-comments:
```toml
# WM-GROUP-BEGIN:aerospace
[[comboMode.bindings]]
key = 'a'
...
# WM-GROUP-END:aerospace
```
(same pattern for `# WM-GROUP-BEGIN:yabai` / `# WM-GROUP-END:yabai`). `nix/modules/home/tuna/default.nix` then does a `lib.splitString "\n"` + fold-based line filter (after the existing `<user>` substitution step) that drops every line between the inactive WM's markers, keyed off `lcars.wm.active` — preserving all other comments/formatting in the file byte-for-byte.

**Workspace renumbering (yabai only)**: research confirmed AeroSpace's workspaces are a **virtual, non-Mission-Control-visible** concept by design (AeroSpace's own docs: it moves inactive-workspace windows off-screen rather than using real macOS Spaces, and explicitly recommends *not* interacting with real Spaces at all). yabai's spaces, by contrast, already are real numbered macOS Spaces. Since the user wants to "match linkarzu's setup more, use actual macOS desktops," this is only meaningfully achievable for yabai:
- yabai workspace labels renamed `B/C/D/T/M/F` → `desk1..desk6` (linkarzu-style, same semantic mapping: desk1=Browsing, desk2=Code, desk3=Dev, desk4=Terminal, desk5=Music, desk6=Focus/work-only), applied to space labels, app-routing rules, and the `y` Tuna group's bindings
- AeroSpace's own config is left as-is (letters unchanged) — renumbering it would be purely cosmetic and would not grant real-Spaces behavior, so it's not worth the churn given AeroSpace is now the non-default fallback

**Yabai gap/padding tightening**: per user request, reduced from `window_gap=20`/`*_padding=64` to `window_gap=2`/`*_padding=8` in `services.yabai.config`.

**Monitor assignment**: left commented out, unchanged (deferred until real hardware/multi-monitor setup is confirmed).

## Risks / Trade-offs

- **[Risk] yabai's Scripting Addition requires SIP partial-disable on the host** → out of scope for this change (assumed already configured or accepted by the user); we only handle the sudoers/declarative wiring, not SIP itself. Document this clearly in tasks.
- **[Risk] Line-based sentinel filtering in Tuna's default.nix is a bespoke text-processing mechanism, not a standard Nix/TOML pattern** → mitigate with clear inline comments explaining why (comment-preservation), and by keeping the marker syntax simple/unambiguous (`# WM-GROUP-BEGIN:<wm>` / `# WM-GROUP-END:<wm>`, one per line, never nested).
- **[Risk] Renumbering yabai's workspaces touches 3 places (space labels, app-routing rules, Tuna `y` group bindings) that must stay consistent** → mitigate by using a single source-of-truth mapping (comment table) and double-checking each reference during implementation.
- **[Risk] `stack` layout may not suit all workflows immediately** → acceptable per explicit user preference; can be revisited later per-space if needed.

## Migration Plan

1. Add `lcars.wm.active` option (`nix/options/wm.nix` + registration), default `"yabai"`
2. Gate `services.yabai.enable` and `programs.aerospace.enable`/`launchd.enable` on the flag
3. Delete `wm-switch.nix` and all its references (import, aerospace `after-startup-command`, Tuna Pause/Start children, stale comments)
4. Renumber yabai workspaces (`B/C/D/T/M/F` → `desk1..desk6`) across `yabai/default.nix`, `yabai/work.nix`, and the Tuna `y` group's bindings
5. Tighten yabai gaps (`window_gap=2`, `*_padding=8`)
6. Add sentinel markers around both Tuna groups (all 3 files) + line-filter logic in `tuna/default.nix` driven by `lcars.wm.active`
7. Run full validation sequence (`nix flake check`, `nix fmt`, `deadnix`, `statix`); `just check`/deploy only on explicit request
8. Manually verify (user, post-deploy): yabai is enabled by default with `desk1..desk6` labels and correct app routing, only the `y` Tuna group is visible; flipping `lcars.wm.active = "aerospace"` and redeploying switches to AeroSpace with only the `a` group visible
9. (Last) Build `nix/modules/home/sketchybar.nix`: minimal bar, Stylix colors, WM-agnostic workspace indicator, wire into `home.nix`, validate

**Rollback**: Set `lcars.wm.active` back to a known-good value and redeploy; to fully revert, remove the `lcars.wm` option/flag usage, restore `wm-switch.nix` and its references from git history, remove sentinel markers from Tuna files.

## Open Questions

- ~~Exact launchd label/mechanism for pausing yabai without uninstalling it~~ — moot as of Decision 7 (no runtime pause/resume anymore)
- Whether SA's SIP prerequisite is already satisfied on this machine (assumed yes per user's explicit request to enable it)
