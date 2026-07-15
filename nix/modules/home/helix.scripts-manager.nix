{ ... }:

let
  targetPath = "helix/yazi-picker.sh";
in
{
  # 1) Install the managed file
  home.file.".config/${targetPath}" = {
    source = ./helix/yazi-picker.sh;
    # Use a symlink by default; for a real file copy, set `copy = true;`
    # copy = true;
  };

  # 2) Activation step to create a backup of any pre-existing target
  # I shall not update the script from outside
}
