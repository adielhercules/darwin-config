{ lib, ... }:
{
  options.lcars.bar.height = lib.mkOption {
    type = lib.types.ints.between 20 64;
    default = 28;
    description = ''
      Height in pixels of the sketchybar status bar. Single source of truth
      shared by sketchybar itself (threaded into
      nix/modules/home/sketchybar/sketchybarrc.sh as its BAR_HEIGHT env var)
      and yabai's `external_bar` top-of-screen reservation
      (nix/modules/darwin/yabai/default.nix), so the drawn bar and the
      reserved padding can never drift apart.
    '';
  };

  options.lcars.bar.sketchybar.enable = lib.mkEnableOption "the sketchybar status bar";
}
