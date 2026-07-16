# Profile-aware module path resolver.
#
# Given a `base` path (without extension) and a `profile` name, resolves to
# the profile-specific variant if it exists, falling back to the shared base
# path otherwise. Used to keep profile-dependent imports (aerospace, tuna,
# fish bindings, etc.) out of `home.nix`'s import list logic.
#
# Resolution order:
#   1. "${base}${sep}${profile}${ext}"  (profile-specific variant)
#   2. "${base}${ext}"                  (shared fallback)
#
# Examples:
#   resolveModule { profile = "personal"; base = ../modules/home/ghostty; }
#     -> falls back to ../modules/home/ghostty.nix (no ghostty.personal.nix exists)
#
#   resolveModule { profile = "work"; base = ../modules/home/aerospace; ext = ""; }
#     -> falls back to ../modules/home/aerospace (directory, default.nix auto-imported)
#
#   resolveModule { profile = "personal"; base = ../modules/home/fish; ext = ".bindings"; sep = "-"; }
#     -> ../modules/home/fish-personal.bindings (if it exists)
_: {
  resolveModule =
    {
      profile,
      base,
      ext ? ".nix",
      sep ? ".",
    }:
    let
      baseStr = toString base;
      profilePath = "${baseStr}${sep}${profile}${ext}";
      sharedPath = "${baseStr}${ext}";
    in
    if builtins.pathExists profilePath then profilePath else sharedPath;
}
