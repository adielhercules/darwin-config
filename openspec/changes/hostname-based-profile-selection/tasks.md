## 1. Nix flake / darwin config changes

- [x] 1.1 Add `hostProfiles` hostname → profile mapping in `nix/darwin/default.nix` (keyed by `scutil --get LocalHostName`: `"Adiels-MacBook-Pro" = "personal";`, `"MPCE-MBP-RWF4347WJP" = "work";`)
- [x] 1.2 Replace the final `{ personal = mkDarwinConfig "personal"; work = mkDarwinConfig "work"; }` expression with `nixpkgs.lib.mapAttrs (_hostname: profile: mkDarwinConfig profile) hostProfiles`, keeping `mkDarwinConfig`'s existing profile assertion intact
- [x] 1.3 Update `nix/flake.nix`: change `configs.pkgs = configs.personal.pkgs;` to reference the new hostname-keyed attribute (`configs."Adiels-MacBook-Pro".pkgs`)
- [x] 1.4 Update the comment block in `nix/flake.nix` describing profile selection to reflect hostname-based auto-resolution (removed the "no hostname-based auto-resolution" language, documented `darwin-rebuild switch --flake .` behavior and the explicit `--flake ".#<hostname>"` override)

## 2. init.sh changes

- [x] 2.1 Remove `set_profile()`, `deploy_personal()`, `deploy_work()` functions from `init.sh`
- [x] 2.2 Remove `--personal`/`--work` CLI flag handling/dispatch from `init.sh`
- [x] 2.3 Make `--deploy` a functional flag that invokes `just deploy` (removed the always-fail stub and its guidance message)
- [x] 2.4 Update `--all` flag's post-bootstrap guidance text to point to `init.sh --deploy` / `just deploy` instead of `--personal`/`--work`
- [x] 2.5 Update `init.sh`'s usage/help text to remove `--personal`/`--work` and reflect the new `--deploy` behavior

## 3. Justfile changes

- [x] 3.1 Set `flake_target := "./nix"` (remove per-profile suffix) as the fixed, no-longer-mutated default
- [x] 3.2 Verify no other Justfile recipe references profile-specific flake targets
- [x] 3.3 (discovered during implementation) Neutralize `.githooks/pre-commit`'s now-obsolete `flake_target := "<not_initialized>"` placeholder guard, since `flake_target` is now a fixed, always-committed value with no local sed-mutation to protect against

## 4. Validation

- [x] 4.1 Run `just check` (dry-run) and confirm it resolves the current machine's hostname to the expected profile (personal profile confirmed via Homebrew casks installed during dry-run activation)
- [x] 4.2 Run `nix flake check ./nix` to confirm flake integrity with the renamed `darwinConfigurations` attributes
- [x] 4.3 Run `nix fmt --check` (or `nix fmt`) to validate formatting of changed Nix files
- [x] 4.4 Confirmed `MPCE-MBP-RWF4347WJP` as the work machine's exact `scutil --get LocalHostName` value with the user; `hostProfiles` updated accordingly. Full `darwin-rebuild switch --flake ".#MPCE-MBP-RWF4347WJP" --dry-run` verification deferred until run on the actual work machine, but the mapping and flake attribute now match the confirmed hostname.
- [x] 4.5 Confirm `git status` is clean and all changes are intentional before handing off for user-approved commit (verified: only the expected files listed above are modified/added)
