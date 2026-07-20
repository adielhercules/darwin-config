{ pkgs, lib, ... }:
{
  config = {
    programs = {
      helix = {
        enable = true;
        package = pkgs.unstable.helix;
        settings = {
          theme = lib.mkDefault "lcars";
          editor = {
            # Editor appearance
            line-number = "relative";
            bufferline = "multiple";
            color-modes = true;
            cursor-shape = {
              insert = "bar";
              normal = "block";
              select = "underline";
            };
            indent-guides = {
              render = true;
            };
            # Diagnostics
            end-of-line-diagnostics = "hint";
            inline-diagnostics = {
              cursor-line = "warning";
            };
            # Usability tunings
            jump-label-alphabet = "ntesiroahdmgcxzlpufywqjbkv";
            # Input setup
            mouse = false;
            lsp = {
              display-inlay-hints = true;
            };
          };
          keys = {
            normal = {
              "C-y" = "copy_between_registers";
              "C-," = "command_mode";
              "C-e" =
                ":sh zellij run -n Yazi -c -f -x 1%% -y 1%% --width 98%% --height 98%% -- bash ~/.config/helix/yazi-picker.sh open %{buffer_name}";
              "C-l" = [
                ":new"
                ":insert-output lazygit"
                ":buffer-close!"
                ":reload-all"
              ];
              "C-a" = [
                ":new"
                ":insert-output opencode"
                ":buffer-close!"
                ":reload-all"
              ];
              "tab" = ":buffer-next";
              "S-tab" = ":buffer-previous";
              "]" = {
                b = ":buffer-next";
              };
              "[" = {
                b = ":buffer-previous";
              };
              space = {
                q = ":quit";
                Q = ":quit!";
                w = ":write";
                b = {
                  c = ":buffer-close";
                  e = ":buffer-next";
                  n = ":buffer-previous";
                  o = ":buffer-close-others";
                  x = ":buffer-close!";
                  a = ":buffer-close-all";
                  b = "buffer_picker";
                };
              };
            };
          };
        };
      };
    };

    home.sessionVariables = {
      EDITOR = "hx";
    };
    xdg.configFile = {
      "helix/themes/lcars.toml".text = ''
        inherits = 'stylix'

        "ui.cursor.primary" = { fg = "base04", modifiers = ["reversed"] }
        "ui.background" = {bg = "bg_transparent"}
      '';
    };
  };
}
