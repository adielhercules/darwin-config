{
  config,
  lcars,
  lib,
  pkgs,
  files,
  ...
}:
let
  inherit (config.lib.stylix) colors;
in
{
  config = {

    xdg.configFile = {
      "zellij/plugins/zellij_forgot.wasm".source = pkgs.fetchurl {
        url = "https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm";
        sha256 = "sha256-MRlBRVGdvcEoaFtFb5cDdDePoZ/J2nQvvkoyG6zkSds=";
      };
      "zellij/layouts" = {
        source = "${files}/zellij/layouts";
        recursive = true;
      };
      "zellij/plugins/zjstatus-hints.wasm".source = pkgs.fetchurl {
        url = "https://github.com/b0o/zjstatus-hints/releases/download/v0.1.4/zjstatus-hints.wasm";
        sha256 = "sha256-k2xV6QJcDtvUNCE4PvwVG9/ceOkk+Wa/6efGgr7IcZ0=";
      };
      "zellij/themes/lcars.kdl".source = colors {
        template = ./zellij/lcars.theme.mustache;
        extension = "kdl";
      };
      "zellij/config.kdl".text =
        builtins.readFile "${files}/zellij/config.kdl"
        + import ./zellij/zjstatus.nix {
          inherit
            colors
            pkgs
            lcars
            lib
            ;
        };
    };

    # Pre-approve permissions for plugins loaded via `load_plugins {}` (background
    # plugins). Zellij has a bug (zellij-org/zellij#4982) where background-loaded
    # plugins request permissions before being attached to a tab, so the
    # interactive approval popup never renders/becomes focusable. Pre-populating
    # the permission cache short-circuits that broken path.
    #
    # NOTE: on macOS, Zellij's Rust `directories` crate does NOT respect
    # $XDG_CACHE_HOME - it always uses the native macOS cache path
    # (~/Library/Caches/org.Zellij-Contributors.Zellij/permissions.kdl), so
    # this must be provisioned via `home.file` at that absolute path rather
    # than `xdg.cacheFile` (which targets ~/.cache and is never read here).
    #
    # Cache keys must match the plugin's real resolved path exactly as Zellij
    # loads it - using ${pkgs.zjstatus} keeps the zjstatus entry in sync
    # automatically across nixpkgs updates instead of hardcoding a nix store
    # hash that would go stale.
    home.file."Library/Caches/org.Zellij-Contributors.Zellij/permissions.kdl".text = ''
      "${pkgs.zjstatus}/bin/zjstatus.wasm" {
          ReadApplicationState
          RunCommands
          ChangeApplicationState
      }
      "${config.home.homeDirectory}/.config/zellij/plugins/zjstatus-hints.wasm" {
          ReadApplicationState
          MessageAndLaunchOtherPlugins
      }
    '';

    programs = {
      zellij.enable = true;
      zellij.package = pkgs.unstable.zellij;
      fish.interactiveShellInit = "${config.programs.zellij.package}/bin/zellij setup --generate-completion fish | source";
    };
  };
}
