{ pkgs, ... }:
{
  lcars = {
    shell.fish = {
      enable = true;
      pkg = pkgs.fish; # Omit or override if needed
    };
    wm.active = "yabai";
    # Status-bar feature flags. `height` is the single source of truth shared
    # between sketchybar's drawn bar (nix/modules/home/sketchybar/
    # sketchybarrc.sh, via the BAR_HEIGHT env var) and yabai's top-of-screen
    # `external_bar` reservation (nix/modules/darwin/yabai/default.nix) —
    # changing it here updates both.
    bar = {
      sketchybar.enable = false; # false restores the native macOS menu bar
      height = 28;
    };
  };
}
