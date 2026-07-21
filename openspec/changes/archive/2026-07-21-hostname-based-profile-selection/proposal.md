## Why

Profile selection today requires the user to remember and explicitly pass `--personal`/`--work` (via `init.sh` or `just deploy .#<profile>`) every time they deploy. Since each profile is tied 1:1 to a specific physical machine (Adiels-MacBook-Pro for personal, MPCE-MBP-RWF4347WJP for work), this manual step is redundant: nix-darwin already has a built-in mechanism — `darwin-rebuild switch --flake .` (no `#attr`) auto-selects the `darwinConfigurations` attribute matching the machine's hostname. Adopting this removes a manual, error-prone step (e.g. accidentally deploying the wrong profile on the wrong machine) and simplifies the deploy workflow to a single, hostname-driven command.

## What Changes

- **BREAKING**: Rename flake outputs `darwinConfigurations.personal` / `darwinConfigurations.work` to `darwinConfigurations."Adiels-MacBook-Pro"` / `darwinConfigurations."MPCE-MBP-RWF4347WJP"`, keyed by each machine's actual hostname.
- Internal `profile` string (`"personal"` / `"work"`) is preserved and threaded through `mkDarwinConfig`/`specialArgs`/`resolveModule` exactly as today — only the flake attribute *name* (and the hostname → profile mapping used to derive it) changes, not the internal branching logic.
- Add a hostname → profile mapping (e.g. in `nix/darwin/default.nix` or a new small `nix/hosts.nix`) so each hostname-keyed `darwinConfigurations` entry is built with the correct `profile` argument.
- **BREAKING**: Remove the explicit `--personal`/`--work` override mechanism:
  - Remove `init.sh`'s `set_profile()`, `deploy_personal()`, `deploy_work()` functions and the `--personal`/`--work` CLI flags.
  - Update `init.sh --deploy` (currently a stub that always fails directing users to `--personal`/`--work`) to actually perform the deploy via `just deploy`, since profile-less deploy is now the norm.
  - Simplify `Justfile`'s `flake_target` variable to a fixed `./nix` (no attribute suffix), removing the sed-mutation convention used by `init.sh` for profile selection.
- `just check`/`just deploy`/`just verbose` continue to work unchanged in spirit, but now always resolve the profile automatically via the hostname instead of a previously-persisted `flake_target` value.
- No change to `networking.hostName` management — hostname continues to be managed by macOS/System Settings, not pinned in Nix. Users are responsible for ensuring each machine's actual hostname matches the flake attribute key expected for it.

## Capabilities

### New Capabilities
(none — this is a modification of existing profile-selection behavior)

### Modified Capabilities
- `split-profiles`: The "Profile-based deployment via named flake outputs" requirement changes from explicit `.#personal`/`.#work` targeting to hostname-keyed flake outputs auto-resolved by `darwin-rebuild switch --flake .`. All other requirements in this spec (shared defaults layer, module path resolution, aerospace/tuna/fish/git per-profile split) are unaffected since they operate on the internal `profile` string, not the flake attribute name.
- `init-script-flags`: The `--personal`/`--work` flags are removed; `--deploy` becomes a real (non-stub) deploy invocation; `--all` guidance text updates to no longer mention `--personal`/`--work`.

## Impact

- `nix/flake.nix`: `darwinConfigurations` attribute names change from `personal`/`work` to hostname strings; `configs.pkgs` convenience accessor logic must be updated to reference the new attribute names.
- `nix/darwin/default.nix`: add hostname → profile mapping; `mkDarwinConfig` call sites updated to produce hostname-keyed attrs (internal `profile` argument values unchanged).
- `init.sh`: remove `--personal`/`--work` flags and `set_profile()`/`deploy_personal()`/`deploy_work()`; make `--deploy` functional; update usage/help text and `--all` guidance.
- `Justfile`: `flake_target` becomes a fixed `./nix` (no per-profile suffix); no longer mutated by `init.sh`.
- Documentation/comments in `nix/flake.nix` referencing "no hostname-based auto-resolution" must be corrected to reflect the new behavior.
- No changes anticipated to `nix/darwin/home.nix`, `nix/lib/resolve-module.nix`, `nix/darwin/profiles/{defaults,personal,work}.nix`, or any `nix/modules/home/*` files — they consume `profile` as before.
