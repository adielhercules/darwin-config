# Work-profile-only yabai overrides, mirroring
# nix/modules/home/aerospace/work.toml: adds Teams/Outlook/Edge app-routing
# rules. Teams and Outlook route to desk1 (Communications, shared across
# profiles), while Edge routes to desk6 (Browsing, shared across profiles,
# labeled in ./default.nix).
#
# Returns a raw extraConfig string fragment (not a NixOS/nix-darwin module)
# — see the profileExtraConfig plumbing in ./default.nix, which imports
# this file directly and appends its contents to the shared extraConfig.
#
# Teams/Outlook/Edge are installed manually on the work machine (not
# managed via Homebrew), per the corresponding tuna work-profile "Open"
# group entries — see aerospace/work.toml for the equivalent aerospace-side
# comment.
''
  # Work-only: Teams/Outlook (Communications, desk1) and Edge (Browsing,
  # desk6) routing, mirroring aerospace/work.toml. desk6's label and
  # monitor assignment now live in ./default.nix since Browsing/Dia
  # applies to both profiles.
  yabai -m rule --add app="^Microsoft Teams$" space=desk1    # com.microsoft.teams2
  yabai -m rule --add app="^Microsoft Outlook$" space=desk1  # com.microsoft.Outlook
  yabai -m rule --add app="^Microsoft Edge$" space=desk6     # com.microsoft.edgemac
''
