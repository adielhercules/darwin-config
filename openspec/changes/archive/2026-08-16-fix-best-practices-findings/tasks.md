## 1. Repo hygiene: stray file cleanup

- [x] 1.1 Delete `nix/modules/home/tuna/config.toml.backup-20260816-120353-530` and unstage it
      from git if currently staged
- [x] 1.2 Confirm via `git status --porcelain` that the file no longer appears (tracked, staged,
      or untracked)

## 2. Tuna config portability fix

- [x] 2.1 Edit `nix/modules/home/tuna/config.shared.toml`'s Android Studio binding to replace the
      literal `/Users/adielhercules/` segment with the file's existing `<user>` placeholder
      convention
- [x] 2.2 Verify the change by inspecting the rendered/templated output (or re-running the
      relevant home-manager build) to confirm the placeholder is substituted with the current
      user's actual username at build time, matching the pattern used by every other absolute
      path in the file

## 3. Document `pkgs.unstable.*` usages

- [x] 3.1 Add an inline comment to `nix/modules/home/zellij.nix:74` explaining why `zellij` is
      sourced from `pkgs.unstable`
- [x] 3.2 Add an inline comment to `nix/modules/home/helix.nix:7` explaining why `helix` is
      sourced from `pkgs.unstable`
- [x] 3.3 Add inline comments to `nix/modules/home/aerospace/default.nix:32` and `:61` explaining
      why `aerospace` is sourced from `pkgs.unstable`
- [x] 3.4 Add an inline comment to `nix/modules/home/sketchybar/default.nix:135` explaining why
      the aerospace package used there is sourced from `pkgs.unstable`
- [x] 3.5 Add an inline comment to `nix/darwin/home.nix:133` explaining why `difftastic` is
      sourced from `pkgs.unstable`

## 4. Stylix input pinning decision

- [x] 4.1 Research whether `nix-community/stylix` offers a release branch/tag aligned with the
      pinned NixOS 26.05 trio (`nixpkgs-26.05-darwin` / `nix-darwin-26.05` / `release-26.05`)
- [x] 4.2 If an aligned branch/tag exists: update `stylix.url` in `nix/flake.nix` to reference it
- [x] 4.3 If no aligned branch/tag exists: add an explicit comment adjacent to `stylix.url` in
      `nix/flake.nix` documenting that the input intentionally tracks its default branch, and
      how a deliberate update should be performed (e.g. `nix flake lock --update-input stylix`)
- [x] 4.4 If `stylix.url` was changed in 4.2, run `nix flake check --no-build ./nix` and `just
      check` (dry-run) to confirm the new lock entry evaluates cleanly before considering this
      task done; report results to the user before any deploy
- [x] 4.5 Fix `just check` failures surfaced by the `release-26.05` bump (two rounds):
      (a) stylix's GTK home-manager target now unconditionally sets `gtk.gtk4.theme`,
      conflicting with the pre-existing `gtk.gtk4.theme = null;` workaround in
      `nix/darwin/home.nix`; (b) an initial fix attempt setting
      `stylix.targets.gtk.enable = false;` in the darwin-level `stylix` block
      (`nix/darwin/default.nix`) failed with "option does not exist" since GTK is a
      home-manager-only stylix target. Resolved by setting
      `stylix.targets.gtk.enable = false;` in `nix/darwin/home.nix` instead (this is a
      Darwin-only config with no GTK apps) and removing the now-unnecessary workaround line.
      Verified by evaluating `config.system.build.toplevel.drvPath` directly for both
      `darwinConfigurations` outputs (personal and work profiles)

## 5. Pre-commit hook

- [x] 5.1 Rewrite `.githooks/pre-commit` to run `nix run nixpkgs#nixfmt-tree -- --ci` and
      `nix run nixpkgs#statix -- check .` against the `nix/` directory, exiting non-zero on
      failure of either check
- [x] 5.2 Verify the hook runs successfully end-to-end (e.g. `bash .githooks/pre-commit`) against
      the current repo state with no unexpected failures

## 6. Documentation and comment corrections

- [x] 6.1 Update `AGENTS.md`'s "File Locations & Organization" section to remove the stale
      `nix/paths/` reference and reflect that `rootPath` is now defined inline in
      `nix/flake.nix`
- [x] 6.2 Correct the stale comment in `nix/modules/home/opencode/default.nix` (~line 130) that
      references a nonexistent-in-context `nix/modules/home/opencode/agents/thinking.md` path,
      updating it to the actual source path used by `xdg.configFile`
      (`config/opencode/agents/thinking.md`, resolved via `opencodeSource`) — confirm the exact
      path via the file's `opencodeSource` definition before editing
- [x] 6.3 Correct the stale `(see opencode.nix)` reference in `nix/modules/home/opencode2.nix`
      (~line 7) to point at `opencode/default.nix`, since commit `9b7b910` restructured
      `opencode.nix` into the `nix/modules/home/opencode/` directory
- [x] 6.4 Correct the stale reference in `nix/modules/home/sketchybar/plugins/battery.sh`
      (~line 7) to the now-archived openspec change path
      (`openspec/changes/archive/2026-07-30-add-yabai-sketchybar/tasks.md`)

## 8. Repo-wide stale-reference scan (follow-up)

- [x] 8.1 Scan all `.nix` files and non-`.nix` files (shell scripts, top-level docs) under the
      repo for comments referencing other in-repo paths, and verify each referenced path still
      exists; fix any found stale references (see 6.4 above for the one found)

## 7. Final validation

- [x] 7.1 Stage all changes under `nix/` (`git add nix/`)
- [x] 7.2 Run `nix flake check --no-build ./nix`
- [x] 7.3 Run `nix fmt` and confirm no formatting drift remains
- [x] 7.4 Run `deadnix --fail .`
- [x] 7.5 Run `statix check .`
- [x] 7.6 Show final `git status`/`git diff` summary to the user for review before any commit
