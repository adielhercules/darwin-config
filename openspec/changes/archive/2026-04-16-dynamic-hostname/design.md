## Context

The repo uses a `rootPath = "<init-required>"` placeholder in `nix/flake.nix` that `init.sh` substitutes with the real path on first run, with a pre-commit hook blocking committed real values. The nix-darwin hostname key (`"mymbp"`) has no equivalent treatment — it is hardcoded in two files and committed directly. The `darwin-rebuild switch --flake ".#<name>"` command requires the flake attribute to match the machine's hostname as nix-darwin sees it (resolved via `scutil --get LocalHostName` on macOS).

## Goals / Non-Goals

**Goals:**
- Apply the same placeholder-and-substitute pattern to the hostname as already exists for `rootPath`
- Keep the placeholder string `<hostname>` in committed files; substitute at init time
- Ensure the pre-commit hook blocks both nix files from being committed with a resolved hostname
- Derive the hostname at runtime from `scutil --get LocalHostName` — no manual entry required

**Non-Goals:**
- Supporting multiple host configurations in the same flake (out of scope; single-machine repo)
- Migrating to a fully dynamic flake (e.g., `nixosConfigurations."$(hostname)"`) — complexity is unwarranted here
- Restoring placeholders automatically after `init.sh` runs (user responsibility, same as `rootPath`)

## Decisions

### D1: Placeholder string `<hostname>` (matching `<init-required>` style)

Use angle-bracket syntax consistent with the existing `rootPath` placeholder. The pre-commit hook already uses a `grep -q '<init-required>'` pattern; the new guard follows the same approach. Alternative considered: using an environment variable like `$HOSTNAME` directly in nix — rejected because Nix evaluation is pure and cannot read shell env vars in attribute names without `--impure` in unsafe ways.

### D2: `scutil --get LocalHostName` as the hostname source

`scutil --get LocalHostName` returns the Bonjour/mDNS hostname set in System Preferences → Sharing, which is the value nix-darwin uses. Alternative: `hostname -s` — less reliable on macOS as it reads `/etc/hostname` or the kernel name which may differ. Alternative: `$(hostname)` — returns FQDN on some setups. `scutil` is the canonical macOS source.

### D3: Substitute in both `nix/darwin/default.nix` and `nix/flake.nix`

Both files reference `"mymbp"`. The `default.nix` key is the primary nix-darwin configuration entry point; `flake.nix` references it via `darwinPackages`. Both need the placeholder to ensure neither can be committed with a real value. The substitution is two `sed -i ''` calls, symmetric with the existing rootPath sed call.

### D4: Deploy stage reads hostname directly from `scutil` at runtime

Rather than relying on the substituted file value, `run_deploy` calls `scutil --get LocalHostName` inline to construct the flake target. This makes the deploy stage independent of whether the substitution has been applied, avoiding ordering bugs. The substitution in the nix files is still required for `darwin-rebuild` to find the correct flake attribute.

### D5: Pre-commit hook extended in-place (not split)

The existing hook is a single file checking `nix/flake.nix`. It is extended to also check `nix/darwin/default.nix` for the `<hostname>` placeholder, keeping all staged-file guards in one place.

## Risks / Trade-offs

- **Risk: `scutil` not available** → Only present on macOS; this repo is macOS-only (nix-darwin), so this is a non-issue.
- **Risk: Hostname contains characters unsafe for sed/nix** → macOS hostnames are restricted to alphanumeric + hyphens by the OS. No escaping is needed for the sed substitution or nix attribute name.
- **Risk: User runs `--deploy` before `--paths`** → The substitution won't have run, but `run_deploy` uses `scutil` directly for the flake target, so the deploy itself works. The nix files still contain `<hostname>`, which nix will reject. Mitigation: document that `--all` or `--paths` must be run first, consistent with the existing `rootPath` requirement.
- **Trade-off: Two files need placeholder restoration before committing** → Slightly more friction than before, but the pre-commit hook makes violations impossible to accidentally commit.

## Migration Plan

1. Replace `"mymbp"` with `"<hostname>"` in both nix files (committed state).
2. Update `init.sh` — add hostname sed substitution to `run_paths_sed`; update `run_deploy` to use `scutil`.
3. Update `.githooks/pre-commit` — add guard for `nix/darwin/default.nix`.
4. Update delta specs for `init-script` and `init-script-flags`.
5. Run `init.sh --paths` on the local machine to apply substitution before the next deploy.

Rollback: revert the two nix file changes and the `init.sh` changes; the hook change is safe to leave (it will simply not trigger on the old files).

## Open Questions

None — design is straightforward given the existing pattern.
