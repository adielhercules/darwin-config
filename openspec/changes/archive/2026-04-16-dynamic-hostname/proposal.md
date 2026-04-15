## Why

The nix-darwin configuration hardcodes `"mymbp"` as the hostname key in `nix/darwin/default.nix` and `nix/flake.nix`. This couples the repo to a single machine name and breaks on any machine with a different hostname. Since nix-darwin resolves flake targets by hostname, using the actual macOS hostname (via `scutil --get LocalHostName`) removes this coupling — consistent with the existing `rootPath` placeholder pattern already handled by `init.sh`.

## What Changes

- Replace every `"mymbp"` occurrence in `nix/darwin/default.nix` and `nix/flake.nix` with the placeholder `<hostname>`.
- Extend `init.sh`'s paths stage to detect the machine's macOS hostname and `sed`-substitute `<hostname>` across both files (parallel to rootPath substitution).
- Update `init.sh`'s deploy stage to use the dynamically resolved hostname rather than the hardcoded string.
- Extend `.githooks/pre-commit` to block commits staging `nix/darwin/default.nix` or `nix/flake.nix` that contain a resolved hostname instead of the `<hostname>` placeholder.

## Capabilities

### New Capabilities

- `dynamic-hostname`: Runtime hostname substitution — `init.sh` replaces `<hostname>` placeholders in nix config files with the machine's actual macOS hostname at setup time, and the pre-commit hook prevents the resolved value from being committed.

### Modified Capabilities

- `init-script`: Deploy stage now targets `.#<resolved-hostname>` instead of `.#mymbp`; paths stage gains hostname substitution alongside rootPath substitution.
- `init-script-flags`: The `--deploy` flag scenario changes: it deploys to the dynamically resolved hostname, not the hardcoded `mymbp`.

## Impact

- `nix/darwin/default.nix` — hostname key `"mymbp"` replaced with `"<hostname>"` placeholder
- `nix/flake.nix` — `"mymbp"` reference in `darwinPackages` replaced with `"<hostname>"` placeholder
- `init.sh` — paths stage gains hostname sed substitution; deploy stage reads hostname dynamically
- `.githooks/pre-commit` — gains placeholder guard for both nix files
