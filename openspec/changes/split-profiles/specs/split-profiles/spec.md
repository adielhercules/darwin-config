## ADDED Requirements

### Requirement: Profile-based deployment via named flake outputs
The system SHALL allow users to select a deployment profile (personal or work) explicitly by targeting a named flake output — `darwin-rebuild switch --flake ".#personal"` or `".#work"`. Profile selection SHALL NOT rely on `--argstr`, environment variables, or hostname-based auto-resolution, since flake outputs are evaluated as a pure function of inputs and do not accept CLI arguments the way non-flake `nix-build` expressions do.

#### Scenario: Deploy personal profile
- WHEN the user runs `darwin-rebuild switch --flake ".#personal" --impure`
- THEN the configuration includes only personal-only brew casks, system packages, and module configurations (no work-specific entries)

#### Scenario: Deploy work profile
- WHEN the user runs `darwin-rebuild switch --flake ".#work" --impure`
- THEN the configuration includes only work-only brew casks, system packages, and module configurations (no personal-specific entries)

#### Scenario: Bare flake target is no longer valid
- WHEN the user runs `darwin-rebuild switch --flake "." --impure` without specifying `#personal` or `#work`
- THEN the build fails because no darwinConfiguration matches the bare target — an explicit profile-named target is always required

#### Scenario: Shared pkgs accessible independent of profile name
- WHEN a consumer of this flake accesses `self.darwinConfigurations.pkgs`
- THEN the resolved package set (with `unstable`/`zjstatus` overlays applied) is returned, sourced from either profile's build since overlays are identical across `personal` and `work`
- AND no separate `darwinPackages` output exists (removed as part of this change; the `pkgs` attribute lives directly inside `darwinConfigurations` as a sibling of `personal`/`work`)

### Requirement: Shared default layer for all profiles
The system SHALL define a `nix/darwin/profiles/defaults.nix` module that contains all brew casks, system packages, and settings shared between personal and work machines. Per-profile modules merge on top via list-appending (no repetition of shared values).

#### Scenario: Defaults load first for personal
- WHEN deploying the personal profile
- THEN `defaults.nix` loads first, then `personal.nix` appends personal-only entries

#### Scenario: Defaults load first for work
- WHEN deploying the work profile
- THEN `defaults.nix` loads first, then `work.nix` appends work-only entries

### Requirement: Module path resolution with suffix pattern
The system SHALL resolve module file paths using a profile-aware resolver function that applies the following priority: (a) `<module>.<profile>.<ext>` if it exists, (b) fallback to `<module>.<ext>` shared base. Resolution logic lives in `nix/lib/resolve-module.nix`.

#### Scenario: Profile-specific module exists
- WHEN `fish-personal.bindings` exists alongside `fish.nix` for profile=personal
- THEN the resolver returns `fish-personal.bindings` in addition to the always-loaded `fish.nix` base

#### Scenario: No profile-specific module, falls back to shared
- WHEN only `ghostty.nix` exists (no `ghostty.personal.nix`) for any profile
- THEN the resolver returns `ghostty.nix` unchanged

### Requirement: Aerospace config — shared base merged with per-profile diffs
The aerospace configuration SHALL use a directory structure where `main.toml` contains shared workspace rules identical between both machines, and `personal.toml`/`work.toml` contain only the differing sections. The two are combined via `lib.recursiveUpdate` on the parsed TOML attrsets for scalar/attrset keys. For the `on-window-detected` array specifically, `aerospace/default.nix` SHALL concatenate `main.toml`'s array with the profile override's array (`main.on-window-detected ++ (profileOverrides.on-window-detected or [])`) rather than relying on `lib.recursiveUpdate`'s default whole-array-replacement behavior, since `recursiveUpdate` does not merge array elements and a naive merge would silently drop the shared app-routing rules (Ghostty, Xcode, Android Studio, Music, Dia, the floating-window catch-all) whenever a profile defines its own `on-window-detected` entries. This is a narrowly-scoped, documented exception to the "no custom merge logic" rule, limited to this one array-typed key.

#### Scenario: Shared main.toml loads for both profiles
- WHEN deploying either profile
- THEN `aerospace/main.toml` is always parsed as the base attrset

#### Scenario: Per-profile workspace overrides apply on shared base
- WHEN deploying the work profile and `work.toml` contains different workspace names
- THEN `lib.recursiveUpdate main.toml work.toml` produces a merged settings attrset where the work-specific keys override the corresponding keys from `main.toml`

#### Scenario: No profile-specific override file
- WHEN a profile's override TOML file does not exist
- THEN the merge is a no-op and `main.toml`'s settings apply unchanged

#### Scenario: Work profile adds a Focus workspace without losing shared app-routing rules
- WHEN deploying the work profile and `work.toml` defines new `on-window-detected` entries (e.g. routing Teams/Outlook/Microsoft Edge to a new `F` "Focus" workspace)
- THEN the merged `on-window-detected` array contains both `main.toml`'s original entries (Ghostty, Xcode, Android Studio, VSCode, Music, Dia, floating-window catch-all) AND the work-specific new entries — none are dropped

### Requirement: Tuna config — shared base module with near-duplicate full profile configs
The tuna configuration SHALL use a directory structure where `default.nix` contains the shared logic (file symlinks, activation, profile resolution), a shared reference file `config.shared.toml` documents the common baseline, and per-profile full configs (`personal/config.toml`, `work/config.toml`) are each complete, independently maintained files differing primarily in `[[comboMode.bindings]]` app combo sections. These are NOT programmatically merged — the shared file is a human-authoring reference only.

#### Scenario: Shared tuna module resolves profile-specific config
- WHEN deploying the personal profile
- THEN the tuna module sets `home.file."Library/Application Support/Tuna/config.toml".source` to `tuna/personal/config.toml`

#### Scenario: Work-specific tuna combo bindings apply
- WHEN deploying the work profile
- THEN `home.file."Library/Application Support/Tuna/config.toml".source` resolves to `tuna/work/config.toml`, containing corporate app combo bindings distinct from the personal file

### Requirement: Fish shell — shared plugins with per-profile shell additions
The fish module SHALL share all plugins and base `interactiveShellInit` across profiles via the unchanged `fish.nix` file, while loading per-profile bindings files that add machine-specific aliases or corporate proxy settings via `lib.mkMerge` on `shellInit`/`interactiveShellInit`.

#### Scenario: Shared fish module always loads
- WHEN deploying any profile
- THEN `fish.nix` (base, with all shared plugin definitions) loads unconditionally

#### Scenario: Profile-specific shellInit additions load
- WHEN the personal profile is active
- THEN `fish-personal.bindings` appends personal-only aliases to `interactiveShellInit`

#### Scenario: Work-specific shellInit additions load
- WHEN the work profile is active
- THEN `fish-work.bindings` appends corporate proxy/alias settings to `interactiveShellInit`

### Requirement: External secrets directory for work-only sensitive configuration
The system SHALL support an external, non-committed directory at `~/.config/darwin-secrets/` for corporate certificates, proxy settings, and other sensitive work-only values. `profiles/work.nix` SHALL conditionally import `~/.config/darwin-secrets/work.nix` if present, and SHALL emit a soft build-time warning (not a build failure) if that file is absent when the work profile is being deployed. Additionally, any `.crt`/`.pem` files placed in the same directory SHALL be auto-discovered via `builtins.readDir` and fed into `security.pki.certificateFiles` without requiring individual registration in Nix. The personal profile SHALL NOT reference or require this directory.

#### Scenario: Secrets file present
- WHEN deploying the work profile and `~/.config/darwin-secrets/work.nix` exists
- THEN the file is imported as an additional module, and its settings (e.g., proxy/VPN configuration) are applied

#### Scenario: Certificate files auto-discovered
- WHEN deploying the work profile and one or more `.crt`/`.pem` files exist in `~/.config/darwin-secrets/`
- THEN each discovered file's path is added to `security.pki.certificateFiles` automatically, without needing to list the file path anywhere in the repo's Nix code

#### Scenario: Secrets file absent
- WHEN deploying the work profile and `~/.config/darwin-secrets/work.nix` does not exist
- THEN the build succeeds but emits a `warnings` entry stating the secrets file is missing and corporate settings will be absent

#### Scenario: Personal profile never checks for secrets
- WHEN deploying the personal profile
- THEN no check for `~/.config/darwin-secrets/work.nix` occurs and no related warning is possible

### Requirement: init.sh convenience helpers
The system SHALL provide `deploy_personal` and `deploy_work` functions in `init.sh` that invoke `darwin-rebuild switch` targeting the corresponding named flake output. The obsolete `run_hostname_sed` bootstrap step SHALL be removed, since darwinConfigurations are no longer keyed by hostname.

#### Scenario: deploy_personal targets the personal flake output
- WHEN the user runs `./init.sh --personal` or calls `deploy_personal`
- THEN `darwin-rebuild switch --flake ".#personal" --impure` is executed

#### Scenario: deploy_work targets the work flake output
- WHEN the user runs `./init.sh --work` or calls `deploy_work`
- THEN `darwin-rebuild switch --flake ".#work" --impure` is executed

#### Scenario: run_hostname_sed no longer exists
- WHEN inspecting `init.sh` after this change
- THEN no function performs hostname-based substitution of the darwinConfiguration key
