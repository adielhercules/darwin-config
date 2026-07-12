## 1. Resolve module resolver helper

- [ ] 1.1 Create nix/lib/resolve-module.nix with profile-aware file path resolution (suffix pattern fallback)
- [ ] 1.2 Verify resolver returns correct paths for: existing profile variant, missing profile variant (fallback), and multi-file directory modules

## 2. Create profiles directory with shared + per-profile layers

- [ ] 2.1 Create nix/darwin/profiles/defaults.nix — move shared brew casks, system packages, and settings from default.nix here
- [ ] 2.2 Create nix/darwin/profiles/personal.nix — personal-only additions (no repetition of defaults)
- [ ] 2.3 Create nix/darwin/profiles/work.nix — work-only additions (corporate tools, certs)

## 3. Update flake and default.nix for profile parameter

- [ ] 3.1 Add `profile` argument to nix/flake.nix outputs function signature
- [ ] 3.2 Forward profile parameter through specialArgs to darwinSystem modules
- [ ] 3.3 Update nix/darwin/default.nix to accept profile parameter
- [ ] 3.4 Import profiles/defaults.nix, then personal.nix or work.nix (based on profile) in default.nix module list

## 4. Restructure aerospace config into directory with shared + per-profile diffs

- [ ] 4.1 Create nix/modules/home/aerospace/ directory
- [ ] 4.2 Move existing aerospace settings to aerospace/main.toml as the shared base
- [ ] 4.3 Create aerospace/personal.toml for personal workspace name diffs (or leave empty/identical to main)
- [ ] 4.4 Create aerospace/work.toml for work workspace name diffs
- [ ] 4.5 Rewrite nix/modules/home/aerospace.nix as directory-based module that resolves active config via resolver
- [ ] 4.6 Verify aerospace config renders correctly for both profiles (nix build check)

## 5. Restructure tuna config into directory with shared module + per-profile full configs

- [ ] 5.1 Create nix/modules/home/tuna/ directory structure
- [ ] 5.2 Identify and extract the ~80% shared base from current tuna/config.toml → tuna/config.shared.toml
- [ ] 5.3 Create tuna/personal/config.toml — full tuna config with personal app combo shortcuts (~50 lines diff)
- [ ] 5.4 Create tuna/work/config.toml — full tuna config with corporate app combos
- [ ] 5.5 Rewrite nix/modules/home/tuna.nix as module that resolves profile-specific config file and symlinks it

## 6. Split fish into shared base + per-profile bindings

- [ ] 6.1 Rename current fish plugin definitions from fish.nix to fish.config (base)
- [ ] 6.2 Extract personal shell aliases/hooks into nix/modules/home/fish-personal.bindings
- [ ] 6.3 Extract work proxy/corporate settings into nix/modules/home/fish-work.bindings
- [ ] 6.4 Update fish module to load base config + resolve per-profile bindings file

## 7. Update home.nix to use the resolver for all imports

- [ ] 7.1 Import resolve-module.nix helper in nix/darwin/home.nix
- [ ] 7.2 Replace hardcoded aerespace/nix/modules/home/aerospace.nix import with resolver call
- [ ] 7.3 Replace hardcodetuna module import with resolver call
- [ ] 7.4 Replace the fish.nix import with resolver call
- [ ] 7.5 Verify no hardcoded module paths remain that should use the resolver

## 8. Update init.sh — add deploy helpers, remove hostname detection

- [ ] 8.1 Add deploy_personal function → darwin-rebuild switch --flake ".#" --argstr profile personal --impure
- [ ] 8.2 Add deploy_work function → darwin-rebuild switch --flake ".#" --argstr profile work --impure
- [ ] 8.3 Remove any existing hostname detection logic from init.sh

## 9. Verify deployments for both profiles

- [ ] 9.1 Run darwin-rebuild switch --flake ".#" --argstr profile personal --dry-build — check it succeeds
- [ ] 9.2 Verify personal.nix is loaded (personal brew casks + packages present)
- [ ] 9.3 Run darwin-rebuild switch --flake ".#" --argstr profile work --dry-build — check it succeeds
- [ ] 9.4 Verify work.nix is loaded (work-only brew casks + packages present)
- [ ] 9.5 Confirm default profile still works (no profile arg → personal)
