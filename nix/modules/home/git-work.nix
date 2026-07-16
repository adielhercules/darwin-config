# Work-profile git identity. Name matches the personal profile; email is
# sourced from the local, gitignored .local/git-email file (see
# init.sh --email and nix/lib/git-email.nix), which hard-aborts the build if
# unset.
{ rootPath, lib, ... }:
{
  programs.git.settings.user = {
    name = "Adiel Hercules";
    email = import ../../lib/git-email.nix { inherit rootPath lib; };
  };
}
