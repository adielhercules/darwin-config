## Context

`init.sh` is a one-shot setup script with three hardcoded sequential stages:
1. Set `rootPath` in `nix/flake.nix` via `sed` and activate git hooks
2. Bootstrap nix-darwin via `nix run`
3. Deploy via `darwin-rebuild switch`

There is no mechanism to run a single stage. Users must comment out stages manually or re-run the whole script, risking re-triggering a full `darwin-rebuild` unintentionally.

## Goals / Non-Goals

**Goals:**
- Add `--paths`, `--git`, `--bootstrap`, `--deploy`, and `--all` flags to `init.sh`
- Default (no flags) runs `--all` — existing behaviour is fully preserved
- Each stage becomes a named shell function for clarity and reuse
- `--paths` retains current bundled behaviour (sed + git hooks)
- `--git` provides a standalone way to re-activate hooks only

**Non-Goals:**
- No changes to what each stage does internally — pure refactor + flag routing
- No new stages or build targets beyond the five flags
- No changes to `.githooks/`, `nix/flake.nix`, or any Nix modules

## Decisions

### Arg parsing: `case` statement over `getopts`

`getopts` only supports single-character flags (`-p`, `-g`) and is awkward with long flags like `--paths`. A simple `case "$1"` over `$@` is sufficient for this single-flag-at-a-time design, more readable, and matches the long-flag style the user expects.

**Alternative considered**: `getopt` (GNU) supports long options but is non-portable across macOS BSD vs Linux. `case` has no such issue.

### One flag at a time, no combining

The script accepts exactly one flag. Combining flags (e.g., `--paths --bootstrap`) is not supported in this change. This keeps arg parsing trivial and matches the stated use cases.

**Alternative considered**: Support multiple flags via loop — deferred; adds complexity for minimal gain now.

### Stage functions: `run_paths`, `run_git`, `run_bootstrap`, `run_deploy`

Each stage is extracted to a named function. `run_paths` calls both `run_paths_sed` (inline logic) and `run_git`. `--all` calls `run_paths`, `run_bootstrap`, `run_deploy` in order.

## Risks / Trade-offs

- [Risk] User passes an unknown flag → Script exits with usage message. Safe.
- [Risk] `--bootstrap` run on a machine where nix-darwin is already installed → Harmless; `nix run` will rebuild idempotently.
- [Risk] `--deploy` run before `--paths` on a fresh clone → `darwin-rebuild` fails because `rootPath` is still `<init-required>`. Mitigation: documented — `--paths` must be run first on a fresh clone.
