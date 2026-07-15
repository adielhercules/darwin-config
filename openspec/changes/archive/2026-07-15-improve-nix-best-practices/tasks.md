## 1. Formatter

- [x] 1.1 Add `formatter.${system} = pkgs.nixfmt-rfc-style;` output to `nix/flake.nix`
- [x] 1.2 Run `nix fmt` across the repo and commit the resulting formatting changes as a separate, clearly-labeled commit
- [x] 1.3 Verify `nix fmt` exits successfully with no errors

## 2. CI Workflow

- [x] 2.1 Create `.github/workflows/nix-check.yml` using `cachix/install-nix-action` (with flakes enabled) on `ubuntu-latest`
- [x] 2.2 Add a `nix flake check` step (scoped to `./nix`, `--no-build`/eval-appropriate flags as needed)
- [x] 2.3 Add a formatting-check step (e.g. `nix fmt -- --check` or equivalent verification that files match formatter output)
- [x] 2.4 Add `deadnix` and `statix` steps (installed via `nix run`/`nix shell` from nixpkgs, or as flake check inputs)
- [x] 2.5 Trigger workflow on `push` and `pull_request`
- [ ] 2.6 Verify the workflow passes on the current working branch before merging further changes

## 3. Flake Input Hygiene

- [x] 3.1 Add `inputs.nixpkgs.follows = "nixpkgs";` to the `devenv` input in `nix/flake.nix`
- [x] 3.2 Add `inputs.nixpkgs.follows = "nixpkgs";` to the `zjstatus` input in `nix/flake.nix`
- [x] 3.3 Run `nix flake lock` / `nix flake check` to regenerate `flake.lock` and verify evaluation succeeds
- [x] 3.4 If `devenv`'s `follows` breaks evaluation or the `unstable.devenv` package, revert only that input's `follows` line and add a code comment documenting why
- [x] 3.5 If `zjstatus`'s `follows` breaks evaluation or its build, revert only that input's `follows` line and add a code comment documenting why
- [x] 3.6 Confirm final `flake.lock` reflects whichever `follows` additions were kept

## 4. Dead Code Removal

- [x] 4.1 Delete the orphaned/unused `nix/home/fish.nix` (confirm no imports reference it before deleting)
- [x] 4.2 Remove or fix the `up-secrets` recipe in `Justfile` (no `secrets` flake input exists) — default action: remove the recipe
- [x] 4.3 Determine whether `nix/modules/home/leader_key.nix` is still wanted; ask the user if ambiguous
- [x] 4.4 If not wanted: delete `nix/modules/home/leader_key.nix`, its `leader_key/config.json` asset, and the stale commented-out import in `darwin/home.nix`; if wanted: re-enable the import instead of deleting
- [x] 4.5 Remove the stale commented-out `zsh` config block in `darwin/home.nix`
- [x] 4.6 Remove the vague stale comment in `darwin/home.nix` referencing the nonexistent `modules/home/darwin` path
- [x] 4.7 Remove the stale commented-out `mr.fish` `xdg.configFile` entry in `modules/home/fish.nix`

## 5. Option & Profile Guard Refactors

- [x] 5.1 Refactor `nix/options/shell.nix` to declare the `lcars.shell.fish` enable toggle via `lib.mkEnableOption "Fish shell configuration"`, preserving any non-boolean sub-options as-is
- [x] 5.2 Verify existing consumers (`darwin/home.nix`, `darwin/default.nix`) still read `lcars.shell.fish.enable` correctly with unchanged default behavior
- [x] 5.3 Add an assertion/guard in `nix/darwin/default.nix` (e.g. `assert builtins.elem profile [ "personal" "work" ]`) with a clear custom error message for invalid profile names
- [x] 5.4 Verify both `personal` and `work` profiles still build/evaluate successfully (`just check`)
- [x] 5.5 Verify an intentionally-invalid profile name now produces a clear assertion error (manual test, then revert the test invocation)

## 6. Final Verification

- [x] 6.1 Run `just check` locally to confirm both profiles still build cleanly end-to-end
- [x] 6.2 Run `nix fmt` once more to confirm no formatting drift remains
- [ ] 6.3 Confirm CI workflow passes on the final state of the branch
- [x] 6.4 Review diff for completeness against proposal.md's "What Changes" list

## 7. Follow-up (out of scope for this change)

- [ ] 7.1 Homebrew bundle `--cleanup` switch is deprecated with no replacement, and `brew bundle` prompts to run `brew bundle cleanup --force` — investigate replacing/removing the deprecated flag and decide whether to auto-run cleanup (unrelated to this change; noted during `just check` verification on 2026-07-15).

  **Investigated and reverted (2026-07-15):** Root cause is `nix-darwin`'s `modules/homebrew.nix` using the old `--cleanup`/`--cleanup --zap` flags without `--force-cleanup`, required by a newer Homebrew CLI cleanup-flag rework. This is a known nix-darwin bug fixed upstream in [nix-darwin/nix-darwin#1789](https://github.com/nix-darwin/nix-darwin/pull/1789) (merged 2026-06-17).

  Attempted fix: `nix flake update nix-darwin` (bumped `06648f4` → `a4cf1d1`). Confirmed the fix (`--force-cleanup`/`--zap --force-cleanup`) was present in the updated module source and `nix flake check` passed. **However, `just deploy` then failed** with a hard assertion from nix-darwin's release-branch matching: nix-darwin `26.11` requires nixpkgs `26.05`+-equivalent branch alignment, and the currently-pinned `nixpkgs` (`nixpkgs-unstable`) isn't there yet — `eval-config.nix:25` throws `"nix-darwin now uses release branches that correspond to Nixpkgs releases..."`.

  **Reverted** the `nix-darwin` input bump (commit `63662bb`, reverting `9532061`) to restore the previously-working state. Verified via `nix flake check` and a real `just deploy` that the revert fully restores normal deploy behavior (with the original, non-blocking deprecation warning back, as before).

  **Actual trigger for the deploy failure observed during verification:** unrelated to the deprecation warning itself — `visual-studio-code` is a `work.nix`-only cask that happened to be installed locally while deployed on the `personal` profile, so `homebrew.onActivation.cleanup = "zap"` correctly wants to remove it; the new Homebrew semantics require an explicit `--force` for that removal, which the old (currently pinned) `nix-darwin`'s `--cleanup` invocation doesn't pass — hence the dry-run "Would uninstall casks: visual-studio-code" and non-zero exit.

  **Decision: skip for now.** A real fix requires bumping `nixpkgs` and `nix-darwin` together to mutually compatible newer releases — non-trivial scope/risk increase, and out of scope for a hygiene-only change. Recommend a dedicated future change (e.g. `bump-nixpkgs-nix-darwin`) to handle the version bump deliberately, with its own validation. Until then, the workaround is a manual `brew bundle cleanup --force` (using the real Brewfile, not an empty one) when cask drift blocks a `deploy`.
