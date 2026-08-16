## Why

A local-LLM best-practices audit (`BEST_PRACTICES_ANALYSIS_BY_QWEN3.8_OLLAMA_LOCAL.md`) was run
against this repo and independently re-verified, finding-by-finding, against the actual repo
state (see `BEST_PRACTICES_ANALYSIS_BY_QWEN3.8_OLLAMA_LOCAL-v2-refined.md` for the corrected
version, since updated 2026-08-16 to reflect a subsequent `opencode.nix` → `opencode/` restructure
— see commit `9b7b910`). After verification, several findings are real, low-risk
hygiene/reproducibility gaps worth fixing now: a stray backup file staged for commit, a hardcoded
personal path in a git-tracked Tuna config source file, a no-op pre-commit hook that implies
checks aren't happening, stale documentation referencing a removed directory, undocumented
`pkgs.unstable.*` usages, a stylix flake input with no branch/tag pin (unlike the other three
core inputs), and two stale source-path comments in the `opencode` module (one carried over from
before the rename, one newly introduced by the rename itself). None of these are
urgent/breaking, but they're small, well-understood, and cheap to fix in one pass.

Two findings from the original audit were investigated and intentionally **excluded** from this
change because they are either already-accepted tradeoffs or false claims:
- The `builtins.getEnv "SUDO_USER"/"USER"/"SUDO_UID"` impurity in `nix/darwin/default.nix` is
  already a documented, deliberate design decision (see the existing `dynamic-user-detection`
  spec and its originating design docs) with an intentional hard-abort safety net. It is not
  being changed by this proposal.
- The claim that `.DS_Store` is tracked in git under `nix/modules/home/tuna/` is false
  (`git ls-files` confirms it is not tracked); no action needed.
- The claim that `opencode.nix`/`opencode2.nix` represented duplicate/abandoned work was false at
  the time of the original audit — both were intentional, live, and served different purposes
  (config generation vs. a separate beta binary install). This is still true today; only the
  stale comment paths need fixing (see below for the updated locations after the rename).

## What Changes

- Delete the stray backup file `nix/modules/home/tuna/config.toml.backup-20260816-120353-530`
  (currently staged for commit) and confirm it is not re-created by the Tuna backup activation
  script under its tracked name.
- Fix the one hardcoded absolute path in `nix/modules/home/tuna/config.shared.toml` (the Android
  Studio binding) to use the file's existing `<user>` placeholder convention instead of the
  literal `adielhercules` username.
- Add short explanatory comments to every `pkgs.unstable.*` usage (`zellij.nix`, `helix.nix`,
  `aerospace/default.nix` ×2, `sketchybar/default.nix`, `nix/darwin/home.nix`'s difftastic
  reference) documenting why the unstable channel is needed instead of stable.
- Pin (or explicitly document as intentionally-floating) the `stylix` flake input, which
  currently has no branch/tag qualifier unlike the `nixpkgs`/`home-manager`/`nix-darwin` trio
  that are all pinned to the 26.05 release train.
- Wire `.githooks/pre-commit` to actually run `nix fmt --check` + `statix check .` (mirroring
  CI), or remove the hook entirely if local pre-commit enforcement is not desired — decision to
  be made explicit in design.md.
- Fix the stale `nix/paths/` reference in `AGENTS.md`'s "File Locations & Organization" section
  (that directory no longer exists; `rootPath` now lives inline in `nix/flake.nix`).
- Fix the stale comment in `nix/modules/home/opencode/default.nix` (~line 130, since commit
  `9b7b910` renamed `opencode.nix` into this directory) that references a path
  (`nix/modules/home/opencode/agents/thinking.md`) inconsistent with the file's own header
  comment and `opencodeSource` definition, both of which correctly point at
  `config/opencode/agents/thinking.md`.
- Fix the stale `(see opencode.nix)` reference in `nix/modules/home/opencode2.nix` (~line 7),
  which is now inaccurate since that file was restructured into `nix/modules/home/opencode/
  default.nix` by the same rename.
- Fix a similarly stale in-repo path reference in
  `nix/modules/home/sketchybar/plugins/battery.sh` (~line 7), which points at an openspec
  change proposal path that has since been archived.

## Capabilities

### New Capabilities

- `tuna-config-portability`: The Tuna config's tracked source file(s) (`config.shared.toml` and
  per-profile delta files) must not contain hardcoded personal usernames in absolute paths —
  they must use the file's existing `<user>` placeholder convention instead.

### Modified Capabilities

- `nix-repo-hygiene`: Add requirements covering (a) no stray/backup files committed to the
  repository, (b) `pkgs.unstable.*` usages must carry an inline comment explaining why the
  unstable channel is required, (c) the pre-commit hook must either mirror CI checks or not
  exist, (d) in-repo path references (both prose documentation like `AGENTS.md` and inline code
  comments) must stay accurate after files are renamed or moved.
- `nixpkgs-darwin-version-pinning`: Add a requirement covering the `stylix` flake input's
  pinning/documentation posture relative to the matched 26.05 trio.

## Impact

- Affected files: `nix/modules/home/tuna/config.toml.backup-20260816-120353-530` (deleted),
  `nix/modules/home/tuna/config.shared.toml`, `nix/modules/home/zellij.nix`,
  `nix/modules/home/helix.nix`, `nix/modules/home/aerospace/default.nix`,
  `nix/modules/home/sketchybar/default.nix`, `nix/modules/home/sketchybar/plugins/battery.sh`,
  `nix/darwin/home.nix`, `nix/flake.nix`, `.githooks/pre-commit`, `AGENTS.md`,
  `nix/modules/home/opencode/default.nix`, `nix/modules/home/opencode2.nix`.
- No changes to deployed system behavior are expected (all changes are comments, docs, one
  path-portability fix, and repo hygiene) except possibly the `stylix` input pin, which could
  change the resolved stylix revision on the next `nix flake update` — to be handled carefully
  per design.md.
- No changes to the `dynamic-user-detection` spec or its underlying `getEnv` behavior.
