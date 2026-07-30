{
  config,
  pkgs,
  lcars,
  ...
}:
let
  inherit (config.lib.stylix) colors mkOpacityHexColor;

  # Minimal semantic palette, base16-conventional mapping (design.md
  # Decision 6): base00 = background, base05 = default foreground/label
  # text, base0D = accent/highlight (blue), base01 = subtle pill-style
  # item background. All colors are exported as full-opacity
  # 0xAARRGGBB-format bash variables via mkOpacityHexColor (sketchybar's
  # `--bar`/`--set ... color=` flags expect 8 hex digits including alpha;
  # plain mkHexColor only produces 6, which sketchybar would misparse).
  colorsSh = pkgs.writeText "sketchybar-colors.sh" ''
    #!/usr/bin/env bash
    # Generated from stylix's base16 color scheme — do not edit by hand.
    export COLOR_BG=${mkOpacityHexColor colors.base00 1.0}
    export COLOR_FG=${mkOpacityHexColor colors.base05 1.0}
    export COLOR_ACCENT=${mkOpacityHexColor colors.base0D 1.0}
    export COLOR_ITEM_BG=${mkOpacityHexColor colors.base01 1.0}
  '';

  # Workspace-indicator script, Nix-templated per the active WM
  # (lcars.wm.active, nix/options/wm.nix) since each WM needs a different
  # query command. Only ever one of these branches is actually built/used
  # at a time, matching the yabai/AeroSpace build-time exclusivity used
  # throughout this feature.
  #
  # yabai: `yabai -m query --spaces --space` returns the focused space's
  # JSON; `.label` holds the desk1..desk6 label set in
  # nix/modules/darwin/yabai/default.nix. `jq` is added to extraPackages
  # below since it isn't guaranteed to be on PATH otherwise.
  #
  # AeroSpace: `aerospace list-workspaces --focused` prints the focused
  # workspace's single-letter name directly (B/C/D/T/M, plus work-only F —
  # see nix/modules/home/aerospace/main.toml). AeroSpace's own
  # letter/purpose scheme is left as-is (design.md Decision 7), so the
  # mapping below is a best-effort short-name mirror of yabai's, not a
  # literal 1:1 semantic match.
  workspaceShContent =
    if lcars.wm.active == "yabai" then
      ''
        #!/usr/bin/env bash
        LABEL="$(yabai -m query --spaces --space | jq -r '.label')"
        case "$LABEL" in
          desk1) NAME_OUT="Communications" ;;
          desk2) NAME_OUT="IDE" ;;
          desk3) NAME_OUT="Dev" ;;
          desk4) NAME_OUT="Terminal" ;;
          desk5) NAME_OUT="Music" ;;
          desk6) NAME_OUT="Browsing" ;;
          *) NAME_OUT="$LABEL" ;;
        esac
        sketchybar --set "$NAME" label="$NAME_OUT"
      ''
    else
      ''
        #!/usr/bin/env bash
        FOCUSED="$(aerospace list-workspaces --focused)"
        case "$FOCUSED" in
          B) NAME_OUT="Browsing" ;;
          C) NAME_OUT="IDE" ;;
          D) NAME_OUT="Dev" ;;
          T) NAME_OUT="Terminal" ;;
          M) NAME_OUT="Music" ;;
          F) NAME_OUT="Communications" ;;
          *) NAME_OUT="$FOCUSED" ;;
        esac
        sketchybar --set "$NAME" label="$NAME_OUT"
      '';
  workspaceSh = pkgs.writeText "sketchybar-workspace.sh" workspaceShContent;

  # Assembles the full `.config/sketchybar` directory tree: the static
  # entrypoint + plugin scripts alongside the two generated files above.
  # Merge pattern mirrors the other resolveModule-adjacent directory-merge
  # conventions used elsewhere in this repo, adapted here to plain
  # `pkgs.runCommand` since there's no attrset/TOML to recursively merge —
  # just files to copy into one tree (design.md Decision 6). The entrypoint
  # MUST be named exactly `sketchybarrc` (no extension) — confirmed from
  # home-manager's actual `modules/programs/sketchybar.nix` source: when
  # `config.source` is a directory (`recursive = true`), it's copied
  # verbatim to `~/.config/sketchybar`, and sketchybar's own CLI looks for
  # `sketchybarrc` there by convention (no `.sh`).
  sketchybarConfigDir =
    pkgs.runCommand "sketchybar-config"
      {
        preferLocalBuild = true;
      }
      ''
        mkdir -p "$out/plugins"

        cp ${./sketchybarrc.sh} "$out/sketchybarrc"
        cp ${./plugins/battery.sh} "$out/plugins/battery.sh"
        cp ${./plugins/wifi.sh} "$out/plugins/wifi.sh"
        cp ${./plugins/clock.sh} "$out/plugins/clock.sh"
        cp ${colorsSh} "$out/colors.sh"
        cp ${workspaceSh} "$out/plugins/workspace.sh"

        chmod +x "$out/sketchybarrc" "$out"/plugins/*.sh
      '';
in
{
  programs.sketchybar = {
    enable = true;
    configType = "bash";
    # `jq` is needed to parse yabai's JSON query output. The active WM's
    # CLI binary itself must ALSO be on PATH — sketchybar runs as its own
    # launchd agent, whose PATH does NOT include the Nix/home-manager
    # profile paths where `yabai`/`aerospace` actually live (confirmed live:
    # workspace.sh failed with "yabai: command not found" in
    # sketchybar.err.log until this was added). Only the active WM's
    # package is added, matching the build-time exclusivity used
    # throughout this feature (lcars.wm.active, nix/options/wm.nix).
    extraPackages = [
      pkgs.jq
    ]
    ++ (if lcars.wm.active == "yabai" then [ pkgs.yabai ] else [ pkgs.unstable.aerospace ]);
    config = {
      source = sketchybarConfigDir;
      recursive = true;
    };
  };
}
