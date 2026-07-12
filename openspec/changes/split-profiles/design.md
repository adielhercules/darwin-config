## Context

The darwin-config repo manages a macOS development machine declaratively via Nix + nix-darwin + Home Manager + nix-homebrew. The current architecture is monolithic: `nix/flake.nix` exports a single `darwinConfigurations."Adiels-MacBook-Pro"` that imports all modules, brew entries, and settings in one pass. Deployment uses `sudo darwin-rebuild switch --flake "./nix" --impure` and `init.sh`.

You've been using two machines — a personal laptop and a work laptop — and differences are emerging: different Homebrew casks (zed/herd/postman vs vscodium/corporate VPN clients), corporate certificates, different applications in tuna shortcuts, and different aerospace workspace names. Currently no mechanism exists to deploy machine-specific configs from the same repo.

The existing module structure in `nix/modules/home/` follows a flat per-tool pattern (`ghostty.nix`, `helix.nix`, `neovim.nix`, etc.), each with its own inline config or referenced TOML. Nix-darwin's deep-merge model naturally supports list-appending for brew casks and system packages across merged modules.

`init.sh` today has a `run_hostname_sed` bootstrap step that substitutes a `<hostname>` placeholder in `flake.nix`/`default.nix` with the machine's actual `scutil` hostname, one time, when first cloning onto a new Mac. This exists because nix-darwin's `darwin-rebuild switch --flake .` (no explicit `#<name>` target) auto-resolves the darwinConfiguration by matching the current machine's hostname to a `darwinConfigurations.<hostname>` key. This is unrelated to profile selection — it is purely how the flake's single configuration got its name to enable that auto-resolution convenience.

Nix flakes evaluate `outputs` as a pure function of `inputs` only — there is no mechanism to pass extra CLI arguments (`--argstr`, etc.) into a flake's output evaluation the way `nix-build`/`nix-instantiate` support for non-flake expressions. This means profile selection cannot be a CLI flag layered on top of a single flake output; it must be encoded as the flake output name itself, or read impurely via an environment variable inside an `--impure` build. This repo already deploys with `--impure`, but named flake outputs were chosen as the cleaner, more idiomatic mechanism (see Decision 1).

## Goals / Non-Goals

**Goals:**
- Enable explicit profile-based deployment via named flake outputs: `darwin-rebuild switch --flake ".#personal"` or `".#work"` — always explicit, no hostname-based auto-resolution, no environment variables
- Define a shared default layer (`profiles/defaults.nix`) so brew casks and system packages are not repeated across profiles
- Create a tiny profile-aware module resolver (`nix/lib/resolve-module.nix`) that falls back to shared modules via suffix pattern matching (e.g., `fish-personal.bindings` or `ghostty.nix`)
- Restructure aerospace config into directory with shared base (`main.toml`) + per-profile diffs (`personal.toml`, `work.toml`), merged via `lib.recursiveUpdate` on the parsed TOML attrsets, with one narrowly-scoped array-concat exception for `on-window-detected` (see Decision 6) — no general-purpose custom merge logic, no text-replacement hacks
- Restructure tuna config into directory with shared base module + near-duplicate profile configs (`personal/config.toml`, `work/config.toml` containing full config with ~20% app combo diffs)
- Split fish plugin/base configuration from per-profile bindings into separate files
- Provide a safe, non-committed mechanism for work-only secrets (corporate certificates, proxy settings) via an external file path, with a soft build-time warning if it's missing when deploying the work profile
- Add convenience helpers in `init.sh` that wrap the named-flake-output deploy commands
- Remove the now-obsolete `run_hostname_sed` bootstrap step from `init.sh`

**Non-Goals:**
- No CLI-argument-based profile selection (`--argstr`) — this does not work with flakes and is explicitly not attempted
- No hostname-based auto-resolution of the darwinConfiguration — giving this up is an accepted trade-off of moving to named, profile-keyed outputs
- No TOML partial-merge logic for tuna — tuna uses full near-duplicate per-profile configs rather than partial merges, because its diffs live in deeply nested arrays that don't merge cleanly
- No change to ghostty, helix, neovim, zellij, or oh_my_posh modules — these are confirmed identical between machines and remain as single shared files in their current locations
- No secrets-management tooling (agenix, sops-nix) — the external file mechanism is sufficient for the stated need and avoids adding new dependencies
- No restructure of non-profile-related module organization

## Decisions

### Decision 1: Named flake outputs (`darwinConfigurations.personal` / `.work`), not `--argstr`

`darwin-rebuild switch --flake ".#personal"` and `".#work"` are two independent flake outputs sharing the same base modules. Profile selection is baked into which output you target — there is no CLI flag, environment variable, or side-channel involved.

**Alternative considered**: `--argstr profile <name>`. **Rejected — not viable.** Flake outputs are evaluated as a pure function of `inputs`; there is no CLI-argument-passing mechanism into flake output evaluation (unlike `nix-build --argstr` for legacy non-flake expressions). Any design relying on `--argstr` with a flake-based `darwin-rebuild switch --flake` command would silently ignore the flag.

**Alternative considered**: `builtins.getEnv "DARWIN_PROFILE"` combined with `--impure` (already used by this repo for deployment). **Rejected** in favor of named outputs — while technically workable, it's less discoverable (`darwin-rebuild switch --flake .#personal` is self-documenting; an env var requires reading `init.sh` or docs to discover) and named outputs are the more idiomatic flake pattern for this use case.

**Trade-off accepted**: `darwin-rebuild switch --flake .` (bare, no target) no longer auto-resolves via hostname matching. Every deploy now requires an explicit `--flake ".#personal"` or `".#work"`. This is intentional — explicitness was preferred over convenience per prior discussion.

### Decision 2: Remove `run_hostname_sed` from `init.sh`

Since darwinConfigurations are now keyed by profile name (not hostname), the `run_hostname_sed` bootstrap step — which substituted a `<hostname>` placeholder with `scutil --get LocalHostName` — no longer serves any purpose and is removed entirely from `init.sh`. The `run_paths` function (rootPath substitution + git hooks activation) is retained; only the hostname substitution sub-step is dropped.

### Decision 3: Profile-aware module resolver (`nix/lib/resolve-module.nix`)

Instead of scattering `lib.optional` / conditional imports throughout `home.nix`, a single helper function encapsulates the resolution logic:

```
resolver { profile, moduleName }:
  if <module>.<profile>.<ext> exists → return it
  else → return <module>.<ext> (shared)
```

This is ~12 lines of Nix using `builtins.pathExists` on resolved paths. It's called from `home.nix`:

```nix
{ profile, ... }: {
  imports = [
    (resolveModule { inherit profile; module = "aerospace"; })     # → aerospace/ dir (always)
    (resolveModule { inherit profile; module = "fish"; })           # → fish-personal.bindings or fish.nix
    (resolveModule { inherit profile; module = "tuna"; })          # → tuna/ dir, resolves personal/work config internally
    ./ghostty.nix   # no suffix variant exists — imported directly, unconditionally
  ] ++ ...
}
```

For modules with multi-file structures (aerospace, tuna), the resolution returns the directory's `default.nix`, which internally resolves which TOML/config to load. For flat per-profile diff files (fish bindings), the resolver returns the appropriate `.bindings` file directly.

**Rationale:** Minimizes conditional logic in `home.nix`, centralizes the pattern matching in one place, and makes adding new profile-specific modules predictable. Without this resolver, every new module with a profile variant requires manual `lib.optional ... pathExists` boilerplate scattered across the imports list.

### Decision 4: Profiles directory for brew/system packages (`nix/darwin/profiles/defaults.nix`)

All brew casks and system packages defined in `nix/darwin/default.nix` move to `profiles/defaults.nix`. Per-profile modules (`personal.nix`, `work.nix`) contain only list-appending entries — they add to the defaults, never replace them.

```nix
# profiles/defaults.nix (always loaded):
homebrew.brews = [ "mas" "xcodes" "aria2" "just" "opencode" "yazi" "rtk" ];
homebrew.casks   = [ "mouseless" "ghostty" "font-monaspace" "alcove" "postman" "herd" "zed" ];
environment.systemPackages = with pkgs; [ comma bat curl neovim lazygit nodejs_22 lua5_1 bun ];

# profiles/personal.nix (appends):
environment.systemPackages = with pkgs; [ obsidian ];  # ← just extra

# profiles/work.nix (appends):
homebrew.casks   = [ "vscodium" "corporate-vpn" ];
environment.systemPackages = with pkgs; [ work-crlf-cli ];
```

Note: Nix-darwin deep-merges these as module inputs — list entries accumulate. If exclusives are ever needed (not appends), use `lib.mkForce`, though this should rarely be necessary since brew casks are additive by nature.

**Alternative considered:** Per-profile full lists replacing defaults entirely. **Rejected** because it creates a maintenance burden — every new shared package must be added to both profiles individually, violating DRY.

### Decision 5: External secrets directory for work-only sensitive values

This repository is public on GitHub. Corporate certificates, proxy URLs, and VPN settings for the work profile must never be committed in plaintext. Rather than a single hardcoded `work.nix` file, the whole `~/.config/darwin-secrets/` directory is treated as an auto-discovered drop-in location:

```nix
# nix/darwin/profiles/work.nix
{ lib, config, ... }:
let
  secretsDir = "${config.home.homeDirectory}/.config/darwin-secrets";
  secretsFile = "${secretsDir}/work.nix";
  hasSecrets = builtins.pathExists secretsFile;

  # Auto-discover any .crt/.pem files dropped in the same directory —
  # no per-file registration needed, just place the file and rebuild.
  certFiles =
    if builtins.pathExists secretsDir then
      lib.mapAttrsToList (name: _: "${secretsDir}/${name}")
        (lib.filterAttrs
          (name: type:
            type == "regular" && (lib.hasSuffix ".crt" name || lib.hasSuffix ".pem" name))
          (builtins.readDir secretsDir))
    else
      [ ];
in {
  imports = lib.optional hasSecrets secretsFile;
  security.pki.certificateFiles = certFiles;
  warnings = lib.optional (!hasSecrets)
    "profile=work but no secrets file found at ${secretsFile} — corporate certs/proxy config will be missing.";
}
```

- `~/.config/darwin-secrets/` lives entirely outside the git repository — never committed, never in git history (the directory itself does not exist in the repo; only `profiles/work.nix.example` is committed, as a template)
- `work.nix` inside that directory is a plain Nix module (attrset) for proxy/VPN/misc settings, manually placed on the work machine by the user (out of band — password manager export, private note, AirDrop, etc.)
- Any `.crt`/`.pem` files dropped in the same directory are auto-discovered via `builtins.readDir` and fed into `security.pki.certificateFiles` — no need to individually reference each cert file path in Nix
- `profiles/work.nix` conditionally imports `work.nix` if present, via `builtins.pathExists`
- If `profile == "work"` and `work.nix` is absent, a `warnings` entry is emitted — nix-darwin surfaces this as a build-time warning in `darwin-rebuild switch` output, but the build does **not** fail (missing cert files simply result in an empty `certificateFiles` list, no warning needed for those since they're purely additive)
- The `personal` profile never references this path and never warns
- `profiles/work.nix.example` (committed) documents this directory convention directly in its header comment: drop `work.nix` (Nix module) plus any `.crt`/`.pem` cert files into `~/.config/darwin-secrets/` and they are picked up automatically on the next `darwin-rebuild switch --flake ".#work"` — no other registration step required

**Alternative considered:** agenix or sops-nix for encrypted secrets committed to the repo. **Rejected** — heavier tooling than needed for the stated requirement; introduces new dependencies (age/SOPS keys, encryption workflow) for a need that's fully met by keeping the directory out of git entirely. Can be revisited later if secrets need to be shared across multiple people/machines.


### Decision 6: Aerospace directory-based with shared + per-profile TOML diffs, merged via `lib.recursiveUpdate` (with a targeted array-concat exception for `on-window-detected`)

```
aerospace/
  default.nix     ← module: enable, package, home.file symlink resolution, TOML merge
  main.toml       ← shared workspace rules, layout options (same on both machines)
  personal.toml   ← only sections that differ from main.toml (e.g., workspace name labels)
  work.toml       ← only sections that differ from main.toml
```

In `aerospace/default.nix`:

```nix
{ pkgs, lib, profile, ... }:
let
  main = builtins.fromTOML (builtins.readFile ./main.toml);
  profileOverridePath = ./. + "/${profile}.toml";
  profileOverrides =
    if builtins.pathExists profileOverridePath
    then builtins.fromTOML (builtins.readFile profileOverridePath)
    else { };
  merged = lib.recursiveUpdate main profileOverrides // {
    # `lib.recursiveUpdate` replaces arrays wholesale rather than merging
    # elements, which would silently drop main.toml's shared app-routing
    # rules whenever a profile defines its own `on-window-detected` entries.
    # This one array-typed key is concatenated explicitly instead.
    on-window-detected = (main.on-window-detected or [ ])
      ++ (profileOverrides.on-window-detected or [ ]);
  };
in {
  config.programs.aerospace = {
    enable = true;
    launchd.enable = true;
    package = pkgs.unstable.aerospace;
    settings = merged;
  };
}
```

`lib.recursiveUpdate` is a stock, battle-tested nixpkgs `lib` function used for all scalar/attrset keys — no general-purpose custom merge logic is written. The one deliberate, narrowly-scoped exception is the `on-window-detected` array: since aerospace diffs are mostly workspace name changes or layout overrides, the shared base covers the vast majority of the file, making per-profile TOMLs very small — except for the case (introduced by this change) where a profile needs to add new app-routing rules (e.g. `work.toml` routing Teams/Outlook/Edge to a new `F` "Focus" workspace) without losing the shared rules for Ghostty/Xcode/Android Studio/Music/Dia/floating-window handling.

**Alternative considered:** Require `work.toml`/`personal.toml` to duplicate the full `on-window-detected` array (including all shared entries) whenever they need to add new routing rules, keeping `lib.recursiveUpdate` fully generic with zero exceptions. **Rejected** — this reintroduces the exact drift risk being avoided for aerospace in the first place (the array would need to be kept in sync by hand across `main.toml` and every profile override that touches it), for a cost of only a 2-line special case in `default.nix`.

**Alternative considered:** Full separate TOML per profile (no shared base, like tuna). **Rejected** because aerospace differs by a small number of sections — maintaining two near-identical files wastes effort and introduces drift risk. Using `main.toml` as the anchor keeps diffs small and explicit.

### Decision 7: Tuna directory-based with shared module + near-duplicate profiles (no merge)

```
tuna/
  default.nix     ← module: symlinks, activation steps (shared), resolves active config by profile
  config.shared.toml  ← base settings (catalogs, hotkeys, settings — the majority of the file)
  personal/
    config.toml   ← full tuna config with personal app combo shortcuts
  work/
    config.toml   ← full tuna config with corporate app combos
```

Since tuna is ~540 lines of deeply nested TOML and the diffs are in `[[comboMode.bindings]]` arrays (arrays of objects, sometimes 3-4 levels deep), attempting a partial merge (as with aerospace) is fragile — `lib.recursiveUpdate` replaces arrays wholesale rather than merging them element-by-element, so array-based diffs don't compose the way flat key diffs do. Near-duplicate full configs per profile are more maintainable here.

`default.nix` resolves which config file to use based on profile:

```nix
{ profile, ... }:
let activeConfig = if profile == "work" then ./work/config.toml else ./personal/config.toml; in {
  home.file."Library/Application Support/Tuna/config.toml".source = activeConfig;
}
```

**Alternative considered:** Shared base + partial merge via Nix TOML parsing (same pattern as aerospace). **Rejected** because: (a) tuna's diffs are inside nested arrays, where `lib.recursiveUpdate` cannot selectively merge individual array elements — it replaces the whole array; (b) the shared base is documented as an authoring anchor (`config.shared.toml`) for humans to diff against manually, even though it isn't programmatically merged.

### Decision 8: Fish split into base config + per-profile bindings shellInit additions

```
fish.nix                ← base module with all plugins, interactiveShellInit greeting, PATH setup (unchanged file, unchanged name)
fish-personal.bindings  ← personal alias additions (shellInit content)
fish-work.bindings      ← work corporate proxy settings (shellInit content)
```

`fish.nix` keeps its existing `.nix` extension (a Nix module must be `.nix` or a directory with `default.nix` to be importable — the earlier draft's `fish.config` name was corrected). In `home.nix`, fish is loaded as: the base `fish.nix` unconditionally, plus the resolved per-profile bindings file appended to `interactiveShellInit` via `lib.mkMerge`.

This is simpler than a directory-based split because fish's config is primarily Nix expressions (plugin definitions, PATH settings) with small inline shell strings for aliases/proxies. The diff between personal and work is minimal (roughly a dozen alias lines).

### Decision 9: Ghostty, helix, neovim, zellij, oh_my_posh remain as shared-only (no suffix variants)

Confirmed identical between machines via user confirmation:
- Ghostty — font-family/theme/background settings are the same
- Helix — keys/themes/layout all identical
- Neovim — managed from `dotfiles/nvim.astro-v5/` synced from repo
- Zellij — kdl layout/theme same
- Oh My Posh — `simple.omp.json` shared

These stay as single files in their current flat locations under `nix/modules/home/`. The resolver naturally falls back to them when no profile-specific variant exists.

## Risks / Trade-offs

### [Risk] Loss of hostname-based auto-resolution
Every deploy now requires an explicit `--flake ".#personal"` or `".#work"` target — running bare `darwin-rebuild switch --flake .` will fail (no default darwinConfiguration matches). **Mitigation:** `init.sh`'s `deploy_personal`/`deploy_work` helpers encode the correct flag so this is rarely typed manually; document clearly in README/comments.

### [Risk] Nix homebrew.casks list-appending behavior
Nix-darwin's Homebrew module uses list operations for `casks`. Per-profile modules appending to casks is well-supported in upstream nix-darwin — all brew cask lists from merged modules accumulate. **Mitigation:** Test with `--dry-build` before first real deploy; if appends cause duplicates, switch to `lib.mkForce` + manual lists for specific profiles (rare).

### [Risk] Missing work secrets file silently degrading config
If `~/.config/darwin-secrets/work.nix` is absent when deploying the work profile, corporate certs/proxy settings are simply missing — the build still succeeds (by design, soft warning only). **Mitigation:** The `warnings` mechanism surfaces this clearly in `darwin-rebuild switch` output; the file's expected schema should be documented (e.g., a `work.nix.example` template committed to the repo, showing the expected attrset shape without real values).

### [Risk] Tuna drift between per-profile configs
Near-duplicate TOML config files can drift apart over time since they are not programmatically merged. **Mitigation:** Document the shared anchor (`config.shared.toml`) clearly in module comments for human reference; keep diffs bounded to `[[comboMode.bindings]]` sections only — never change catalog settings, hotkeys, or base settings independently across profiles.

### [Risk] Resolver edge cases
The resolver resolves files via path existence checks. **Edge case:** ambiguous naming could cause an unintended file to match a suffix pattern. **Mitigation:** the resolver's fallback logic is unambiguous — it checks for the exact profile-suffixed path first, and only falls back to the shared path if that specific file does not exist; no partial/fuzzy matching is used.

### [Trade-off] Tuna uses full configs vs partial merge
Tuna's near-duplicate pattern means two files to maintain instead of one shared base plus diffs. This is justified because: (a) tuna differences are in deeply nested arrays that `lib.recursiveUpdate` cannot cleanly merge; (b) tuna config should remain editable as plain TOML — editing a partial diff would require understanding Nix attrset merge semantics for arrays, which is more error-prone than editing two complete files.

### Decision 10: Shared `pkgs` exposed as `darwinConfigurations.pkgs`, not a separate `darwinPackages` output

The current (pre-change) `flake.nix` exposes `darwinPackages = self.darwinConfigurations."<hostname>".pkgs;` as a convenience output for tooling/`nix repl` access to the resolved package set (with the `unstable`/`zjstatus` overlays applied). With two named profiles, this single-hostname reference becomes stale.

Since `darwinConfigurations` is a plain attrset, a `pkgs` key can be added as a sibling of `personal`/`work` without conflicting with `darwin-rebuild switch --flake ".#personal"` / `".#work"` (nix-darwin only inspects the specific named key targeted; an extra sibling attribute is inert):

```nix
outputs = { ... }:
  let
    configs = import ./darwin { ... };  # { personal = ...; work = ...; }
  in {
    darwinConfigurations = configs // {
      pkgs = configs.personal.pkgs;  # identical overlays on both profiles
    };
  };
```

This gives `self.darwinConfigurations.pkgs` directly and removes the separate `darwinPackages` output entirely. Since both profiles apply identical `nixpkgs.overlays`, sourcing this from `configs.personal.pkgs` vs `configs.work.pkgs` is functionally equivalent — purely a naming/access-path convenience, with zero effect on which profile's `profiles/*.nix`, aerospace/tuna/fish configs, etc. are selected during an actual `darwin-rebuild switch` for either profile.

**Alternative considered:** Keep a separate top-level `darwinPackages` output (e.g. `darwinPackages = configs.personal.pkgs;`). **Rejected** per user preference for a flatter, more general access path (`self.darwinConfigurations.pkgs` instead of a differently-named sibling output).

### [Trade-off] Per-profile brew casks append vs replace
Per-profile modules append rather than replace brew casks — both machines' shared apps stay installed on each. If exclusives are ever needed (e.g., "only on work: install corporate VPN, remove zed"), `lib.mkForce` syntax would be required. **Mitigation:** Document in `defaults.nix` that all entries in `personal.nix`/`work.nix` are additive by default.

### Decision 11: `init.sh` for bootstrap/profile-switch only; `Justfile` for day-to-day deploys

This repo already uses `just deploy` (via `Justfile`) as the day-to-day deploy entrypoint — `init.sh` is a separate, older script originally meant only for first-time bootstrap (setting `rootPath`, activating git hooks, running `nix run ... darwin-rebuild -- switch` once). Prior to this change, `Justfile`'s `deploy`/`verbose`/`check` recipes hardcoded `--flake ./nix --impure` (bare, no profile) — which breaks entirely under named profile outputs, since no bare/default `darwinConfigurations` attribute exists (see Decision 1's trade-off).

Rather than have every `just` recipe require a `profile` parameter (breaking the simple `just deploy` muscle-memory workflow), the profile selection is persisted as a `Justfile` variable, set once by `init.sh`:

```just
# Justfile
flake_target := "<not_initialized>"
...
deploy: && optimise
  sudo {{darwin_rebuild}} switch --flake {{flake_target}} --impure
```

`init.sh --personal` / `--work` `sed`-replace `flake_target := "..."` with `./nix#personal` / `./nix#work` (the same locally-mutated-but-uncommitted convention already used for `rootPath` in `flake.nix` — see the `gitskip`/`gitunskip` aliases in `darwin/default.nix`), then immediately invoke `just deploy` to perform the actual switch. This keeps `darwin_rebuild`/`optimise` invocation logic in exactly one place (`Justfile`), rather than duplicating it in `init.sh`.

The default value `"<not_initialized>"` is deliberately not a valid flake output reference — `just deploy` run before ever running `init.sh` fails clearly (`./nix#<not_initialized>` doesn't resolve to any `darwinConfigurations` attribute) rather than silently falling back to some default profile or a stale bare target.

**Division of responsibility going forward:**
- `init.sh --personal` / `--work`: initial deploy, or switching a machine's profile — run rarely
- `just deploy` / `just verbose` / `just check`: regular day-to-day deploys — reuse whichever profile was last selected

**Alternative considered:** Have `init.sh` fully own deploys (keep `just deploy` targeting a hardcoded default profile, or remove `just deploy` in favor of always using `init.sh`). **Rejected** — the user's existing daily workflow already relies on `just deploy` (with its `optimise`-chained cleanup step, `check`/`verbose` variants, and the broader `sanitize-all`/`update` recipe chains); changing that muscle memory has more cost than persisting one variable via `sed`.

## Migration Plan

1. Create `nix/lib/resolve-module.nix` — profile-aware resolver function
2. Create `nix/darwin/profiles/defaults.nix` — move shared brew casks/system packages from `default.nix` here
3. Create `nix/darwin/profiles/personal.nix` — personal-only appends
4. Create `nix/darwin/profiles/work.nix` — work-only appends, plus external secrets conditional import + warning
5. Update `nix/flake.nix` — replace the single `darwinConfigurations."Adiels-MacBook-Pro"` with `darwinConfigurations.personal` and `darwinConfigurations.work`, both built from the same base module list plus their respective `profiles/*.nix`
6. Update `nix/darwin/default.nix` — accept a `profile` parameter (passed from `flake.nix`, not CLI), thread it through to home-manager's `extraSpecialArgs` and to any module needing it (aerospace, tuna)
7. Restructure `nix/modules/home/aerospace/` — create directory with `main.toml` + per-profile TOMLs; rewrite `aerospace.nix` as `aerospace/default.nix` using `lib.recursiveUpdate` (with the `on-window-detected` array-concat exception, see Decision 6)
8. Restructure `nix/modules/home/tuna/` — create directory with shared base module + per-profile full configs; rewrite `tuna.nix` as `tuna/default.nix` resolving the active config by profile
9. Split fish into `fish.nix` (base, unchanged name) + `fish-personal.bindings`/`fish-work.bindings` (profiles)
10. Update `nix/darwin/home.nix` — replace hardcoded imports with resolver calls where profile-dependent
11. Update `init.sh` — remove `run_hostname_sed`; add `deploy_personal`/`deploy_work` helpers that persist the profile into `Justfile`'s `flake_target` and delegate to `just deploy`
12. Update `Justfile` — add `flake_target := "<not_initialized>"`; update `deploy`/`verbose`/`check` to use `--flake {{flake_target}} --impure`
13. Create `~/.config/darwin-secrets/work.nix.example` template (committed, no real secrets) documenting the expected shape for the real file
14. Verify: `darwin-rebuild switch --flake ".#personal" --dry-build`, then `--flake ".#work" --dry-build` (this can be tested entirely from the personal machine, since profile selection is explicit and not hostname-gated); verify `just deploy` correctly reuses a persisted profile and fails clearly with the `<not_initialized>` default

**Rollback:** Revert `default.nix`, `home.nix`, `flake.nix`, `init.sh`, and `Justfile`. Remove the `profiles/` directory and new modules. Move shared configs back from subdirectories to their original flat locations. All existing modules (ghostty, helix, neovim, zellij, oh_my_posh) remain untouched — no rollback risk there. Restore `run_hostname_sed` from git history if reverting fully.

## Open Questions

- Does the work machine require nix-level substituter/proxy configuration (`nix.settings.substituters`, `netrc-file`) in addition to app-level certs? If so, these values also belong in the external `~/.config/darwin-secrets/work.nix` file, not hardcoded in the repo.
- Could a third profile be added later (e.g., a shared "remote"/server profile)? The resolver and profiles/ pattern both support this without structural changes — just add `profiles/remote.nix` and a corresponding `darwinConfigurations.remote` output.
- Should the `work.nix.example` template be validated (e.g., a Nix module `options` block with `mkOption` declarations) so a malformed real secrets file fails clearly at eval time rather than silently omitting settings?
