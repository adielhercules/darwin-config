{ lib, pkgs, ... }: {
  config = {
    programs = {
      helix = {
        enable = true;
        package = pkgs.unstable.helix;
        settings = lib.mkForce {
          theme = "lcars";
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
            indent-guides = { render = true; };
            # Diagnostics
            end-of-line-diagnostics = "hint";
            inline-diagnostics = { cursor-line = "warning"; };
            # Usability tunings
            jump-label-alphabet = "ntesiroahdmgcxzlpufywqjbkv";
            # Input setup
            mouse = false;
            lsp = { display-inlay-hints = true; };
          };
          keys = {
            normal = {
              "C-y" = "copy_between_registers";
              "C-," = "command_mode";
              "C-e" = [
                ":sh rm -f /tmp/files2open"
                ''
                  :insert-output yazi "%{buffer_name}" --chooser-file=/tmp/files2open''
                ":redraw"
                ":open /tmp/files2open"
                "select_all"
                "split_selection_on_newline"
                "goto_file"
                ":buffer-close! /tmp/files2open"
              ];
              "C-E" = ":sh zellij run -n Yazi -c -f -x 10%% -y 10%% --width 80%% --height 80%% -- bash ~/.config/helix/yazi-picker.sh open %{buffer_name}";
              "C-l" =
                [ ":new" ":insert-output lazygit" ":buffer-close!" ":reload-all" ];
              "C-a" =
                [ ":new" ":insert-output opencode" ":buffer-close!" ":reload-all" ];
              "tab" = ":buffer-next";
              "S-tab" = ":buffer-previous";
              "]" = { b = ":buffer-next"; };
              "[" = { b = ":buffer-previous"; };
              space = {
                c = ":buffer-close";
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
    xdg.configFile = {
      "helix/themes/lcars.toml".text = ''
        inherits = 'stylix'

        "ui.cursor.primary" = { fg = "base04", modifiers = ["reversed"] }
        "ui.background" = {bg = "bg_transparent"}
      '';
    };
  };
}
