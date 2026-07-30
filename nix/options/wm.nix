{ lib, ... }:
{
  options.lcars.wm.active = lib.mkOption {
    type = lib.types.enum [
      "yabai"
      "aerospace"
    ];
    default = "yabai";
    description = "Which tiling window manager is active. Only one of yabai/AeroSpace is ever enabled at a time (see openspec/changes/add-yabai-sketchybar/design.md, Decision 7).";
  };
}
