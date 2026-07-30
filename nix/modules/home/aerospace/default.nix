{
  pkgs,
  lib,
  profile,
  lcars,
  ...
}:
let
  main = builtins.fromTOML (builtins.readFile ./main.toml);
  profileOverridePath = ./. + "/${profile}.toml";
  profileOverrides =
    if builtins.pathExists profileOverridePath then
      builtins.fromTOML (builtins.readFile profileOverridePath)
    else
      { };

  # `lib.recursiveUpdate` replaces arrays wholesale rather than merging
  # elements, which would silently drop main.toml's shared app-routing rules
  # whenever a profile defines its own `on-window-detected` entries. That one
  # array-typed key is concatenated explicitly instead — see design.md
  # Decision 6.
  merged = lib.recursiveUpdate main profileOverrides // {
    on-window-detected =
      (main.on-window-detected or [ ]) ++ (profileOverrides.on-window-detected or [ ]);
  };
in
{
  config = {
    programs.aerospace = {
      enable = lcars.wm.active == "aerospace";
      launchd.enable = lcars.wm.active == "aerospace";
      package = pkgs.unstable.aerospace;
      settings = merged;
    };

    # Defense-in-depth against Home Manager's own aerospace module
    # (modules/programs/aerospace.nix), which sets a fatal, synchronous
    # `onChange` hook on the generated config file that runs `aerospace
    # reload-config` unconditionally whenever the rendered TOML content
    # changes — with no error tolerance. If AeroSpace is ever left in an
    # unexpected state (not yet started, mid-restart, etc.) for any reason,
    # this hook would otherwise fail the entire `darwin-rebuild switch`
    # activation. `lib.mkForce` overrides it with a `|| true`-guarded
    # version so a future `just deploy` can never be broken by this hook,
    # regardless of AeroSpace's runtime state — this is useful independent
    # of the build-time WM-selection mechanism above (design.md Decision 7).
    # `xdg.enable` is not set in this config, so the config path matches
    # home-manager's non-xdg fallback: `.aerospace.toml`.
    #
    # This whole block must stay gated on `cfg.enable` (mirroring the
    # upstream module's own `lib.mkIf cfg.enable`): when AeroSpace is
    # disabled (e.g. `lcars.wm.active == "yabai"`), the upstream module
    # never defines `home.file.".aerospace.toml".source`, so setting
    # `onChange` unconditionally here would create a dangling/incomplete
    # file entry (onChange but no source/text), which breaks home-manager's
    # file-activation with "`.source` was accessed but has no value
    # defined." Confirmed via a real deploy failure — see design.md.
    home.file.".aerospace.toml" = lib.mkIf (lcars.wm.active == "aerospace") {
      onChange = lib.mkForce ''
        echo "AeroSpace config changed, reloading (best-effort)..."
        ${lib.getExe pkgs.unstable.aerospace} reload-config || true
      '';
    };
  };
}
