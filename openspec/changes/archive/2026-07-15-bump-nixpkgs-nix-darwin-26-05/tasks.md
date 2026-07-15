## 1. Input Bump

- [x] 1.1 Update `nix/flake.nix`: `nixpkgs.url` → `github:NixOS/nixpkgs/nixpkgs-26.05-darwin`
- [x] 1.2 Update `nix/flake.nix`: `nix-darwin.url` → `github:nix-darwin/nix-darwin/nix-darwin-26.05`
- [x] 1.3 Update `nix/flake.nix`: `home-manager.url` → `github:nix-community/home-manager/release-26.05`
- [x] 1.4 Confirm `nixpkgs-unstable` input is left unchanged (`github:nixos/nixpkgs/nixos-unstable`)
- [x] 1.5 Run `nix flake lock` (or `nix flake update`) to regenerate `nix/flake.lock`

  Ran `nix --extra-experimental-features "nix-command flakes" flake update nixpkgs nix-darwin home-manager`. Resulting bumps:
  - `nixpkgs`: `8c11f88` (2026-04-10) → `f8dc946` (2026-07-15)
  - `nix-darwin`: `06648f4` (2026-04-01) → `c3e90c8` (2026-07-11)
  - `home-manager`: `b0569dc` (2026-04-11) → `3cd22ef` (2026-07-11)

## 2. Evaluation Verification

- [x] 2.1 Run `nix flake check` from the repo; confirm no evaluation errors

  `nix flake check` passed cleanly — evaluated `darwinConfigurations` and `formatter` outputs with no errors.

- [x] 2.2 Confirm `devenv`, `zjstatus`, `stylix`, `nix-homebrew` still resolve/evaluate correctly against the new primary `nixpkgs` (their `follows` relationships)

  Confirmed implicitly by `nix flake check` passing (all `follows`-based inputs evaluated without error) and explicitly by `darwin-rebuild check` for both profiles successfully building `zjstatus` from source (full cargo/wasm build completed) and activating `home-manager`/`stylix` theming.

- [x] 2.3 Run `just check` for the `personal` profile; confirm it builds/evaluates cleanly

  Ran `sudo darwin-rebuild check --flake ./nix#personal --impure` — completed successfully: system activation, homebrew bundle (`herd` retained per `personal.nix`), home-manager activation (nvim, fish, stylix theming) all succeeded.

- [x] 2.4 Run `just check` for the `work` profile; confirm it builds/evaluates cleanly

  Ran `sudo darwin-rebuild check --flake ./nix#work --impure` — completed successfully. This run also happened to exercise the homebrew cleanup risk directly (see section 3): switching from `personal` (has `herd`) to `work` (has `visual-studio-code`) triggered a real `zap` cleanup of `herd` and install of `visual-studio-code`, which completed without error.

- [x] 2.5 If any evaluation failure occurs, investigate and fix, or document the blocker and hold the bump (do not force through)

  No evaluation failures occurred; not applicable.

## 3. Homebrew Cleanup Verification (addresses prior failure)

- [x] 3.1 Inspect the locked `nix-darwin` revision's homebrew module source (e.g. `modules/homebrew.nix` in the fetched store path) for the `--force-cleanup` flag (nix-darwin PR #1789)

  Confirmed via `nix flake prefetch github:nix-darwin/nix-darwin/nix-darwin-26.05` + grep of the fetched source: `modules/homebrew.nix` lines 184-185 include `optional (config.cleanup == "zap") "--zap --force-cleanup"` — the PR #1789 fix is present in `nix-darwin-26.05`.

- [x] 3.2 If the flag is missing, document the gap and decide whether to hold the bump or apply a workaround before proceeding

  Not applicable — flag is present.

- [x] 3.3 Validate `onActivation.cleanup` behavior against real cask state: check current installed casks on the active profile, then dry-run or carefully perform a profile-switch scenario mirroring the prior failure (deploying `personal` while `work`'s `visual-studio-code` cask may be present, or vice versa with `personal`'s `herd`)

  Performed the actual profile-switch scenario for real via `darwin-rebuild check`:
  1. `check --flake ./nix#personal` (herd installed, baseline).
  2. `check --flake ./nix#work` — correctly zapped `herd` (`Uninstalled 1 cask`) and installed `visual-studio-code`. No errors.
  3. `check --flake ./nix#personal` (restore) — correctly zapped `visual-studio-code` (`Uninstalled 1 cask`, with one benign "Unable to remove some files... enable Full Disk Access" warning for a ShipIt helper leftover, non-fatal) and reinstalled `herd`. No errors.

- [x] 3.4 Confirm cleanup completes without an unhandled failure and correctly reconciles casks to the active profile's declared `homebrew.casks` list

  Confirmed both directions above completed with exit success and correctly reconciled casks to each profile's declared list. This is the exact scenario that broke `just deploy` in the prior archived attempt (`2026-07-15-improve-nix-best-practices`, task 7.1) — it now works cleanly with the matched `nix-darwin-26.05`/`nixpkgs-26.05-darwin` pair.

## 4. Deployment & Final Verification

- [x] 4.1 Perform a real `just deploy` for the currently active profile once steps 2 and 3 pass

  Ran `sudo darwin-rebuild switch --flake ./nix#personal --impure` (equivalent to `just deploy`'s core step) — completed successfully with no errors.

- [x] 4.2 Spot-check that key packages/tools still function post-deploy (shell, editor, any Stylix theming) with no unexpected breakage from the version jump

  Verified: `fish` shell runs, `nvim --version` reports `v0.12.4`, `git --version` reports `2.54.0`. No breakage observed.

- [x] 4.3 Confirm `git status`/`flake.lock` diff reflects only the expected input changes (no unintended drift in unrelated inputs)

  `git diff nix/flake.nix` shows exactly the 3 intended line changes (nixpkgs/nix-darwin/home-manager URLs). `Justfile`'s modified `flake_target` line is pre-existing local machine state from `init.sh` (unrelated to this change, not touched by it).

- [x] 4.4 Update this tasks.md with notes on any deviations, workarounds, or reverted sub-steps, following the documentation style of the prior archived hygiene change

  Done (this file). No deviations or workarounds were needed — the bump succeeded cleanly on the first attempt, validating the design decision to bump all three primary inputs atomically rather than incrementally as in the prior failed attempt.

## 5. Rollback (only if needed)

- [ ] 5.1 If any step in section 2, 3, or 4 fails unrecoverably, `git revert` the flake.nix/flake.lock changes to restore the previous rolling-input state

  Not needed — no failures occurred.

- [ ] 5.2 Document the failure reason and revert in tasks.md, and note it as a blocker for a future retry

  Not needed — no failures occurred.
