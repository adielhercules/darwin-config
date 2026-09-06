{
  pkgs,
  lib,
  files,
  ...
}:
{
  config = {

    xdg.configFile = {
      "fish/conf.d/zellij.fish".source = "${files}/fish/zellij.fish";
      "fish/conf.d/ask.fish".source = "${files}/fish/ask.fish";
    };
    programs = {
      fish = {
        enable = true;
        shellInit = lib.mkMerge [
          ''
            set -x SHELL /run/current-system/sw/bin/bash
            fish_add_path /run/current-system/sw/bin
            # bun's global installs (e.g. opencode2) live in ~/.bun/bin
            fish_add_path ~/.bun/bin
          ''
          (lib.mkIf pkgs.stdenv.isDarwin "fish_add_path /opt/homebrew/bin/")
        ];
        interactiveShellInit = ''
          set -g fish_greeting
          set -g fish_key_bindings fish_default_key_bindings
        '';
        plugins = [
          {
            name = "autopair";
            src = pkgs.fishPlugins.autopair.src;
          }
          {
            name = "bang-bang";
            src = pkgs.fishPlugins.bang-bang.src;
          }
          {
            # Not packaged in nixpkgs/fishPlugins — fetch from upstream directly.
            name = "fish-colored-man";
            src = pkgs.fetchFromGitHub {
              owner = "decors";
              repo = "fish-colored-man";
              rev = "1ad8fff696d48c8bf173aa98f9dff39d7916de0e";
              sha256 = "sha256-uoZ4eSFbZlsRfISIkJQp24qPUNqxeD0JbRb/gVdRYlA=";
            };
          }
          {
            name = "done";
            src = pkgs.fishPlugins.done.src;
          }
          {
            name = "sponge";
            src = pkgs.fishPlugins.sponge.src;
          }
        ];
      };
    };
  };
}
