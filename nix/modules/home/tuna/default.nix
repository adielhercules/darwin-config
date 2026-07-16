{
  config,
  lib,
  profile,
  ...
}:

let
  backupExt = ".backup";
  targetPath = "${config.home.homeDirectory}/Library/Application Support/Tuna/config.toml";
  backup = "${targetPath}${backupExt}";

  # Tuna's per-profile diffs live in deeply nested [[comboMode.bindings]]
  # arrays; `lib.recursiveUpdate` cannot selectively merge individual array
  # elements (it replaces arrays wholesale), so — unlike aerospace — tuna
  # uses full, independently-maintained per-profile configs rather than a
  # partial merge. `config.shared.toml` is kept only as a human-authoring
  # reference/diff anchor; it is not read or merged programmatically.
  activeConfig = if profile == "work" then ./work/config.toml else ./personal/config.toml;

  # The per-profile config.toml files use a redacted `<user>` placeholder in
  # place of a real username inside a Tuna deep-link URL's URL-encoded home
  # directory path (%252FUsers%252F<user>%252F...). Substitute it at build
  # time for the current user's actual username, so the deployed file is
  # portable and no real username is ever committed.
  templatedConfig = builtins.replaceStrings [ "<user>" ] [ config.home.username ] (
    builtins.readFile activeConfig
  );
in
{
  # 1) Install the managed file
  home.file."Library/Application Support/Tuna/config.toml" = {
    text = templatedConfig;
  };

  # 2) Activation step to create a backup of any pre-existing target
  home.activation.backupLeaderKeyConfig = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
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
