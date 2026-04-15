## Context

Repo has three shell scripts with overlapping responsibilities: `initialize_paths.sh` writes `rootPath` into a sub-flake (now defunct since Lix compatibility fix removed that input), `initial-deploy.sh` bootstraps nix-darwin on a fresh machine, and `deploy.sh` runs a standard rebuild. All three must be run in sequence on a new machine but there is no single entry point. Additionally, `rootPath` is hardcoded in `nix/flake.nix` — a real machine path that would leak into git history if accidentally committed after a fresh clone.

## Goals / Non-Goals

**Goals:**
- Single `init.sh` entry point: path init → bootstrap deploy → standard deploy
- `rootPath` in `nix/flake.nix` replaced with `<init-required>` placeholder; `init.sh` substitutes real path via `sed`
- Committed `.githooks/pre-commit` that blocks any staged `nix/flake.nix` missing the `<init-required>` placeholder
- `init.sh` activates hook by setting `core.hooksPath = .githooks`
- Remove all dead/redundant scripts and the defunct `nix/paths/` sub-flake

**Non-Goals:**
- Idempotency guards (running `init.sh` twice is user's responsibility)
- Cross-platform support (macOS/BSD `sed -i ''` only)
- Automated testing of the hook or init script

## Decisions

**1. `sed -i ''` over `awk` or Nix for rootPath substitution**
BSD `sed` (macOS) requires empty string argument to `-i`. Simple, no dependencies beyond what ships with macOS. Nix-based substitution would require nix to already be available — chicken-and-egg on a fresh machine.

**2. `.githooks/` dir over `.git/hooks/`**
`.git/hooks/` is not tracked by git — hooks vanish on clone. `.githooks/` is committed, so hook travels with repo. Requires `core.hooksPath` set locally; `init.sh` does this automatically.

**3. `git show :nix/flake.nix` over `git diff --cached` grep**
Reads the staged blob directly. More reliable than grepping a diff which could match context lines or have format artifacts.

**4. Hardcoded `mymbp` hostname**
`deploy.sh` hardcoded `mymbp`. Keeping it hardcoded for now — single known machine, no need for dynamic detection.

**5. `SCRIPT_DIR` for all paths**
Script computes its own absolute path so it works regardless of CWD when invoked.

## Risks / Trade-offs

- **`sed` replaces all occurrences** → only one `<init-required>` exists in `nix/flake.nix` so no risk of over-replacement. If future edits add a second, init would replace both — acceptable.
- **Parts 2 and 3 run sequentially on first run** → two full darwin-rebuild evaluations on bootstrap. Unavoidable: Part 2 installs darwin-rebuild, Part 3 uses it.
- **`core.hooksPath` is local git config** → not committed. Anyone cloning without running `init.sh` won't have hook active. Acceptable — they also won't have `rootPath` set, so there's nothing dangerous to commit yet.
- **Hook checks staged file, not working tree** → if user stages `nix/flake.nix` with real path, hook fires. If they never stage it, hook is silent. Correct behaviour.

## Migration Plan

1. Replace `rootPath` literal in `nix/flake.nix` with `<init-required>`
2. Create `init.sh` and `.githooks/pre-commit`
3. Delete `initialize_paths.sh`, `initial-deploy.sh`, `deploy.sh`, `nix/paths/flake.nix`, `paths/flake.nix`
4. On current machine: run `git config core.hooksPath .githooks` manually (or re-run `init.sh` after hook path set — but Part 1 would re-sed an already-initialised `nix/flake.nix`, replacing the real path with placeholder again — **run `git config` manually on existing machine**)
5. Commit and push
