{ config, lib, ... }:

let
  backupExt = ".backup";
  targetPath =
    "${config.home.homeDirectory}/.config/omnivm/settings.json";
  backup = "${targetPath}${backupExt}";
in {
  # 1) Install the managed file
  home.file.".config/omnivm/settings.json" = {
    source = ./omnivm/settings.json;
    # Use a symlink by default; for a real file copy, set `copy = true;`
    # copy = true;
  };

  # 2) Activation step to create a backup of any pre-existing target
  home.activation.backupLeaderKeyConfig =
    lib.hm.dag.entryBefore [ "linkGeneration" ] ''
      set -euo pipefail

      target="${targetPath}"
      backup="${targetPath}${backupExt}"

      # If the target exists and isn't already the exact content we're linking,
      # move it aside to a backup extension.
      if [ -e "$target" ] && [ ! -L "$target" ]; then
        # Avoid overwriting an existing backup; add numeric suffix if needed.
        if [ -e "$backup" ]; then
          i=1
          while [ -e "${backup}.$i" ]; do
            i=$((i+1))
          done
          mv "$target" "${backup}.$i"
        else
          mv "$target" "$backup"
        fi
      fi
    '';
}
