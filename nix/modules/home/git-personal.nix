{ rootPath, lib, ... }:
{
  programs.git.settings.user = {
    name = "Adiel Hercules";
    email = import ../../lib/git-email.nix { inherit rootPath lib; };
  };
}
