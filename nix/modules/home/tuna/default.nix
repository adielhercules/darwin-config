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
  # elements (it replaces arrays wholesale), and nixpkgs' `fromTOML` would
  # silently drop this file's many hand-written comments on a
  # parse/re-serialize round-trip. Instead, tuna uses a plain-text
  # shared-base + per-profile-delta merge: `config.shared.toml` holds the
  # content common to both profiles, and `<profile>/config.delta.toml`
  # holds only that profile's additions, expressed as one or more
  # `# @patch:append <path>` / `# @end` blocks (see the delta files
  # themselves for the directive format). `applyPatches` below locates each
  # target array in the shared text by walking `<path>` against `key`
  # fields (or, for `catalogs.globalScopes`, a fixed anchor point) and
  # splices the delta's lines in as the last entry of that array.
  #
  # This mechanism is intentionally limited to tail-append: it can add new
  # array entries at the end of a targeted array, but cannot replace,
  # remove, or insert-after an existing entry. Where a profile's original
  # entries sat in the middle of a shared array, the merged output places
  # them at the end instead — a deliberate, documented cosmetic reordering
  # (see the delta files' header comments for specifics).
  sharedConfigText = builtins.readFile ./config.shared.toml;
  deltaConfigText = builtins.readFile (./. + "/${profile}/config.delta.toml");

  # ---- Delta directive parsing -------------------------------------------
  #
  # Scans the delta file's lines for `# @patch:append <path>` ... `# @end`
  # pairs, collecting the (unmodified) lines in between as that patch's
  # `body`. Returns an ordered list of `{ path, body }` attrsets; ordering
  # is preserved so patches are applied in the same order they're written.
  patchBeginPrefix = "# @patch:append ";
  patchEndMarker = "# @end";

  parseDeltaPatches =
    text:
    let
      lines = lib.splitString "\n" text;
      # `acc` collects finished `{ path, body }` records; `cur` is either
      # `null` (not currently inside a patch block) or an in-progress
      # `{ path, body }` record being accumulated line-by-line.
      go =
        acc: cur: ls:
        if ls == [ ] then
          acc
        else
          let
            line = lib.head ls;
            rest = lib.tail ls;
          in
          if cur == null then
            if lib.hasPrefix patchBeginPrefix line then
              go acc {
                path = lib.removePrefix patchBeginPrefix line;
                body = [ ];
              } rest
            else
              go acc null rest
          else if line == patchEndMarker then
            go (acc ++ [ cur ]) null rest
          else
            go acc (cur // { body = cur.body ++ [ line ]; }) rest;
    in
    go [ ] null lines;

  deltaPatches = parseDeltaPatches deltaConfigText;

  # ---- Patch application --------------------------------------------------
  #
  # Every non-blank, non-comment array-of-tables entry in the shared file
  # is indented by 4 spaces per nesting level: top-level
  # `[[comboMode.bindings]]` entries (and their `key`/`label`/etc fields)
  # sit at 0 spaces, their `.children` entries at 4 spaces, `.children.
  # children` at 8, and so on. A `path` like `a/s/w` therefore identifies,
  # in order: a top-level entry whose `key = 'a'` sits at 0 spaces, inside
  # which a `.children` entry whose `key = 's'` sits at 4 spaces, inside
  # which a `.children.children` entry whose `key = 'w'` sits at 8 spaces —
  # and the patch body (at 12 spaces, one level deeper still) is appended
  # as the last `.children.children.children` entry inside that `w` block.
  indentFor = depth: lib.concatStrings (lib.replicate (depth * 4) " ");

  # Number of leading space characters on `line`.
  leadingSpaces =
    line:
    let
      go = i: if lib.substring i 1 line == " " then go (i + 1) else i;
    in
    go 0;

  # Does `line` (at exactly `indent` spaces) look like `key = '<key>'`
  # (handling the one binding in this file whose key is itself a single
  # quote, which is written with double quotes instead)?
  isKeyLine =
    indent: key: line:
    let
      prefix = indentFor indent;
    in
    line == "${prefix}key = '${key}'" || line == "${prefix}key = \"${key}\"";

  # Does `line` mark the start of a sibling (or shallower/parent) block —
  # i.e. is its indentation no deeper than `indent`, and, once its leading
  # spaces are stripped, does it begin with `[` (matching both
  # `[[array.of.tables]]` headers and plain `[section]` headers)? Used to
  # find the end boundary of the block we're appending into.
  isBoundaryLine =
    indent: line:
    let
      ls = leadingSpaces line;
      trimmed = lib.substring ls (lib.stringLength line - ls) line;
    in
    ls <= indent && lib.hasPrefix "[" trimmed;

  # 0-based index of the first element of `list` (starting the scan at
  # `from`) satisfying `pred`, or `lib.length list` ("not found / end of
  # list") if none match.
  findIndexFromOr =
    from: pred: list:
    let
      n = lib.length list;
      go =
        i:
        if i >= n then
          n
        else if pred (lib.elemAt list i) then
          i
        else
          go (i + 1);
    in
    go from;

  # Walks `path` (already split on "/") against `lines`, narrowing the
  # search range one path segment at a time, and returns the absolute
  # index in `lines` immediately before which a new entry should be
  # spliced to become the last child of the final matched block.
  resolveAppendIndex =
    lines: pathComponents:
    let
      initial = {
        rangeStart = 0;
        rangeEnd = lib.length lines;
        depth = 0;
      };
      step =
        state: comp:
        let
          indent = state.depth * 4;
          slice = lib.sublist state.rangeStart (state.rangeEnd - state.rangeStart) lines;
          relMatch = findIndexFromOr 0 (isKeyLine indent comp) slice;
          matchIdx = state.rangeStart + relMatch;
          relBoundary = findIndexFromOr (relMatch + 1) (isBoundaryLine indent) slice;
          boundaryIdx = state.rangeStart + relBoundary;
        in
        {
          rangeStart = matchIdx;
          rangeEnd = boundaryIdx;
          depth = state.depth + 1;
        };
      final = lib.foldl' step initial pathComponents;
    in
    final.rangeEnd;

  # Splices `body` (a list of lines) into `lines` at `idx`, adding blank
  # lines before and after to match the file's existing style of
  # separating sibling `[[...]]` entries with a single blank line. Any
  # resulting runs of 2+ consecutive blank lines (e.g. because `idx`
  # already sat right after an existing blank line) are collapsed
  # afterwards by `collapseBlankRuns`.
  spliceAt =
    lines: idx: body:
    (lib.sublist 0 idx lines)
    ++ [ "" ]
    ++ body
    ++ [ "" ]
    ++ (lib.sublist idx (lib.length lines - idx) lines);

  collapseBlankRuns =
    lines:
    let
      go =
        prevBlank: ls:
        if ls == [ ] then
          [ ]
        else
          let
            line = lib.head ls;
            rest = lib.tail ls;
            isBlank = line == "";
          in
          if isBlank && prevBlank then go true rest else [ line ] ++ go isBlank rest;
    in
    go false lines;

  # Applies one patch record to `text` (a full config text, not yet split
  # into lines outside this function).
  applyPatch =
    text: patch:
    let
      lines = lib.splitString "\n" text;
      idx =
        if patch.path == "catalogs.globalScopes" then
          # Not keyed by `key` — this dotted path is a fixed anchor
          # instead: the catalogs section always ends right before the
          # first top-level `[[comboMode.bindings]]` entry in this file.
          findIndexFromOr 0 (line: line == "[[comboMode.bindings]]") lines
        else
          resolveAppendIndex lines (lib.splitString "/" patch.path);
    in
    lib.concatStringsSep "\n" (collapseBlankRuns (spliceAt lines idx patch.body));

  applyPatches = sharedText: patches: lib.foldl' applyPatch sharedText patches;

  mergedConfigText = applyPatches sharedConfigText deltaPatches;

  # The merged config text uses a redacted `<user>` placeholder in place of
  # a real username inside a Tuna deep-link URL's URL-encoded home
  # directory path (%252FUsers%252F<user>%252F...). Substitute it at build
  # time for the current user's actual username, so the deployed file is
  # portable and no real username is ever committed.
  templatedConfig = builtins.replaceStrings [ "<user>" ] [ config.home.username ] mergedConfigText;

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
