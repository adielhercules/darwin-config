## Context

The darwin-config repository is a Nix-Darwin macOS system configuration flake with two deployment profiles (personal/work). A comprehensive audit against nix.dev best practices, the NixOS Wiki, and Determinate Systems guidelines identified 14 issues across high/medium/low priority. The codebase is well-structured overall — it already follows many best practices (no `rec {}`, no `<...>` lookup paths, scoped `with`, `follows` on most inputs, `useGlobalPkgs`). The issues found are incremental improvements rather than architectural problems.

The audit was performed in a previous session and all 14 findings were verified as still valid against the current codebase. This change addresses all of them in a single cohesive pass.

## Goals / Non-Goals

**Goals:**
- Eliminate all hardcoded paths that break portability (rootPath, uid)
- Remove duplicate packages and dead code
- Improve module composability (remove blanket mkForce)
- Extract large inline config blocks for maintainability
- Standardize naming conventions
- Add post-apply validation guardrails to prevent regression
- Ensure all changes pass `nix flake check`, `nix fmt`, `deadnix`, and `statix`

**Non-Goals:**
- Restructuring the overall module architecture
- Adding new features or packages
- Changing the profile selection mechanism (already hostname-based)
- Migrating to a different secrets management tool (agenix/sops-nix)
- Changing the CI workflow (already has deadnix/statix)

## Decisions

### 1. rootPath = self, git email managed imperatively

**Decision**: Change `rootPath` to `self` (the flake source). Git email is no longer read by Nix at all — `init.sh --email` writes a standard git config snippet to `~/.config/git/config.local`, and home-manager includes it via `programs.git.includes`.

**Rationale**: `self` is the standard flake mechanism for referencing the flake's own source tree. It makes the config portable — no hardcoded user path. For git email, the previous approach (`builtins.getEnv "HOME"` reading `~/.local/git-email`) worked but added complexity (a dedicated Nix library function, abort-on-missing logic). The new approach is simpler: git already supports `include.path` for machine-specific overrides, and `init.sh` already runs before any deploy. No Nix code needs to read the email file.

**Alternatives considered**:
- *Keep rootPath as string with a comment*: Rejected — doesn't fix the portability issue.
- *Use `builtins.getFlake "."`*: Rejected — same git-tracking limitation as `self`, and adds complexity.
- *Keep reading email via `builtins.getEnv "HOME"`*: Worked but added a Nix library function and eval-time file reads. The `include.path` approach is simpler and more idiomatic for git.

### 2. Dynamic UID via SUDO_UID environment variable

**Decision**: Replace `uid = 501` with `builtins.getEnv "SUDO_UID"`, converting via `builtins.fromJSON`. Abort with a clear message if `SUDO_UID` is not set (i.e., not running via sudo).

**Rationale**: `builtins.exec` is unavailable in Lix. `SUDO_UID` is set by macOS when running via `sudo`, which is the only way `darwin-rebuild` runs (the Justfile uses `sudo`). This gives us the real user's UID without needing to execute shell commands at eval time.

**Alternatives considered**:
- *`builtins.exec ["id" "-u" username]*: Rejected — `builtins.exec` doesn't exist in Lix.
- *`builtins.lines` + `builtins.exec`*: Rejected — `builtins.lines` also doesn't exist in Lix.
- *Remove uid entirely*: Rejected — nix-darwin may assign a different default, potentially breaking existing user accounts.
- *Keep uid = 501 with a comment*: Rejected — still breaks on machines with different UIDs.

### 3. Remove mkForce from helix settings

**Decision**: Remove `lib.mkForce` from `settings = lib.mkForce { ... }`, leaving just `settings = { ... }`.

**Rationale**: home-manager's helix module merges settings by default. `mkForce` overrides ALL other module contributions. Currently no other module contributes helix settings, so the output is identical. Removing mkForce allows future modules (e.g., stylix helix integration) to contribute settings without being silently overridden.

**Alternatives considered**: None — this is a straightforward improvement with no downside.

### 4. Extract zellij plugin block to separate .nix file

**Decision**: Extract the ~110-line plugin/zjstatus configuration block from `zellij.nix` into `nix/modules/home/zellij/zjstatus.nix` that returns the interpolated string.

**Rationale**: The plugin block uses Nix string interpolation for Stylix colors (`${colors.base03}`, etc.), so it CANNOT be a plain `.kdl` file. A separate `.nix` file that returns the string is the correct approach. This keeps `zellij.nix` focused on the Zellij module configuration while isolating the zjstatus-specific logic.

**Alternatives considered**:
- *Keep inline but add section comments*: Rejected — doesn't improve maintainability.
- *Use a .kdl template with mustache placeholders*: Rejected — adds unnecessary complexity when Nix string interpolation already works.

### 5. Git user.name: keep literal, document rationale

**Decision**: Keep `"Adiel Hercules"` as a literal string in both git modules. The `git-email-config` spec currently requires this as a hard requirement.

**Rationale**: The name is the same across profiles (personal and work). While it could be parameterized via `specialArgs`, the benefit is marginal — the name is unlikely to change, and parameterizing it adds indirection without clarity. The current approach (email externalized, name inline) is a reasonable split. The spec will be updated to document this as an intentional choice rather than an oversight.

**Alternatives considered**:
- *Add a `gitUserName` specialArg*: Over-engineered for a constant value.
- *Read from a file like git-email.nix*: Adds complexity for no benefit.

### 6. fish-colored-man: keep fetchFromGitHub, add comment

**Decision**: Keep the `fetchFromGitHub` approach for `fish-colored-man` but add a comment explaining why.

**Rationale**: `fish-colored-man` may not be available as `fishPlugins.colored-man-pages` in nixpkgs 26.05-darwin. Rather than guessing at the package name and risking a build failure, keeping the working fetchFromGitHub with a pinned hash is safer. The comment documents the intent.

**Alternatives considered**:
- *Use `fishPlugins.colored-man-pages`*: Would need to verify availability first. Can be done in a follow-up if the package exists.

### 7. Post-apply validation: 5-step mandatory sequence

**Decision**: Add a mandatory validation sequence to AGENTS.md and openspec/config.yaml: `git add nix/` → `nix flake check --no-build ./nix` → `nix fmt` → `deadnix --fail .` → `statix check .`.

**Rationale**: This mirrors the CI workflow (`.github/workflows/nix-check.yml`) but adapted for local use (nix fmt instead of treefmt, no `--ci` flag). Making it mandatory for openspec changes ensures every change is validated before merge.

**Alternatives considered**:
- *Add a Justfile recipe*: Possible but not necessary — the steps are simple enough to run individually.
- *Add to pre-commit hook*: Overkill — pre-commit should be fast, and these checks can be slow.

## Risks / Trade-offs

- **[Risk]** Changing rootPath to self may break files that reference rootPath expecting a filesystem path. `self` is a Nix store path (e.g., `/nix/store/abc...-source`), which works for `builtins.readFile`/`builtins.pathExists` but may behave differently for some operations.
  → **Mitigation**: Audit all `rootPath` references before committing. Use `rg rootPath nix/` to find every usage. The main consumers (files, nixPath, libFiles) are all used in string interpolation or as paths, which auto-coerce correctly.

- **[Risk]** Removing `git-email.nix` and `user.email` from git modules is a breaking change for existing setups. Users who have already run `init.sh --email` will have the file at `~/.local/git-email` (old location), not `~/.config/git/config.local`.
  → **Mitigation**: Document the migration in the commit message. Users need to re-run `init.sh --email <address>` after applying this change. The old `~/.local/git-email` file can be cleaned up manually.

- **[Risk]** `builtins.getEnv "SUDO_UID"` for dynamic UID requires running via sudo. Running `darwin-rebuild` without sudo will abort.
  → **Mitigation**: This is already the case — the Justfile always uses `sudo`. The error message is clear: "Run via sudo (e.g. `just deploy`)."

- **[Risk]** nix-homebrew `follows` may break if it requires a different nixpkgs version.
  → **Mitigation**: Test with `nix flake check`. If it fails, document why and omit the follows for this input only.

- **[Trade-off]** The zellij extraction creates a new file but the inline string is still a Nix expression (not pure KDL). This is unavoidable due to Stylix color interpolation.

## Migration Plan

1. Apply all changes in task groups (flake → identity → modules → cleanup → guardrails)
2. Stage all changes: `git add nix/ init.sh AGENTS.md openspec/`
3. Run validation: `nix flake check` → `nix fmt` → `deadnix` → `statix`
4. Re-run `init.sh --email <address>` to write email to the new `~/.config/git/config.local` location
5. Run `just check` to verify darwin-rebuild evaluation passes
6. Deploy with `just deploy`

**Rollback**: All changes are pure refactors. Revert with `git revert` if any issue arises. The email location change requires re-running `init.sh --email` on rollback.

## Open Questions

- None outstanding — all key decisions were confirmed with the user during planning (rootPath → self: yes; dynamic UID via id -p: yes; all 14 items in one change: yes).
