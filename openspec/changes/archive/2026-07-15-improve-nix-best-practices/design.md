## Context

The Nix flake (`nix/`) is a single-user, two-profile (`personal`/`work`) nix-darwin + home-manager setup. A best-practices review found it largely idiomatic (pure flake-only, no `with lib;`, correct `stateVersion`/`hostPlatform`, home-manager wired as a nix-darwin module) but missing automated enforcement (no `formatter` output, no CI) and carrying some accumulated drift: two flake inputs with unfollowed `nixpkgs`, an orphaned module file, a broken `just` recipe, stale commented-out code, and a hand-rolled boolean option where `lib.mkEnableOption` would do. This is a solo-maintainer repo with no existing CI infrastructure (`.github/` currently only holds AI-agent tooling config, no `workflows/`).

## Goals / Non-Goals

**Goals:**
- Make `nix fmt` work and enforce it (plus `deadnix`/`statix`) in CI so formatting/lint regressions are caught automatically going forward.
- Reduce avoidable duplicate `nixpkgs` evaluation by following the primary `nixpkgs` from `devenv` and `zjstatus` where version-compatible.
- Remove dead code and one broken command so the repo reflects only what's actually in use.
- Replace the hand-rolled `lcars.shell.fish.enable` boolean option with `lib.mkEnableOption`, and add a clear-error guard for unknown profile names — small idiomatic-Nix polish items, low risk.

**Non-Goals:**
- Not changing the actual deployed system behavior (packages, settings, dotfiles) — this is a hygiene/tooling change only.
- Not introducing a secrets-management overhaul (agenix/sops-nix) — that was already deliberately rejected in an earlier design (`openspec/changes/archive/2026-07-12-split-profiles/design.md`) and stays out of scope here.
- Not restructuring the profile/module architecture beyond the one small assertion guard.
- Not guaranteeing `devenv`/`zjstatus` `follows` will land — each is attempted independently and reverted if it breaks evaluation.

## Decisions

1. **Formatter choice: `nixfmt-rfc-style` via `treefmt-nix` vs. bare `formatter` output.**
   Decision: use a plain `formatter.<system> = pkgs.nixfmt-rfc-style;` output in `flake.nix` rather than pulling in `treefmt-nix` as a new top-level input. Rationale: `treefmt-nix` is already present transitively (via `devenv`'s input graph) but not exposed for direct use, and adding it as a first-class input just for one formatter is unnecessary weight for a single-language (Nix-only) repo. A bare `formatter` output satisfies `nix fmt` and is the minimal idiomatic solution recommended by the Nix flake schema itself.

2. **CI runner and Nix installation: `cachix/install-nix-action` on `ubuntu-latest` vs. requiring a macOS runner.**
   Decision: run CI on Linux (`ubuntu-latest`) using `cachix/install-nix-action` with flakes enabled, and use `nix flake check --no-build` / eval-only checks plus `deadnix`/`statix` (both cross-platform, no Darwin-only evaluation needed). Full `darwin-rebuild check` requires an actual macOS host and Darwin-specific store paths that GitHub's hosted Linux runners can't build; that step is explicitly out of scope for CI and remains a local-only check (`just check`). Rationale: avoids the cost/complexity of macOS runners for what is fundamentally a flake-eval/lint check, while still catching syntax errors, dead code, and format drift automatically.

3. **`devenv`/`zjstatus` `nixpkgs.follows`: attempt independently, revert per-input on failure.**
   Decision: add `follows` to both inputs in the same commit, run `nix flake check` (and a `just check` if available in review), and if one input's `follows` causes an evaluation/build failure, revert only that input's `follows` line and leave a code comment explaining why, keeping the other input's fix. Rationale (per user decision during proposal): partial hygiene improvement is better than an all-or-nothing approach; documenting the revert prevents future contributors from re-attempting the same known-broken change without context.

4. **`leader_key` module: re-enable vs. delete.**
   Decision: during implementation, check whether `nix/modules/home/leader_key.nix` is still desired (e.g., check its content/purpose and ask the user if ambiguous). Default action if no clear signal it's wanted: delete the module file, its `config.json` asset, and the stale commented-out import together, rather than leaving an unused module with a dangling disabled import. Rationale: an unimported, unreferenced module with commented-out wiring is pure dead weight; if it turns out to be wanted, re-enabling the import is the trivial alternative.

5. **`mkEnableOption` refactor scope: minimal, behavior-preserving.**
   Decision: refactor only the `enable`-shaped part of `nix/options/shell.nix`'s `lcars.shell.fish` submodule to use `lib.mkEnableOption "Fish shell configuration"`, keeping any other sub-options (e.g., package selection) as explicit `lib.mkOption` calls. Rationale: `mkEnableOption` is specifically the idiomatic helper for boolean enable/disable toggles; it should not be force-fit onto non-boolean options.

6. **Profile-name guard: `assert` vs. `lib.types.enum`.**
   Decision: add an `assert builtins.elem profile [ "personal" "work" ]` (or equivalent `lib.assertMsg`) at the point `mkDarwinConfig`/profile-path construction happens in `nix/darwin/default.nix`, producing a clear custom error message. Rationale: this is a simple, localized fix; introducing a full `lib.types.enum`-typed option would require restructuring how `mkDarwinConfig` receives `profile` (currently a plain function argument, not a module option) — disproportionate for the actual risk (only two call sites, both under direct maintainer control in `flake.nix`... actually within `darwin/default.nix` itself).

## Risks / Trade-offs

- **[Risk] CI adds friction/maintenance overhead for a solo personal repo.** → Mitigation: keep the workflow minimal (flake check + format + deadnix + statix only, no build/deploy steps), and it runs only on push/PR, not blocking local work.
- **[Risk] Adding `nixpkgs.follows` to `devenv`/`zjstatus` could break their pinned functionality if the primary `nixpkgs` lacks a package/version they depend on.** → Mitigation: verify with `nix flake check` (and manually invoking the `unstable.devenv` package / zjstatus build) before committing; revert per-input as decided above.
- **[Risk] Deleting `leader_key` module/assets could remove functionality still wanted by the maintainer but merely paused.** → Mitigation: inspect content and confirm with the user before deleting if there's any ambiguity about intent; git history preserves it regardless.
- **[Risk] Removing `up-secrets` Justfile recipe could surprise a future contributor expecting a `secrets` input to exist.** → Mitigation: proposal/tasks explicitly document that no `secrets` input exists or is planned; removal is the correct fix given the actual (non-flake) secrets mechanism.
- **[Trade-off] Choosing eval-only/Linux CI over full Darwin build verification** means CI won't catch macOS-specific build failures. → Accepted trade-off; `just check`/`just deploy` locally remain the authoritative Darwin build gate, as they are today (no regression from current state, since no CI exists at all currently).

## Migration Plan

1. Add `formatter` output; run `nix fmt` once locally to normalize existing formatting (separate, clearly-labeled commit if it touches many files).
2. Add `.github/workflows/nix-check.yml`; verify it passes on the current `main`/working branch before merging further changes.
3. Attempt `devenv`/`zjstatus` `follows` additions; run `nix flake check`; revert per-input on failure; regenerate `flake.lock`.
4. Remove orphaned `nix/home/fish.nix`.
5. Remove/fix `up-secrets` Justfile recipe.
6. Clean up dead code in `darwin/home.nix` and `modules/home/fish.nix` (confirming `leader_key` intent first).
7. Refactor `options/shell.nix` to use `mkEnableOption`; verify `darwin-rebuild check` still passes (local, Darwin-only step, run by maintainer).
8. Add profile-name assertion guard in `darwin/default.nix`; verify both `personal` and `work` profiles still build via `just check`.

No rollback complexity beyond standard `git revert` — no data migrations, no irreversible deploys involved. Each step above is independently revertible.

## Open Questions

- Is `nix/modules/home/leader_key.nix` still wanted (paused-but-planned) or safe to delete outright? — to be confirmed with the user during implementation if not obvious from context.
- Should the CI workflow also run on a schedule (e.g., weekly) to catch drift from upstream `nixpkgs` advisories, or push/PR-only is sufficient? — defaulting to push/PR-only unless the user requests otherwise.
