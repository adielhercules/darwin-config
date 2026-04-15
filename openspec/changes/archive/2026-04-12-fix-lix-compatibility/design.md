# Design: fix-lix-compatibility

## 1. Remove paths sub-flake — hardcode rootPath

**Problem**: `nix/flake.nix` had `paths.url = "path:./paths"` pointing to `nix/paths/flake.nix`, which only exists to expose `rootPath = "/Users/adielhercules/darwin-config"`. Lix now rejects lock entries of `type: path` without a `narHash`.

**Option considered — `builtins.toString self`**: Rejected. `self` resolves to the flake source root (`nix/`), not the repo root (`darwin-config/`). `dotfiles/` lives at `darwin-config/dotfiles/`, so `${builtins.toString self}/dotfiles` would never resolve correctly. Tested and confirmed broken.

**Decision**: Define `rootPath` as an inline `let` binding in `flake.nix` outputs:

```nix
outputs = inputs@{ self, ... }:
  let paths = { rootPath = "/Users/adielhercules/darwin-config"; };
  in { ... }
```

`nix/paths/flake.nix` already hardcoded this value — no regression. `paths` input removed from `flake.nix` and its node removed from `flake.lock`. `initialize_paths.sh` is now redundant (left in place, harmless).

## 2. Add /run/current-system/sw/bin to fish PATH

**Problem**: Ghostty launches fish directly via `/etc/profiles/per-user/adielhercules/bin/fish`, bypassing macOS login shell PATH setup. `/run/current-system/sw/bin` (where `darwin-rebuild`, `nix`, etc. live) was never added to fish's PATH.

**Decision**: Add `fish_add_path /run/current-system/sw/bin` to `shellInit` in both fish modules:
- `nix/modules/home/fish.nix` (active, used by home.nix)
- `nix/home/fish.nix` (legacy duplicate, kept in sync)

## 3. Justfile nix_flags variable

**Problem**: Lix does not enable `nix-command` or `flakes` by default. Every `nix` subcommand invocation needs `--extra-experimental-features 'nix-command flakes'`.

**Decision**: Define a single variable at the top of the Justfile:

```just
nix_flags := "--extra-experimental-features 'nix-command flakes'"
```

All affected recipes use `nix {{nix_flags}} <subcommand>`. Legacy commands (`nix-env`, `nix-collect-garbage`, `nix-tree`) are unaffected — they are separate binaries that don't use the experimental features flag.

**Affected recipes**: `optimise`, `up`, `up-unstable-to`, `up-secrets`, `update-brew` (×4), `repl`, `gc` (×2), `clean`.
