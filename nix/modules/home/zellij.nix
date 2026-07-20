{
  config,
  lcars,
  lib,
  pkgs,
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
        source = ./zellij/layouts;
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
        builtins.readFile ./zellij/config.kdl
        + import ./zellij/zjstatus.nix {
          inherit
            colors
            pkgs
            lcars
            lib
            ;
        };
    };

    programs = {
      zellij.enable = true;
      zellij.package = pkgs.unstable.zellij;
      fish.interactiveShellInit = "${config.programs.zellij.package}/bin/zellij setup --generate-completion fish | source";
    };
  };
}
