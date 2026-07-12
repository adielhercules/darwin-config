{ pkgs, lib, profile, ... }:
let
  main = builtins.fromTOML (builtins.readFile ./main.toml);
  profileOverridePath = ./. + "/${profile}.toml";
  profileOverrides = if builtins.pathExists profileOverridePath then
    builtins.fromTOML (builtins.readFile profileOverridePath)
  else
    { };

  # `lib.recursiveUpdate` replaces arrays wholesale rather than merging
  # elements, which would silently drop main.toml's shared app-routing rules
  # whenever a profile defines its own `on-window-detected` entries. That one
  # array-typed key is concatenated explicitly instead — see design.md
  # Decision 6.
  merged = lib.recursiveUpdate main profileOverrides // {
    on-window-detected = (main.on-window-detected or [ ])
      ++ (profileOverrides.on-window-detected or [ ]);
  };
in {
  config = {
    programs.aerospace = {
      enable = true;
      launchd.enable = true;
      package = pkgs.unstable.aerospace;
      settings = merged;
    };
  };
}
