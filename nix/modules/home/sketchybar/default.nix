{
  config,
  pkgs,
  lib,
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

  # Explicitly loads the Hack Nerd Font's Regular weight directly into
  # sketchybar's own CoreText context via `--load-font`, bypassing any
  # dependence on the OS-level font registration/ATS cache having picked
  # it up correctly. This is sketchybar's own documented troubleshooting
  # step for "if you experience missing icons"
  # (https://felixkratz.github.io/SketchyBar/setup#fonts) — added after
  # icon glyphs failed to render even though the font was confirmed
  # correctly installed, named, and glyph-mapped via every other check.
  # The absolute Nix store path is baked in at build time so this doesn't
  # depend on any runtime PATH/font-directory assumption.
  loadFontSh = pkgs.writeText "sketchybar-load-font.sh" ''
    #!/usr/bin/env bash
    sketchybar --load-font "${pkgs.nerd-fonts.hack}/share/fonts/truetype/NerdFonts/Hack/HackNerdFont-Regular.ttf"
  '';

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
        mkdir -p "$out/items"

        cp ${./sketchybarrc.sh} "$out/sketchybarrc"
        cp ${./plugins/battery.sh} "$out/plugins/battery.sh"
        cp ${./plugins/wifi.sh} "$out/plugins/wifi.sh"
        cp ${./plugins/clock.sh} "$out/plugins/clock.sh"
        cp ${./icons.sh} "$out/icons.sh"
        cp ${./items/apple.sh} "$out/items/apple.sh"
        cp ${./items/wifi.sh} "$out/items/wifi.sh"
        cp ${colorsSh} "$out/colors.sh"
        cp ${workspaceSh} "$out/plugins/workspace.sh"
        cp ${loadFontSh} "$out/load_font.sh"

        chmod +x "$out/sketchybarrc" "$out"/plugins/*.sh "$out"/items/*.sh "$out/load_font.sh"
      '';
  # `jq` (to parse yabai's JSON query output) plus the active WM's own CLI
  # binary (`yabai`/`aerospace`) need to be on sketchybar's launchd PATH,
  # same requirement as before — only now threaded manually into our own
  # launchd.agents.sketchybar block below instead of via home-manager's
  # programs.sketchybar `extraPackages` option, since that module is no
  # longer used (see explanation above extraBinPath).
  extraBinPath = lib.makeBinPath (
    [
      pkgs.jq
    ]
    # pkgs.unstable.aerospace: consistent with the aerospace package pin in
    # nix/modules/home/aerospace/default.nix — kept on unstable to track
    # upstream's fast release cadence rather than 26.05 stable.
    ++ (if lcars.wm.active == "yabai" then [ pkgs.yabai ] else [ pkgs.unstable.aerospace ])
  );
in
{
  # sketchybar is intentionally installed via Homebrew (nix-darwin's
  # `homebrew.brews`, see nix/darwin/profiles/defaults.nix's
  # "felixkratz/formulae" tap) rather than home-manager's
  # `programs.sketchybar` module. The nixpkgs-built sketchybar binary
  # (ad-hoc/linker-signed, no entitlements — standard for nixpkgs Darwin
  # CLI tools) exhibited a total icon-glyph rendering failure that
  # persisted across every font/cache/config fix attempted (font-name
  # verification, cmap glyph-presence checks, font-cache dedup, full
  # logout, explicit `--load-font`, switching fonts entirely) and traced
  # most plausibly to sketchybar v2.23.0's rendering engine (nixpkgs'
  # pinned version at the time) predating upstream's v2.24.0 "Rendering
  # System Overhaul" — rather than chase a version bump across this
  # flake's pinned nixpkgs, we switch the binary source to Homebrew
  # entirely, which tracks upstream releases directly. Since
  # `programs.sketchybar` has no supported way to manage config-only
  # while deferring the actual package/launchd-service to an external
  # binary (its `package`/`home.packages`/`launchd.agents.sketchybar`
  # wiring are all unconditionally coupled under `cfg.enable`), we
  # replicate just the config-file delivery (`xdg.configFile`) and
  # launchd agent (`launchd.agents.sketchybar`) pieces of that module
  # directly here, pointed at Homebrew's install path instead of a Nix
  # store path.
  xdg.configFile."sketchybar" = {
    source = sketchybarConfigDir;
    recursive = true;
  };

  launchd.agents.sketchybar = {
    enable = true;
    config = {
      Program = "/opt/homebrew/bin/sketchybar";
      ProcessType = "Interactive";
      KeepAlive = true;
      RunAtLoad = true;
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/sketchybar/sketchybar.err.log";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/sketchybar/sketchybar.out.log";
      EnvironmentVariables = {
        PATH = "${extraBinPath}:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin";
        # Bar height from the shared lcars.bar.height option
        # (nix/options/bar.nix) so sketchybarrc.sh's `--bar height=` always
        # matches yabai's `external_bar` reservation, which reads the same
        # option (nix/modules/darwin/yabai/default.nix).
        BAR_HEIGHT = toString lcars.bar.height;
      };
    };
  };
}
