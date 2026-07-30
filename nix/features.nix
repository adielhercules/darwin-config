{ pkgs, ... }:
{
  lcars.shell.fish = {
    enable = true;
    pkg = pkgs.fish; # Omit or override if needed
  };
  lcars.wm.active = "yabai";
}
