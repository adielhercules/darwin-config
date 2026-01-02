{ pkgs, lib, ... }: {
  config = {
    programs = {
      ghostty = {
        enable = true;
        # For darwin we use the cask
        package = null;
        settings = {
          font-size = 16;
          font-family = "Monaspace Neon";
          font-family-bold = "Monaspace Xenon";
          font-family-italic = "Monaspace Radon";
          font-family-bold-italic = "Monaspace Krypton";
          background-opacity = 0.9;
          background-blur-radius = 20;
          window-inherit-font-size = false;
          macos-titlebar-style = "tabs";

          # Exit without prompt
          confirm-close-surface = false;
          #macos-option-as-alt = true;
          #keybind = [ ] ++ lib.optionals pkgs.stdenv.isDarwin [
          # Fix for MacOS keys
          #  "alt+left=unbind"
          #  "alt+right=unbind"
          #];
        };
      };

    };
  };
}
