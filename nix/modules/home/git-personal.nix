# Personal-profile git identity. The email is managed imperatively by
# init.sh --email, which writes ~/.config/git/config.local. Home-manager
# includes that file via programs.git.includes (see home.nix).
_: {
  programs.git.settings.user = {
    name = "Adiel Hercules";
  };
}
