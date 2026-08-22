# yabai window manager (nix-darwin system module).
#
# Mirrors the workspace scheme, gaps, and app-routing rules of the existing
# AeroSpace config (nix/modules/home/aerospace/) so switching between the
# two window managers is transparent day-to-day — see
# openspec/changes/add-yabai-sketchybar/design.md, Decisions 1 and 2.
#
# Unlike AeroSpace, yabai has no native declarative/TOML config format:
# `services.yabai.config` renders as `yabai -m config <k> <v>` lines, and
# `services.yabai.extraConfig` is raw shell/yabai-CLI text (design.md
# Decision 1). Space labels, app-routing rules, and monitor assignment all
# live in `extraConfig` below, built from Nix so the work-profile override
# (./work.nix) can still be composed similarly to aerospace's
# main.toml/work.toml split, but as string concatenation rather than TOML
# merge.
#
# `enableScriptingAddition = true` covers the entire SA + sudoers story:
# nix-darwin's own services.yabai module already declares a
# `environment.etc."sudoers.d/yabai"` entry (scoped to a sha256 hash of the
# yabai binary, `%admin ALL=(root) NOPASSWD: sha256:<hash> <bin> --load-sa`)
# plus a `launchd.daemons.yabai-sa` job that runs `yabai --load-sa` at load
# — no manual sudoers stanza is needed here (see design.md Decision 4; the
# "declared inside the yabai module for cohesion" intent is satisfied by
# this single option flip). SIP must still be partially disabled on the
# host for the scripting addition to actually load — that is a host-level
# prerequisite, out of scope to automate here (task 3.3).
#
# Mutual exclusivity with AeroSpace (v2 — build-time selection): rather than
# both WMs being installed and toggled at runtime via a shared pause/resume
# helper, `services.yabai.enable` below is gated directly on the
# `lcars.wm.active` flag (`nix/options/wm.nix`), which defaults to `"yabai"`.
# AeroSpace's own `programs.aerospace.enable`/`launchd.enable`
# (nix/modules/home/aerospace/default.nix) are gated the opposite way, so
# exactly one WM is ever enabled at build/deploy time — no runtime
# coordination, launchd pause/resume script, or login-time wiring required.
# See openspec/changes/add-yabai-sketchybar/design.md, Decision 7.
{
  lib,
  pkgs,
  profile,
  lcars,
  ...
}:
let
  # Mirrors aerospace/default.nix's profile-override-path convention (see
  # nix/lib/resolve-module.nix for the general pattern this is modeled on).
  # Unlike aerospace's TOML merge, the work override here is just an
  # extraConfig string fragment to append, since yabai has no attrset-based
  # config format to recursively merge.
  profileOverridePath = ./. + "/${profile}.nix";
  profileExtraConfig =
    if builtins.pathExists profileOverridePath then import profileOverridePath else "";
in
{
  services.yabai = {
    enable = lcars.wm.active == "yabai";
    package = pkgs.yabai;

    # Enables the scripting addition (and its sudoers/launchd wiring) —
    # see the module-level comment above.
    enableScriptingAddition = true;

    # Global window/behavior config, applied via `yabai -m config <k> <v>`.
    # Gaps/padding are intentionally tighter than AeroSpace's (`inner`/`outer`
    # = 20/64) — per explicit user request, not mirroring AeroSpace for this
    # value (design.md Decision 7):
    # window_gap = 2, {top,bottom,left,right}_padding = 8.
    config = {
      # Free-floating windows by default, per explicit user request
      # (superseding the previous `stack` default — see
      # openspec/changes/yabai-float-default-layout/design.md Decision 1).
      # Any given space's layout can still be manually switched to `stack` or
      # `bsp` later via `yabai -m space --layout <mode>` (already exposed
      # through the Tuna `y l` submenu) — this only changes the default.
      layout = "float";
      window_gap = 4;
      top_padding = 8;
      bottom_padding = 16;
      left_padding = 16;
      right_padding = 16;
      window_opacity = "on";
      active_window_opacity = 0.98;
      normal_window_opacity = 0.1;
      # Off (was "on" under the old `stack` default): under `stack` only one
      # window is ever focused/visible per space, so cursor-warping on focus
      # change was unobtrusive. Under `float`, multiple windows can be
      # visible/focused at once, so warping the cursor on every focus change
      # is disruptive — see design.md Decision 2.
      mouse_follows_focus = "off";
      focus_follows_mouse = "off";
      window_placement = "second_child";
      window_topmost = "off";
      window_shadow = "off";
    };

    extraConfig =
      let
        # Top-of-screen padding reserved for the status bar, straight from
        # lcars.bar.height (nix/options/bar.nix) — the exact same value
        # sketchybar itself runs at (threaded into
        # nix/modules/home/sketchybar/sketchybarrc.sh as its BAR_HEIGHT env
        # var), so the reserved area and the drawn bar can never drift
        # apart. Collapses to 0 when sketchybar is disabled, letting tiled
        # windows reclaim the full screen height under the native menu bar.
        barTopPadding = if lcars.bar.sketchybar.enable then toString lcars.bar.height else "0";
      in
      ''
        # Reserve space at the top of the screen for the status bar
        # (${barTopPadding}px; see lcars.bar.height, nix/options/bar.nix).
        # `all` (not `main`) is required so the reserved padding applies to
        # every display, not just the main one — confirmed live: with
        # `main`, windows on the secondary monitor were placed
        # underneath/overlapping the bar since only the main display's
        # spaces had top padding.
        yabai -m config external_bar all:${barTopPadding}:0
      ''
      + lib.optionalString lcars.bar.sketchybar.enable ''
        # Notify sketchybar to refresh the workspace indicator whenever the
        # active space changes (see
        # openspec/changes/add-yabai-sketchybar/design.md, Decision 6).
        yabai -m signal --add event=space_changed action="sketchybar --trigger yabai_space_change"
        # `space_changed` alone doesn't fire when switching focus between apps
        # on different displays that each already show their own space (no
        # actual space change occurs in that case, only a focus change) —
        # `window_focused` covers that case too. Both signals trigger the same
        # `yabai_space_change` sketchybar event since `workspace.sh` just
        # re-queries whatever the currently-focused space is, regardless of
        # which signal woke it up.
        yabai -m signal --add event=window_focused action="sketchybar --trigger yabai_space_change"
      ''
      + ''

          # NOTE: an earlier version of this file auto-created missing macOS
        # Spaces here via a synchronous `yabai -m query --spaces | grep -c
        # ...` loop. This broke yabai's own startup entirely — calling
        # `yabai -m query` (a full request/response IPC round-trip) from
        # *within* yabai's own `-c` config script is racy, since yabai's
        # internal message-passing server may not yet be ready to answer
        # queries while it is still synchronously executing its own startup
        # config. Confirmed live: after deploying that loop, execution never
        # reached the space-labeling/rule lines below (`yabai -m rule --list`
        # returned `[]`, all space labels were blank), even though the daemon
        # answered the identical query fine moments later once fully up.
        # Reverted to a manual one-time step instead: if fewer than 6 Spaces
        # exist on the target machine, create the missing ones via Mission
        # Control (or run `yabai -m space --create` manually from a normal
        # shell — never from within yabairc) *before* the labels below can
        # apply successfully.

        # Space labels mirroring AeroSpace's workspace scheme
        # (nix/modules/home/aerospace/main.toml), renumbered to real macOS
        # Space indices (linkarzu-style `deskN` labels — design.md Decision 7).
        # Shared 6-desk scheme (desk6/Browsing was previously work-profile-only
        # but is now shared, since Dia routes there regardless of profile):
        # desk1=Communications, desk2=IDE, desk3=Dev, desk4=Terminal,
        # desk5=Music, desk6=Browsing. Spaces are created/labeled by index;
        # yabai numbers spaces per-display starting at 1, so this assumes at
        # least 6 spaces already exist on the display(s) being labeled (create
        # additional spaces via Mission Control if needed before labels apply).
        yabai -m space 1 --label desk1
        yabai -m space 2 --label desk2
        yabai -m space 3 --label desk3
        yabai -m space 4 --label desk4
        yabai -m space 5 --label desk5
        yabai -m space 6 --label desk6

        # App-routing rules mirroring aerospace/main.toml's
        # `on-window-detected` entries. yabai's `--rule` matches on app name
        # (not bundle id like aerospace), so app names below are best-effort
        # equivalents of the aerospace app-ids they mirror.
        yabai -m rule --add app="^Ghostty$" space=desk4        # com.mitchellh.ghostty
        yabai -m rule --add app="^Xcode$" space=desk2           # com.apple.dt.Xcode
        yabai -m rule --add app="^Android Studio$" space=desk2  # com.google.android.studio
        yabai -m rule --add app="^Code$" space=desk2            # com.microsoft.VSCode
        yabai -m rule --add app="^Music$" space=desk5           # com.apple.Music
        yabai -m rule --add app="^Dia$" space=desk6             # company.thebrowser.dia

        # Float-by-default apps: `manage=off` excludes matching windows from
        # tiling entirely (they stay floating, unaffected by whatever layout
        # mode the space they're on is switched to). These rules are kept
        # explicit on purpose even now that `float` is the global default
        # (see design.md Decision 3, yabai-float-default-layout): they ensure
        # Simulator/Finder keep floating even if a given space's layout is
        # later manually overridden to `stack`/`bsp`. No space assignment is
        # given for these — they float freely wherever they happen to open.
        yabai -m rule --add app="^Simulator$" manage=off
        yabai -m rule --add app="^Finder$" manage=off

        # NOTE: aerospace's main.toml has a catch-all
        # `[[on-window-detected]] check-further-callbacks = true; run =
        # ["layout floating"]` fallback for anything not matched above. yabai
        # has no exact equivalent — it tiles all windows by default unless an
        # explicit `manage=off` rule is added per-app, so there is no direct
        # 1:1 translation of that fallback here.

        # Monitor assignment mirroring aerospace's
        # `[workspace-to-monitor-force-assignment]`: Communications (desk1) is
        # kept on the primary display, everything else (desk2-desk6) on the
        # secondary display. Display indices confirmed via a live
        # `yabai -m query --displays` on this machine: index 1 = built-in
        # 1728x1117 primary display, index 2 = 2560x1440 external secondary
        # display. These are hardware-dependent — re-verify with
        # `yabai -m query --displays` and adjust indices below if the monitor
        # setup changes.
        yabai -m space desk1 --display 1   # Communications -> primary
        yabai -m space desk2 --display 2   # IDE -> secondary
        yabai -m space desk3 --display 2   # Dev -> secondary
        yabai -m space desk4 --display 2   # Terminal -> secondary
        yabai -m space desk5 --display 2   # Music -> secondary
        yabai -m space desk6 --display 2   # Browsing -> secondary

        ${profileExtraConfig}

        # Retroactively apply all rules above to any windows that were
        # already open before yabai (re)started — `yabai -m rule --add`
        # alone only affects windows created from this point forward, so
        # without this, already-running apps never get moved to their
        # assigned desk<N> space. Safe/idempotent to re-run on every
        # yabai start/reload.
        yabai -m rule --apply
      '';
  };
}
