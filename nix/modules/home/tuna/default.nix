{
  config,
  lib,
  profile,
  lcars,
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

  # Only one of the two WM Tuna groups (`a`/Aerospace, `y`/Yabai) is ever
  # meaningful, since `lcars.wm.active` (nix/options/wm.nix) enables exactly
  # one WM at build time (design.md Decision 7). Each config.toml wraps both
  # groups in sentinel line-comments (`# WM-GROUP-BEGIN:<wm>` / `#
  # WM-GROUP-END:<wm>`), and the inactive group is stripped out here via a
  # simple line-based filter rather than a `fromTOML`/re-serialize
  # round-trip, which would silently drop the file's many hand-written
  # comment blocks (nixpkgs' TOML tooling has no comment-preservation).
  inactiveWm = if lcars.wm.active == "yabai" then "aerospace" else "yabai";

  # Drops every line from (and including) `# WM-GROUP-BEGIN:<marker>`
  # through (and including) `# WM-GROUP-END:<marker>`, keeping all other
  # lines (and their order) untouched. Applied once, to strip the inactive
  # WM's entire group.
  stripMarkedSection =
    marker: lines:
    let
      beginMarker = "# WM-GROUP-BEGIN:${marker}";
      endMarker = "# WM-GROUP-END:${marker}";
      # Drops lines until (and including) `endMarker` is found.
      skipToEnd =
        ls:
        if ls == [ ] then
          [ ]
        else if lib.head ls == endMarker then
          lib.tail ls
        else
          skipToEnd (lib.tail ls);
      go =
        ls:
        if ls == [ ] then
          [ ]
        else if lib.head ls == beginMarker then
          go (skipToEnd (lib.tail ls))
        else
          [ (lib.head ls) ] ++ go (lib.tail ls);
    in
    go lines;

  # Strips only the bare sentinel marker lines themselves (BEGIN/END),
  # leaving everything between them intact — applied to the active WM's
  # group, since its content should remain, just without the now-redundant
  # marker comments.
  stripMarkerLines =
    marker: lines:
    let
      beginMarker = "# WM-GROUP-BEGIN:${marker}";
      endMarker = "# WM-GROUP-END:${marker}";
    in
    builtins.filter (l: l != beginMarker && l != endMarker) lines;

  configLines = lib.splitString "\n" templatedConfig;
  linesWithoutInactiveGroup = stripMarkedSection inactiveWm configLines;
  linesWithoutActiveMarkers = stripMarkerLines lcars.wm.active linesWithoutInactiveGroup;
  filteredConfig = lib.concatStringsSep "\n" linesWithoutActiveMarkers;
in
{
  # 1) Install the managed file
  home.file."Library/Application Support/Tuna/config.toml" = {
    text = filteredConfig;
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
