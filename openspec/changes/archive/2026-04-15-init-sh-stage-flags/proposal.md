## Why

`init.sh` currently runs all stages (path initialisation, git hook activation, bootstrap deploy, and standard deploy) sequentially with no way to skip or isolate individual ones. This makes it tedious to re-run a single stage after initial setup — for example, re-activating git hooks or re-running path substitution without triggering a full `darwin-rebuild`.

## What Changes

- `init.sh` gains CLI flag support: `--paths`, `--git`, `--bootstrap`, `--deploy`, and `--all`
- `--paths` runs sed substitution AND git hook activation together (current bundled behaviour)
- `--git` runs git hook activation only
- `--bootstrap` runs the `nix run` bootstrap deploy only
- `--deploy` runs `darwin-rebuild switch` only
- `--all` runs all stages in order: paths → bootstrap → deploy (this is also the default when no flags are passed)
- Each stage is extracted into a clearly named shell function

## Capabilities

### New Capabilities
- `init-script-flags`: CLI flag support for `init.sh` allowing individual stages to be run in isolation via `--paths`, `--git`, `--bootstrap`, `--deploy`, and `--all`

### Modified Capabilities
- `init-script`: The invocation contract changes — `init.sh` must now accept optional flags and run selectively rather than always executing all stages sequentially

## Impact

- `init.sh` — primary file being modified
- No changes to `nix/flake.nix`, `.githooks/`, or any Nix modules
- No breaking change to the default no-flag invocation (`./init.sh` still runs everything)
