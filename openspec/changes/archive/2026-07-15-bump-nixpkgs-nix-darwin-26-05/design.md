## Context

This is a single-user, two-profile (`personal`/`work`) nix-darwin + home-manager flake. The primary `nixpkgs`, `nix-darwin`, and `home-manager` inputs currently move independently: `nixpkgs` tracks the rolling `nixpkgs-unstable` branch, `nix-darwin` tracks rolling `master`, and `home-manager` defaults to `master`. A prior hygiene change attempted to advance only `nix-darwin` and hit a hard failure at `just deploy`: newer `nix-darwin` revisions assert that the `nixpkgs` input is on a release branch matching nix-darwin's own release train (e.g. `nixpkgs-26.05-darwin` for `nix-darwin-26.05`), and reject a rolling `nixpkgs-unstable` pin outright with an explicit error message. That change was reverted and explicitly deferred a "bump nixpkgs and nix-darwin together" follow-up — this change is that follow-up.

Ground-truthed via `git ls-remote --heads` against the real GitHub repos (not just docs, since generic web research can be unreliable about "latest" given the current date): `nixos-26.05` / `nixpkgs-26.05-darwin` / `nix-darwin-26.05` / `release-26.05` all exist and are the current latest matched stable trio, superseding the previously-discussed `25.11` train (itself confirmed to still exist as `nixpkgs-25.11-darwin` / `nix-darwin-25.11` / `release-25.11`, but one release behind).

A second, independently-discovered risk from the same prior attempt: nix-darwin's homebrew module previously invoked `brew bundle cleanup`/`--zap` without the `--force-cleanup` flag that newer Homebrew CLI versions require for cask removal during `onActivation.cleanup = "zap"`. This was fixed upstream in nix-darwin PR #1789 (merged 2026-06-17), which predates the `nix-darwin-26.05` branch cut, so the fix should already be present — but this must be verified, not assumed, since it was the proximate cause of the previous deploy failure (surfaced via `work.nix`'s `visual-studio-code` cask being flagged for zap-removal when deploying the `personal` profile).

## Goals / Non-Goals

**Goals:**
- Move `nixpkgs`, `nix-darwin`, and `home-manager` primary inputs together onto the matched `26.05` stable release trio, replacing today's independently-rolling pins.
- Explicitly verify the homebrew `--force-cleanup` fix is present in the locked `nix-darwin-26.05` revision and that `onActivation.cleanup` behaves correctly against both profiles' real cask sets, closing out the exact failure mode from the prior attempt.
- Leave the secondary `nixpkgs-unstable` overlay input (used for `unstable.*` packages in `nix/darwin/default.nix`) untouched — it is deliberately rolling and orthogonal to this bump.

**Non-Goals:**
- Not re-attempting or expanding the `nix-repo-hygiene` capability's CI/formatter/dedup work — that is already implemented and out of scope here.
- Not changing which packages/casks/settings are deployed beyond what naturally shifts from the nixpkgs version bump itself.
- Not introducing an automated-update/renovate-style mechanism for future release bumps — this is a one-time manual bump; a recurring-bump process is a separate future concern if desired.
- Not pinning to `25.11` — confirmed via `git ls-remote` to already be the prior stable release as of now, so `26.05` is the correct "latest stable" target per the user's actual intent ("aiming to latest stable").

## Decisions

1. **Target release: `26.05` over `25.11`.**
   Decision: use the `26.05` matched trio (`nixpkgs-26.05-darwin`, `nix-darwin-26.05`, `release-26.05`), not `25.11`. Rationale: the user's goal is "latest stable"; `git ls-remote` confirms `26.05` is the current latest release branch set (all three repos have `*-26.05` branches with more recent commits than their `*-25.11` counterparts), and `25.11` is now the previous release. Alternative considered: `25.11` for extra conservatism/field-testing — rejected because it contradicts the stated goal and there's no specific compatibility reason found to prefer it.

2. **Use `nixpkgs-<ver>-darwin` (not `nixos-<ver>`) for the nixpkgs branch.**
   Decision: pin `nixpkgs` to `github:NixOS/nixpkgs/nixpkgs-26.05-darwin`, the Darwin-specific branch, rather than the generic `nixos-26.05` branch. Rationale: this is nix-darwin's own documented/recommended pairing (per its README's stable-pinning example) — the `nixos-<ver>` branch is primarily NixOS/Linux-gated, while `nixpkgs-<ver>-darwin` is the branch nix-darwin's release process actually tracks and tests against.

3. **Bump all three primary inputs atomically in one change, not incrementally.**
   Decision: change `nixpkgs`, `nix-darwin`, and `home-manager` together in a single commit/lock update, rather than repeating the prior attempt's mistake of moving `nix-darwin` alone. Rationale: the prior failure was caused by exactly this kind of partial/independent bump; nix-darwin's own version-matching assertion makes atomic bumping a correctness requirement, not just a style preference.

4. **Leave `nixpkgs-unstable` (secondary input) untouched.**
   Decision: do not touch the `nixpkgs-unstable` input or its `unstable.*` overlay usage in `nix/darwin/default.nix`. Rationale: it's a deliberately independent rolling channel for accessing bleeding-edge packages outside the stable pin; conflating it with this bump would expand scope and risk unrelated to the nix-darwin/nixpkgs version-matching problem being solved here.

5. **Homebrew cleanup verification is a required gating step, not a follow-up.**
   Decision: explicitly verify `--force-cleanup` presence in the locked nix-darwin source and manually validate cleanup behavior against both profiles before this change is considered done — do not defer it the way the prior attempt did (which left it as an open "Follow-up (out of scope)" item that then blocked the actual bump). Rationale: this exact gap is what broke `just deploy` last time; treating it as in-scope verification (not a separate future change) is the direct fix for "let's try now... [not risky]".

6. **home-manager pinned to matching `release-26.05` rather than left on `master`.**
   Decision (per user's explicit choice): pin `home-manager.url` to `github:nix-community/home-manager/release-26.05`. Rationale: keeps all three primary inputs on the same stable train, minimizing module-option drift between home-manager's expectations and the pinned nixpkgs/nix-darwin versions, consistent with the overall goal of matched-version stability.

## Risks / Trade-offs

- **[Risk] `nixpkgs-26.05-darwin` may lack a package version that `devenv`/`zjstatus`/`stylix` (which follow the primary `nixpkgs`) depend on, causing `nix flake check` failures.** → Mitigation: run `nix flake check` immediately after the input bump; since these inputs already follow the primary `nixpkgs` today (established in the prior hygiene change), the actual delta is just a version bump of the same followed input, which is lower risk than introducing a new `follows` relationship — but still explicitly verified before proceeding.
- **[Risk] The `--force-cleanup` homebrew fix might not actually be present at whatever commit the `nix-darwin-26.05` branch HEAD resolves to (e.g. if backported differently or the branch diverged).** → Mitigation: explicitly grep the locked nix-darwin source (`modules/homebrew.nix` or equivalent) for `--force-cleanup` after `nix flake lock`, before running a real `just deploy`.
- **[Risk] Package version changes across an entire stable-release jump (unstable → 26.05, or even 25.11 → 26.05 equivalent) could change enough package behavior/config option names to break `just check` or the actual system build in ways smaller bumps wouldn't.** → Mitigation: run `nix flake check` and `just check` for both `personal` and `work` profiles before any real deploy; treat any build/eval failures as blocking, to be fixed or the bump held, rather than force-deployed.
- **[Trade-off] Atomic three-input bump means a larger single diff/lock update than incremental bumps.** → Accepted: this is exactly what's required to satisfy nix-darwin's version-matching assertion; the alternative (incremental) is the approach that already failed once.

## Migration Plan

1. Update `nix/flake.nix`: `nixpkgs` → `nixpkgs-26.05-darwin`, `nix-darwin` → `nix-darwin-26.05`, `home-manager` → `release-26.05`.
2. Run `nix flake lock` (or `nix flake update`) to regenerate `nix/flake.lock` for the three changed inputs only (other inputs stay pinned unless they fail to resolve against the new `nixpkgs`).
3. Run `nix flake check` from the repo; treat any evaluation failure in `devenv`/`zjstatus`/`stylix`'s `follows`-based resolution as blocking and investigate before proceeding.
4. Run `just check` for both `personal` and `work` profiles; confirm both build/evaluate cleanly.
5. Inspect the locked `nix-darwin` source for the `--force-cleanup` homebrew fix (PR #1789) to confirm it is present.
6. Validate homebrew cleanup behavior against real cask state on both profiles (dry-run or careful real deploy), specifically re-testing the scenario that broke last time (switching profiles with differing casks installed).
7. Only after steps 3–6 pass, perform (or have the user perform) a real `just deploy` for the active profile.
8. Rollback: `git revert` the input/lock changes — no data migrations or irreversible steps are involved; reverting restores the previous working rolling-input state exactly as the prior attempt's revert did.

## Open Questions

- None outstanding — version target (26.05), homebrew verification scope, and home-manager pinning were all explicitly decided with the user before this design was written.
