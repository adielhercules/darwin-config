## Context

`nix/darwin/default.nix` currently exports a flat attrset `{ personal = mkDarwinConfig "personal"; work = mkDarwinConfig "work"; }` which `nix/flake.nix` assigns directly to `darwinConfigurations` (plus a `pkgs` convenience alias). Users select a profile explicitly with `darwin-rebuild switch --flake ".#personal"` or `".#work"`, wrapped by `init.sh --personal|--work` (which sed-mutates the Justfile's `flake_target`) and `just deploy`.

nix-darwin's `darwin-rebuild` tool has built-in support for hostname-based resolution: when invoked as `darwin-rebuild switch --flake .` (no `#attr` suffix), it runs `scutil --get LocalHostName` and looks for a matching attribute name in `darwinConfigurations` (verified directly in `darwin-rebuild.sh`: `flakeAttr=$(scutil --get LocalHostName)`). Note this is the raw Bonjour/`LocalHostName` value, NOT the `.local`-suffixed mDNS name returned by the `hostname` command (confirmed on the personal machine: `hostname` → `Adiels-MacBook-Pro.local`, `scutil --get LocalHostName` → `Adiels-MacBook-Pro`). Since each profile already maps 1:1 to a specific physical machine (`Adiels-MacBook-Pro` ↔ personal, `MPCE-MBP-RWF4347WJP` ↔ work — confirmed directly by the user via `scutil --get LocalHostName` on the work machine), this built-in mechanism can fully replace the manual `--personal`/`--work` selection step.

## Goals / Non-Goals

**Goals:**
- Auto-select the correct profile based on the machine's hostname, with zero required CLI flags.
- Preserve all existing internal profile-branching logic (`mkModules profile`, `mkSpecialArgs profile`, `resolveModule`) untouched — only the flake attribute *name* changes, derived from a hostname → profile mapping.
- Simplify `init.sh`/`Justfile` by removing the sed-mutation convention now that there's nothing to persist.
- Keep the assertion that guards against unknown/typo'd profile strings.

**Non-Goals:**
- Managing/pinning `networking.hostName` in Nix (explicitly declined by user — hostname stays under macOS/System Settings control).
- Supporting more than two machines/profiles in this change (mapping table can be extended later trivially).
- Changing any per-profile module content (`personal.nix`, `work.nix`, aerospace/tuna/fish/git split) — out of scope, unaffected by this change.

## Decisions

### 1. Hostname → profile mapping lives in `nix/darwin/default.nix`
Add a small `let`-bound attrset, e.g.:
```nix
hostProfiles = {
  "Adiels-MacBook-Pro" = "personal";
  "MPCE-MBP-RWF4347WJP" = "work";
};
```
and replace the final expression:
```nix
lib.mapAttrs (_hostname: profile: mkDarwinConfig profile) hostProfiles
```
**Rationale**: keeps the mapping colocated with `mkDarwinConfig`/`mkModules`/`mkSpecialArgs`, avoids introducing a new file for a two-entry table, and requires no changes to `mkDarwinConfig`'s existing profile validation (assert still runs on the internal `profile` value produced by the mapping, catching any typo in the mapping table itself).
**Alternative considered**: a separate `nix/hosts.nix` file. Rejected — unnecessary indirection for a 2-line table; can be extracted later if the mapping grows.

### 2. `nix/flake.nix` no longer special-cases `pkgs`/`personal` by name
Since `darwinConfigurations` attribute names are no longer stable literals (`personal`/`work`) but hostnames, `configs.pkgs = configs.personal.pkgs` must reference the new hostname key, e.g. `configs."Adiels-MacBook-Pro".pkgs`. Update the comment block explaining the previous "no hostname-based auto-resolution" design decision to describe the new behavior.
**Alternative considered**: derive `pkgs` from `builtins.head (builtins.attrValues configs)` to avoid hardcoding a hostname string in `flake.nix` twice. Rejected for clarity — an explicit, readable reference is preferred over cleverness in a rarely-touched convenience accessor.

### 3. `init.sh` and `Justfile` simplification
- Remove `set_profile()`, `deploy_personal()`, `deploy_work()`, and the `--personal`/`--work` flag handling from `init.sh`.
- `Justfile`'s `flake_target` becomes a fixed `./nix` (no `#<profile>` suffix), so `darwin-rebuild switch --flake ./nix` always auto-resolves via hostname.
- `init.sh --deploy` (currently a stub that always errors) becomes a real deploy path: it invokes `just deploy` directly, since there is no longer a profile to select first.
- Update `--all` and usage/help text accordingly (drop references to `--personal`/`--work`).
**Rationale**: matches the user's explicit choice to fully remove the manual override in favor of always auto-detecting.

### 4. Internal `profile` string naming preserved
Per user's explicit choice, `"personal"`/`"work"` remain the internal values threaded through `specialArgs`/`resolveModule`/profile files. Only the *lookup key* (flake attribute name) changes from these literal strings to hostnames. This minimizes the diff surface — `nix/darwin/home.nix`, `nix/lib/resolve-module.nix`, and all `nix/modules/home/*` files require zero changes.

## Risks / Trade-offs

- **[Risk]** If a machine's actual hostname doesn't exactly match the corresponding key in `hostProfiles` (e.g. macOS changes it, or DHCP-assigned `.local` suffix behaves differently than expected), `darwin-rebuild switch --flake .` will fail to find a matching attribute, with a somewhat unhelpful "attribute not found" style error.
  → **Mitigation**: Document in `nix/flake.nix` comments how to verify the current hostname (`scutil --get LocalHostName` / `hostname`) and how to fall back to explicit `--flake ".#<hostname>"` targeting if it ever mismatches. The explicit hostname-keyed attribute remains directly addressable as an escape hatch even without the removed `--personal`/`--work` sed-based flow.
- **[Risk]** Removing `--personal`/`--work` from `init.sh` is a breaking CLI change for any muscle-memory / existing scripts/aliases the user has.
  → **Mitigation**: User explicitly requested full removal; call this out clearly in the PR/commit message and README if applicable.
- **[Trade-off]** Hardcoding hostnames as literal flake attribute names (rather than using `--argstr`/env-var driven profile selection) means adding a third machine requires editing `nix/darwin/default.nix`'s mapping table directly. Acceptable given only two machines exist today and the mapping is a single obvious line to add.

## Migration Plan

1. Update `nix/darwin/default.nix`: add `hostProfiles` mapping, replace final attrset expression, keep `mkDarwinConfig`'s profile assertion unchanged.
2. Update `nix/flake.nix`: fix `configs.pkgs` reference to use the new hostname key; update comments describing profile-selection behavior.
3. Update `init.sh`: remove `--personal`/`--work`/`set_profile`/`deploy_personal`/`deploy_work`; make `--deploy` functional; update `--all`/usage text.
4. Update `Justfile`: set `flake_target := "./nix"` as the fixed, non-mutated default.
5. Run `just check` (dry-run) on the current machine to confirm the hostname-based resolution picks the expected profile.
6. No rollback complexity: this is a pure refactor of flake-output naming and CLI wrapper scripts; reverting is a straightforward `git revert` if the hostname-based resolution misbehaves on either machine.

## Open Questions

- None outstanding — all key decisions were confirmed with the user (hostname-keyed outputs: yes; pin `networking.hostName`: no; keep manual override: no, remove entirely; internal profile naming: keep "personal"/"work").
