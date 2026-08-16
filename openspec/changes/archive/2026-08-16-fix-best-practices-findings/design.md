## Context

This change addresses a batch of small, independently-verified hygiene/reproducibility findings
from a best-practices audit (see `BEST_PRACTICES_ANALYSIS_BY_QWEN3.8_OLLAMA_LOCAL-v2-refined.md`
at repo root for full detail on each finding and how it was verified). All findings here were
re-confirmed against the live repo (file reads, `git status`/`git ls-files`, `flake.lock`
inspection) before being included — this is not a blind pass-through of the original LLM audit.

Two related, previously-flagged findings are explicitly **out of scope** for this change and are
not touched by any task below:
- The `builtins.getEnv` username/UID resolution in `nix/darwin/default.nix` — already governed
  by the existing `dynamic-user-detection` spec, which documents it as an intentional,
  abort-on-missing design decision.
- `.DS_Store` tracking and `opencode.nix`/`opencode2.nix` "duplication" — both were confirmed
  false claims during verification (see refined analysis doc), no code changes needed.

## Goals / Non-Goals

**Goals:**
- Remove a stray backup file that is currently staged for commit.
- Restore portability of the one hardcoded personal path in a git-tracked Tuna config source,
  using the file's own existing `<user>` placeholder convention (no new mechanism needed).
- Document every `pkgs.unstable.*` usage inline so future readers understand why the unstable
  channel is required there instead of stable.
- Decide and implement a consistent posture for the `stylix` flake input's pinning (either pin
  it to a specific branch/tag, or explicitly document that it intentionally floats and how
  updates to it should be performed).
- Make `.githooks/pre-commit` either meaningfully enforce the same checks as CI, or be removed
  so it doesn't imply false confidence.
- Correct two stale documentation/comment references (`AGENTS.md`'s `nix/paths/` mention;
  `opencode.nix`'s stale `thinking.md` source path in a comment).

**Non-Goals:**
- Changing the `getEnv`-based username/UID resolution strategy in `nix/darwin/default.nix`.
- Consolidating or removing `opencode.nix`/`opencode2.nix` — both are intentional and serve
  different purposes.
- Adding new tooling infrastructure (e.g. treefmt-nix for shell/TOML) — this was flagged as
  optional/low-severity in the original audit and is deferred to a future change if desired.
- Changing Tuna's shared-base + delta-patch merge mechanism itself — only the one line that
  deviates from its existing `<user>` placeholder convention is touched.
- Adding upstream issue citations to the sketchybar rendering-bug comments in
  `nix/darwin/profiles/defaults.nix` — researched (see Decision 9) and found to have no real
  upstream issue to cite; the existing comments remain as-is.
- Building a CI check or automated nudge for `nixpkgs-unstable` lock staleness — recorded as a
  deferred idea (see Decision 10 and Open Questions) but not implemented here.

## Decisions

### 1. Delete the backup file outright; do not add a `.gitignore` pattern for it
The file `nix/modules/home/tuna/config.toml.backup-20260816-120353-530` is a byproduct of manual
testing, not something the repo's own tooling produces under a tracked name — the actual
runtime backup mechanism (`home.activation.backupLeaderKeyConfig` in
`nix/modules/home/tuna/default.nix`) writes to `~/Library/Application Support/Tuna/
config.toml.backup[.N]`, which is entirely outside the repo tree and thus never a git-tracking
concern. Since this specific timestamped filename pattern is not expected to recur from any
in-repo automation, a bespoke `.gitignore` entry isn't warranted — the fix is simply to remove
the file and leave `.gitignore` unchanged.

**Alternative considered**: adding a `*.backup-*` glob to `.gitignore`. Rejected as unnecessary
defensive tooling for a one-off manual artifact; if this recurs, revisit.

### 2. Fix the Android Studio path using the existing `<user>` placeholder, not a new mechanism
`config.shared.toml` already has a working, general templating mechanism: literal `<user>`
tokens are replaced with `config.home.username` at build time in `default.nix`
(`templatedConfig = builtins.replaceStrings [ "<user>" ] [ config.home.username ] ...`). The
Android Studio binding is the one line that bypasses this by hardcoding `adielhercules`
directly. The fix is a one-line edit: replace the literal username segment with `<user>`,
consistent with every other absolute path in the file.

**Alternative considered**: deriving the path from a Nix option/variable instead of a
text-replace token. Rejected — would require restructuring the delta-patch merge pipeline for
a single line; the existing token convention already solves this exact problem file-wide.

### 3. Document `pkgs.unstable.*` usages with inline comments, not additional pinning automation
Per the refined audit, `flake.lock` already pins `nixpkgs-unstable` to a specific commit, so
today's builds are reproducible. The gap is purely documentation: readers can't tell why each
`pkgs.unstable.*` call exists without git-blame archaeology. Each of the following gets a
one-to-three-line comment stating the reason it's on unstable (e.g. "needs a fix/feature not yet
in 26.05 stable"):
- `nix/modules/home/zellij.nix:74`
- `nix/modules/home/helix.nix:7`
- `nix/modules/home/aerospace/default.nix:32` and `:61`
- `nix/modules/home/sketchybar/default.nix:135`
- `nix/darwin/home.nix:133` (difftastic)

Where the original reason for choosing unstable isn't independently known/discoverable (e.g. via
git log or CHANGELOG), the comment will state the observed practical justification (e.g. "pinned
to unstable because the stable-channel version lacks feature X used by this config") rather than
fabricating a specific upstream issue reference that can't be verified — accuracy over the
appearance of precision, consistent with lessons from the audit's own fabricated-citation
mistake.

**Alternative considered**: a repo-wide CI check that fails if `nixpkgs-unstable`'s lock age
exceeds N days. Deferred as a nice-to-have, tracked as an open question below rather than a
blocking task for this change, since it requires new CI plumbing beyond the scope of a
documentation/hygiene pass.

### 4. Pin `stylix.url` to the 26.05-adjacent branch if one exists; otherwise document the floating-input policy explicitly
This requires a research step during implementation: check whether `nix-community/stylix` has
a release branch/tag aligned with NixOS 26.05 (many nix-community flakes track `nixpkgs-unstable`
release trains rather than NixOS stable numbering). Two possible outcomes, both acceptable:
- **If a compatible branch/tag exists**: pin `stylix.url` to it, matching the posture of
  `nixpkgs`/`home-manager`/`nix-darwin`.
- **If no such branch/tag exists** (stylix only ships a rolling `main`): add an explicit comment
  next to `stylix.url` in `flake.nix` stating that this input intentionally tracks its default
  branch, and that updates to it should be done deliberately via a scoped
  `nix flake lock --update-input stylix` rather than swept up silently by a broad `just up`.

This decision explicitly does not require immediately running `nix flake update` on stylix —
only clarifying the pinning posture and, if pinning, doing so without also picking up unrelated
drift on other inputs.

**Alternative considered**: leave `stylix.url` exactly as-is with no comment. Rejected — the
audit correctly identified this as the one input inconsistent with the repo's otherwise
consistent 26.05-pinning discipline; a bare minimum of an explanatory comment is warranted even
if a real branch pin isn't available.

### 5. Wire `.githooks/pre-commit` to mirror CI, rather than removing it
Removing the hook is the "honest but does nothing" option; wiring it up delivers the actual
value a pre-commit hook is meant to provide (fast local feedback before CI). Since CI already
runs `nix fmt --check`-equivalent (`nixfmt-tree --ci`) and `statix check .`, the hook will run
the same two fast, local checks:
```bash
#!/bin/bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)/nix"
nix run nixpkgs#nixfmt-tree -- --ci
nix run nixpkgs#statix -- check .
```
`deadnix --fail .` is intentionally left out of the local hook (kept CI-only) since it can be
slower and less critical for a pre-commit-speed check; this can be revisited later if desired.

**Alternative considered**: removing the hook entirely. Rejected in favor of making it useful,
since the repo already has a `.githooks` directory wired up (implying hooks were intended to be
used) and the marginal cost of wiring 2 fast checks is low.

### 6. Fix stale comments/docs as straightforward text edits
- `AGENTS.md`: remove/replace the `nix/paths/` bullet in the "File Locations & Organization"
  section with the current reality (`rootPath` is defined inline in `nix/flake.nix`).
- `nix/modules/home/opencode/default.nix` (~line 130, since commit `9b7b910` renamed
  `opencode.nix` into this directory): correct the comment's referenced path from
  `nix/modules/home/opencode/agents/thinking.md` to the actual source path used by
  `xdg.configFile` (`config/opencode/agents/thinking.md`, resolved via the file's own
  `opencodeSource = "${files}/opencode";` definition — confirm exact path before editing).
- `nix/modules/home/opencode2.nix` (~line 7): correct the stale `(see opencode.nix)` reference,
  which no longer resolves to a real file since the same rename — point it at
  `opencode/default.nix` instead.
- `nix/modules/home/sketchybar/plugins/battery.sh` (~line 7): correct the stale reference to
  `openspec/changes/add-yabai-sketchybar/tasks.md`, which has since been archived to
  `openspec/changes/archive/2026-07-30-add-yabai-sketchybar/tasks.md`. Found via a repo-wide
  scan (task 8) for other in-repo path references that may have gone stale, prompted by
  discovering the two `opencode` module references above were not the only ones of this kind.

### 7. Broaden the "documentation reflects current structure" requirement to cover in-code comments, and add a dedicated Tuna-portability capability
Two follow-up gaps were identified after the initial pass: (a) the `nix-repo-hygiene` spec's
documentation-accuracy requirement was scoped only to `AGENTS.md`'s prose, not to in-code
comments generally — even though this same change fixes two stale in-code path references
(`opencode/default.nix:130`, `opencode2.nix:7`) and, per the repo-wide scan in task 8, a third
(`battery.sh:7`); and (b) the Tuna hardcoded-path fix (Decision 2) had an implemented task but
no corresponding spec requirement, meaning it wasn't enforced or discoverable as a documented
expectation once this change's context (the analysis doc) is deleted.

Both are resolved by: broadening the existing `nix-repo-hygiene` requirement's title and
scenarios to explicitly cover "in-repo path references" generally (prose and code comments
alike), rather than narrowly to `AGENTS.md`; and adding a new capability,
`tuna-config-portability`, with a requirement stating that `config.shared.toml` (and per-profile
delta files) must use the `<user>` placeholder convention rather than hardcoded usernames in
absolute paths.

**Alternative considered**: leaving the Tuna path fix as an implemented-but-unspecified task.
Rejected — without a spec requirement, there's no durable record of *why* this convention
matters or a scenario that would catch a regression (e.g. a future edit re-introducing a
hardcoded path).

### 8. Repo-wide scan for other stale in-repo path references in comments
Since two stale path references were found in the `opencode` module purely as a side effect of
investigating one specific finding, a broader repo-wide scan was performed (via a dedicated
explore pass over all `.nix` files and non-`.nix` files such as shell scripts and top-level docs)
to check for other comments referencing in-repo paths that may have gone stale from unrelated
renames/archives. This found exactly one more: `battery.sh:7`'s reference to a now-archived
openspec change path (see Decision 6). No other stale references were found; all other in-repo
path references checked (aerospace, sketchybar, yabai, tuna, and cross-references between
`opencode2.nix` and `opencode/default.nix` post-fix) resolve to files that currently exist.

### 9. Sketchybar workaround comment "polish" (original finding #9): reviewed, no fix needed
The original audit suggested optionally adding upstream issue links/dates to the sketchybar
rendering-bug comments in `nix/darwin/profiles/defaults.nix`. A web search was performed for an
existing upstream `FelixKratz/SketchyBar` issue matching the specific diagnosis documented in
those comments (nixpkgs' ad-hoc/linker-signed build causing blank icon glyphs, traced to
pre-v2.24.0 behavior). **No matching upstream issue exists** — this diagnosis appears to be
original local investigation, not a publicly filed/tracked bug; the closest upstream threads
found cover unrelated root causes (font patching, nerd-fonts v3 breaking changes). Since there is
no real citation to add, and the existing comments are already thorough and self-documenting
(font/cmap verification, cache dedup, logout, `--load-font`, font swap, and version tracing are
all spelled out inline), **no change is made here**. This closes out finding #9 as reviewed with
no action needed, rather than leaving it as an open/dangling suggestion.

### 10. Unstable-lock-age CI nudge (original finding #2's optional idea): recorded as deferred, not implemented
The original audit's optional suggestion — a CI check (or documented manual habit) that flags
when the `nixpkgs-unstable` lock entry's age exceeds some threshold, nudging a deliberate
`just up-unstable-to <hash>` re-pin rather than passive drift on every `just up`/`nix flake
update` — is **not implemented** in this change (see Non-Goals and Open Questions). It's
recorded here so the idea isn't silently lost once the source analysis markdown files are
deleted.

## Risks / Trade-offs

- **[Risk]** Pinning `stylix.url` to a new branch/tag could change the resolved stylix revision
  materially (new features, breaking changes, theming differences) on the next `nix flake
  update --update-input stylix`. → **Mitigation**: this change only updates the *input
  reference* posture (adds a branch/tag or a documentation comment); it does not itself run
  `nix flake lock --update-input stylix` unless the research step confirms it's safe and
  desired. If a lock update is performed as part of this change, `just check` (dry-run) MUST be
  run afterward before considering the task done, and results shown to the user before deploy.
  → **Realized**: this risk materialized, in two stages. First, after pinning to
  `release-26.05` and updating the lock, `nix flake check --no-build` passed, but `just check`
  (actual `darwin-rebuild check`) failed with `The option 'home-manager.users.<user>.
  gtk.gtk4.theme' is defined both null and not null`. Root cause: stylix's `release-26.05` GTK
  home-manager target now unconditionally sets `gtk.gtk4.theme`, conflicting with a
  pre-existing workaround (`gtk.gtk4.theme = null;` in `nix/darwin/home.nix`, originally added
  to suppress a GTK4 theme migration warning). An initial fix attempt set
  `stylix.targets.gtk.enable = false;` in the **darwin-level** `stylix` block
  (`nix/darwin/default.nix`), which passed `nix flake check --no-build` but then failed
  `just check` again with a *different* error: `The option 'stylix.targets.gtk' does not
  exist` — because the GTK stylix target is a home-manager-only module with no nix-darwin
  equivalent, so it isn't a valid option at that level. The corrected fix sets
  `stylix.targets.gtk.enable = false;` in `nix/darwin/home.nix` (the home-manager module)
  instead, alongside removing the now-unnecessary `gtk.gtk4.theme = null;` workaround. Verified
  by directly evaluating `config.system.build.toplevel.drvPath` for both the `personal` and
  `work` `darwinConfigurations` outputs (the same attribute `darwin-rebuild check` evaluates),
  which succeeded for both after the corrected fix. This is a good concrete illustration of two
  things: (1) `nix flake check --no-build` alone is insufficient to validate a flake-input
  version bump — it did not catch either error, since it doesn't fully evaluate
  `system.build.toplevel`; and (2) stylix's target options are not uniformly available across
  the nix-darwin and home-manager module surfaces, so target-disabling fixes need to be applied
  at the same module level where the conflicting option lives.
- **[Risk]** Wiring `.githooks/pre-commit` to run real checks could slow down every local commit
  and surprise contributors who weren't expecting it to do anything. → **Mitigation**: keep the
  hook to the two fastest checks (`nixfmt-tree --ci`, `statix check .`); both are already
  fast in CI and operate on a Nix-only file set of modest size in this repo.
- **[Risk]** The `pkgs.unstable.*` comments could state an inaccurate reason if the true original
  motivation for pinning to unstable isn't recoverable. → **Mitigation**: word comments
  conservatively ("appears to require a feature/fix not yet in 26.05 stable" rather than a false
  specific claim), and verify by testing whether swapping to `pkgs.<same>` (stable) still
  evaluates/builds where feasible, to at least confirm current necessity even if the original
  historical reason is lost.
- **[Trade-off]** This change intentionally leaves the `getEnv` impurity, the optional
  treefmt-nix/shellcheck coverage, and CI-based unstable-lock-age checks out of scope, to keep
  this change small and low-risk. These remain valid candidates for future, separate changes.

## Migration Plan

1. Delete the staged backup file; verify `git status --porcelain` no longer shows it.
2. Edit `config.shared.toml`'s Android Studio line; verify by rebuilding the Tuna config output
   locally (or via `just check`) that the deployed `config.toml` correctly renders the current
   user's home path.
3. Add unstable-usage comments; no functional change, verify `nix flake check --no-build` still
   passes.
4. Research and apply the stylix input decision; if a lock update is performed, run
   `nix flake check --no-build ./nix` and `just check` before considering complete.
5. Rewrite `.githooks/pre-commit`; verify it runs successfully via `bash .githooks/pre-commit`
   (or by staging a trivial change and invoking `git commit` to confirm the hook fires, if hooks
   are configured via `core.hooksPath`).
6. Apply the two documentation/comment text fixes.
7. Run the full mandatory post-apply validation sequence from `AGENTS.md` (stage `nix/`,
   `nix flake check --no-build ./nix`, `nix fmt`, `deadnix --fail .`, `statix check .`) before
   marking the change complete.

Rollback is trivial for every task here — each is a small, independent, easily-revertible file
edit or deletion; no data migrations or irreversible state changes are involved.

## Open Questions

- Does `nix-community/stylix` currently offer a release branch/tag aligned with NixOS 26.05, or
  only a rolling default branch? This must be resolved during implementation (task 4) before
  deciding between "pin" vs. "document as floating." **Resolved**: yes, `release-26.05` exists
  and is upstream's officially recommended branch; pinned to it (see Decision 4, and the
  realized-risk note under Risks / Trade-offs).
- Should `deadnix --fail .` be added to the local pre-commit hook as well, for full CI parity,
  or intentionally left CI-only for speed? Currently decided as CI-only (see Decision 5); revisit
  if contributors want stricter local enforcement.
- **Deferred**: should a CI check (or documented manual habit) be added that flags when the
  `nixpkgs-unstable` lock entry's age exceeds some threshold, nudging a deliberate
  `just up-unstable-to <hash>` re-pin rather than passive drift on every `just up`/`nix flake
  update`? Not implemented in this change (see Decision 10) — would require new CI plumbing
  beyond the scope of a documentation/hygiene pass. Revisit as a future, separate change if
  unstable-package drift becomes a recurring problem.
