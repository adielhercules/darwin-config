{ config, lib, profile, ... }:

let
  backupExt = ".backup";
  targetPath =
    "${config.home.homeDirectory}/Library/Application Support/Tuna/config.toml";
  backup = "${targetPath}${backupExt}";

  # Tuna's per-profile diffs live in deeply nested [[comboMode.bindings]]
  # arrays; `lib.recursiveUpdate` cannot selectively merge individual array
  # elements (it replaces arrays wholesale), so — unlike aerospace — tuna
  # uses full, independently-maintained per-profile configs rather than a
  # partial merge. `config.shared.toml` is kept only as a human-authoring
  # reference/diff anchor; it is not read or merged programmatically.
  activeConfig = if profile == "work" then
    ./work/config.toml
  else
    ./personal/config.toml;
in {
  # 1) Install the managed file
  home.file."Library/Application Support/Tuna/config.toml" = {
    source = activeConfig;
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
