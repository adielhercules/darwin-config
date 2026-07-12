## Context

The darwin-config repo manages a macOS development machine declaratively via Nix + nix-darwin + Home Manager + nix-homebrew. The current architecture is monolithic: `nix/flake.nix` exports a single `darwinConfigurations."Adiels-MacBook-Pro"` that imports all modules, brew entries, and settings in one pass. Deployment uses `sudo darwin-rebuild switch --flake "./nix" --impure` and `init.sh`.

You've been using two machines — a personal laptop and a work laptop — and differences are emerging: different Homebrew casks (zed/herd/postman vs vscodium/corporate VPN clients), corporate certificates, different applications in tuna shortcuts, and different aerospace workspace names. Currently no mechanism exists to deploy machine-specific configs from the same repo without manual patching or hostname-based detection inside `init.sh`.

The existing module structure in `nix/modules/home/` follows a flat per-tool pattern (`ghostty.nix`, `helix.nix`, `neovim.nix`, etc.), each with its own inline config or referenced TOML. Nix-darwin's deep-merge model naturally supports list-appending for brew casks and system packages across merged modules.

## Goals / Non-Goals

**Goals:**
- Enable explicit profile-based deployment via `--argstr profile personal` or `--argstr profile work` at CLI time — no hostname detection, no side-channel overrides
- Define a shared default layer (`profiles/defaults.nix`) so brew casks and system packages are not repeated across profiles
- Create a tiny profile-aware module resolver (`nix/lib/resolve-module.nix`) that falls back to shared modules via suffix pattern matching (e.g., `fish-personal.bindings` or `ghostty.nix`)
- Restructure aerospace config into directory with shared base (`main.toml`) + per-profile diffs (`personal.toml`, `work.toml`) — no TOML merge logic needed, separate resolved files loaded from Nix
- Restructure tuna config into directory with shared base module + near-duplicate profile configs (`personal/config.toml`, `work/config.toml` containing full config with ~20% app combo diffs)
- Split fish plugin/base configuration from per-profile bindings into separate files
- Add convenience helpers in `init.sh` that pass explicit profile flags — no hostname detection

**Non-Goals:**
- No hostname detection at all (per user's decision to remove it entirely)
- No TOML merge logic or library — aerospace uses separate resolved TOMLs, tuna uses full per-profile configs rather than partial merges
- No change to ghostty, helix, neovim, zellij, or oh_my_posh modules — these are confirmed identical between machines and remain as single shared files in their current locations
- No restructure of non-profile-related module organization

## Decisions

### Decision 1: CLI-only profile selection via `--argstr profile` (no hostname detection)

The profile is selected EXPLICITLY via `darwin-rebuild switch --flake ".#" --argstr profile <name>`. Convenience functions in `init.sh` (`deploy_personal`, `deploy_work`) encode the flag for convenience, but no builtins-based hostname detection or automatic path checks are used. This eliminates any risk of silent config switching when moving between machines.

**Alternative considered**: Automatic hostname detection via `builtins.readFile "/tmp/hostname"` or checking `/etc/work-machine`. **Rejected** because: (a) adds edge-case bugs on first boot, SSH, or shared environments; (b) violates the principle of explicit deployment — you should always know which config is being deployed; (c) complicates CI/dry-run workflows.

### Decision 2: Profile-aware module resolver (`nix/lib/resolve-module.nix`)

Instead of scattering `lib.optional` / conditional imports throughout `home.nix`, a single helper function encapsulates the resolution logic:

```
resolver path { profile, moduleName }:
  if <module>.<profile>.<ext> exists → return it
  else → return <module>.<ext> (shared)
```

This is ~12 lines of Nix using `builtins.pathExists` on resolved paths. It's called from `home.nix`:

```nix
{ profile ? "personal", ... }: {
  imports = [
    (resolveModule { inherit profile; module = "aerospace"; })     # → aerospace/ dir (always)
    (resolveModule { inherit profile; module = "fish"; })           # → fish-personal.bindings or fish.config
    (resolveModule { inherit profile; module = "tuna"; })          # → tuna/personal/config.toml via module
    (if builtins.pathExists ./ghostty.nix then ./ghostty.nix else {})  # no suffix variant exists
  ] ++ ...
}
```

For modules with multi-file structures (aerospace, tuna), the resolution returns the directory or default module file. For flat per-profile diff files (fish bindings), it resolves to the appropriate `.bindings` file.

**Rationale:** Minimizes conditional logic in `home.nix`, centralizes the pattern matching in one place, and makes adding new profile-specific modules predictable. Without this resolver, every new module with a profile variant requires manual `lib.optional ... pathExists` boilerplate scattered across the imports list.

### Decision 3: Profiles directory for brew/system packages (`nix/darwin/profiles/defaults.nix`)

All brew casks and system packages defined in `nix/darwin/default.nix` move to `profiles/defaults.nix`. Per-profile modules (`personal.nix`, `work.nix`) contain only list-appending entries — they add to the defaults, never replace them.

```nix
# profiles/defaults.nix (always loaded):
homebrew.brews = [ "mas" "xcodes" "aria2" "just" "opencode" "yazi" "rtk" ];
homebrew.casks   = [ "mouseless" "ghostty" "font-monaspace" "alcove" "postman" "herd" "zed" ];
environment.systemPackages = with pkgs; [ comma bat curl neovim lazygit nodejs_22 lua5_1 bun ];

# profiles/personal.nix (appends):
homebrew.casks   = [ "yazi" ];       # ← appends (or duplicates if already in defaults — nix-darwin de-dupes lists)
environment.systemPackages = with pkgs; [ obsidian ];  # ← just extra

# profiles/work.nix (appends):
homebrew.casks   = [ "vscodium" "corporate-vpn" ];
environment.systemPackages = with pkgs; [ work-crlf-cli ];
```

Note: Nix-darwin deep-merges these as module inputs — list entries accumulate. If you want per-profile exclusives (not appends), use `lib.mkForce` but this will rarely be needed since brew casks typically need to be additive rather than exclusive.

**Alternative considered:** Per-profile full lists replacing defaults entirely. **Rejected** because it creates a maintenance burden — every new shared package must be added to both profiles individually, violating DRY.

### Decision 4: Aerospace directory-based with shared + per-profile TOML diffs

```
aerospace/
  default.nix     ← module: enable, package, home.file symlink resolution
  main.toml       ← shared workspace rules, layout options (same on both machines)
  personal.toml   ← only sections that differ from main.toml (e.g., workspace name labels)
  work.toml       ← only sections that differ from main.toml
```

In the Nix module (`aerospace/default.nix`), `main.toml` is always loaded and parsed into an attrset. The per-profile TOML (if one differs from main) is merged via `builtins.mapAttrs` or simple text replacement. Since aerospace diffs are mostly workspace name changes or layout overrides, the shared base covers 90%+ of the file, making this approach very lightweight.

**Alternative considered:** Full separate toml per profile (no shared base). **Rejected** because aerospace differs by a small number of sections — maintaining two near-identical files wastes capacity and introduces drift risk. Using `main.toml` as the anchor means diffs are clear via `diff main.toml work.toml`.

### Decision 5: Tuna directory-based with shared module + near-duplicate profiles

```
tuna/
  default.nix     ← module: symlinks, activation steps (shared)
  config.shared.toml  ← base settings (catalogs, hotkeys, settings — ~80% of file)
  personal/
    config.toml   ← full tuna config with personal app combo shortcuts (~50 diffs from shared)
  work/
    config.toml   ← full tuna config with corporate app combos
```

Since tuna is ~540 lines of deeply nested TOML and the diffs are in `[[comboMode.bindings]]` arrays (which are Nix `builtins.fromTOML` parseable but hard to merge at a key-level), near-duplicate configs per profile are more maintainable than trying to define partial TOML merges in Nix. The shared base (`config.shared.toml`) is documented as the anchor — when adding new settings, both configs stay identical on top of it, and only combo bindings diverge.

The `default.nix` module resolves which config file to use based on profile:

```nix
let activeConfig = if profile == "work" then ./work/config.toml else ./personal/config.toml; in {
  home.file."Library/Application Support/Tuna/config.toml".source = activeConfig;
}
```

**Alternative considered:** Shared base + partial merge via Nix TOML parsing. **Rejected** because: (a) nested array-of-arrays merging in Nix attrsets is fragile and error-prone; (b) diffs between personal/work are ~50 lines of TOML — small enough to maintain two files without drift but too large for a clean partial merge pattern.

### Decision 6: Fish split into base config + per-profile bindings shellInit additions

```
fish.config           ← base module with all plugins, interactiveShellInit greeting, PATH setup
fish-personal.bindings  ← personal alias additions (shellInit content)  
fish-work.bindings    ← work corporate proxy settings (shellInit content)
```

In `home.nix`, fish is loaded as a single resolved module. The base config always loads; the per-profile bindings file appends to `interactiveShellInit`:

```nix
# fish-nix-module handles: programs.fish.plugins + shared interactiveShellInit
# bindings file provides just shellInit content appended via lib.mkMerge
```

This is simpler than separate per-directory configs because fish's config is primarily Nix expressions (plugin definitions, PATH settings) with a small amounts of inline shell strings for aliases/proxies. The diff between personal and work is minimal (a dozen alias lines).

### Decision 7: Ghostty, helix, neovim, zellij, oh_my_posh remain as shared-only (no suffix variants)

Confirmed identical between machines via user confirmation:
- Ghostty — font-family/theme/background settings are the same
- Helix — keys/themes/layout all identical
- Neovim — managed from `dotfiles/nvim.astro-v5/` synced from repo
- Zellij — kdl layout/theme same
- Oh My Posh — `simple.omp.json` shared

These stay as single files in their current flat locations under `nix/modules/home/`. The resolver will naturally fall back to them when no profile-specific variant exists.

## Risks / Trade-offs

### [Risk] Nix homebrew.casks list-appending behavior
Nix-darwin's Homebrew module uses `lib.optionals` and list operations for `casks`. Per-profile modules appending to casks is well-supported in upstream nix-darwin — all brew cask lists from merged modules accumulate. **Mitigation:** Test with a dry-run (`--dry-build --show-trace`) before first deploy; if appends cause duplicates, switch to `lib.mkForce` + manual lists for specific profiles (rare).

### [Risk] Tuna drift between per-profile configs
Near-duplicate TOML config files can drift apart over time. **Mitigation:** Document the shared anchor (`config.shared.toml`) clearly in module comments; keep diffs bounded to `[[comboMode.bindings]]` sections only — never change catalog settings, hotkeys, or base settings across profiles.

### [Risk] Resolver edge cases
The resolver resolves files via path resolution. **Edge case:** a new module name accidentally matches the suffix pattern (e.g., `tuna.personal.toml` resolving to `tuna.personal` when it should resolve as `tuna` → no fallback needed). **Mitigation:** The resolver function returns an error or warning if multiple partial paths match, and the fallback is always unambiguous because it checks for file existence before falling back.

### [Trade-off] Tuna uses full configs vs partial merge
Tuna's near-duplicate pattern means two files to maintain instead of one shared base plus diffs. However, this trade-off is justified because: (a) tuna differences are in deeply nested arrays that are hard to merge cleanly; (b) the diffs are bounded to ~50 lines (combo bindings only); (c) tuna config should be editable as TOML — editing a partial diff requires knowledge of Nix attrset structure.

### [Trade-off] Per-profile brew casks append vs replace
Per-profile modules append rather than replace brew casks. This is desired by default (you want both sets of apps on each machine). However, if you ever need exclusives (e.g., "only on work: install corporate VPN, remove zed"), you'd need `lib.mkForce` syntax. **Mitigation:** Add a comment in `defaults.nix` explaining that all entries in personal/work/nix are additive by default; use `homebrew.casks = lib.mkForce [...]` only for exclusive app lists.

## Migration Plan

1. Create `nix/lib/resolve-module.nix` — profile-aware resolver function
2. Create `nix/darwin/profiles/defaults.nix` — move shared brew casks/system packages from `default.nix` here
3. Create `nix/darwin/profiles/personal.nix` and `work.nix` — per-profile appends only
4. Update `nix/flake.nix` — add `profile` parameter to outputs, forward to darwinConfigurations
5. Update `nix/darwin/default.nix` — accept profile param, import profiles/ modules in order (defaults then personal/work)
6. Restructure `nix/modules/home/aerospace/` — create directory with main.toml + per-profile TOMLs; update `aerospace.nix` to read from resolved config
7. Restructure `nix/modules/home/tuna/` — create directory with shared base module + per-profile full configs; update `tuna.nix` to resolve and symlink profile-specific config
8. Split fish into `fish.config` (base) + `fish-personal.bindings`/`fish-work.bindings` (profiles)  
9. Update `nix/darwin/home.nix` — replace all hardcoded imports with calls to the resolver; remove or bypass any hostname detection remnants
10. Update `init.sh` — add `deploy_personal` and `deploy_work` helpers with explicit `--argstr profile` flags, remove any hostname detection
11. Verify: run `darwin-rebuild switch --flake ".#" --argstr profile personal --impure` then confirm correct brew casks/packages; repeat for work

**Rollback:** Revert all changes to `default.nix`, `home.nix`, `flake.nix`, and `init.sh`. Remove the profiles/ directory and new modules. Move shared configs back from subdirectories to their original flat locations. All existing modules (ghostty, helix, neovim, zellij, oh_my_posh) remain untouched — no rollback risk there.

## Open Questions

- Should aerospace per-profile diffs be in separate TOML files (personal.toml + work.toml as complete replacement of main.toml sections), or are they truly just overrides for specific keys? Currently designed as section-level overrides that merge on top of main.toml's parsed attrset.
- Does the work machine have any nix-specific requirements (nix-certificate paths, nix.conf settings like `extra-ca-file`)? If so, those should also go in profiles/work.nix rather than being handled ad-hoc.
- Could new machines be added later? The design supports adding a third profile easily (e.g., `profiles/remote.nix`) — the resolver function does not hardcode to two profiles.
