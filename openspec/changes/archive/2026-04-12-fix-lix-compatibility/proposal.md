# Proposal: fix-lix-compatibility

## What

Fix three Lix-compatibility breakages that prevented deployment:

1. `flake.lock` contained a mutable `path:` entry for the `paths` sub-flake — Lix 2.x now rejects these at evaluation time.
2. `darwin-rebuild` was missing from fish's `$PATH` after reboot — `/run/current-system/sw/bin` was never added via `fish_add_path`.
3. All `nix` subcommands in the Justfile lacked `--extra-experimental-features` — Lix requires explicit opt-in for `nix-command` and `flakes`.

## Why

A Lix upgrade tightened enforcement of previously-lax behaviours:
- Mutable lock entries (`type: path` without `narHash`) are now a hard error.
- `nix-command` and `flakes` experimental features must be explicitly enabled per-invocation unless set in `nix.conf`.

The fish PATH issue was a pre-existing bug exposed by the Ghostty launch path change — fish was launched via `/etc/profiles/per-user/…/bin/fish` (bypassing login shell PATH setup), so `/run/current-system/sw/bin` was never on PATH.

## Non-goals

- Switching to a different Nix implementation.
- Changing the deploy mechanism beyond what's needed for compatibility.
- Making `rootPath` dynamic or portable across machines.
