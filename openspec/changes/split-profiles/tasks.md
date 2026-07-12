## 1. Create the profile-aware module resolver

- [ ] 1.1 Create `nix/lib/resolve-module.nix` with profile-aware file path resolution (suffix pattern fallback: `<module>.<profile>.<ext>` → fallback `<module>.<ext>`)
- [ ] 1.2 Write a small `nix-instantiate --eval` or `nix eval` smoke test confirming: (a) resolver returns the profile-specific file when it exists, (b) resolver falls back to the shared file when no profile variant exists

## 2. Create profiles directory with shared + per-profile layers

- [ ] 2.1 Create `nix/darwin/profiles/defaults.nix` — move shared brew casks, system packages, and settings from `default.nix` here
- [ ] 2.2 Create `nix/darwin/profiles/personal.nix` — personal-only additions (no repetition of defaults)
- [ ] 2.3 Create `nix/darwin/profiles/work.nix` — work-only additions (corporate tools), plus conditional import of `~/.config/darwin-secrets/work.nix` with a `warnings` fallback if absent, and auto-discovery of any `.crt`/`.pem` files in that same directory fed into `security.pki.certificateFiles`
- [ ] 2.4 Create `nix/darwin/profiles/work.nix.example` — documented template showing the expected attrset shape for the external secrets file (no real values), committed to the repo, with a header comment explaining the `~/.config/darwin-secrets/` directory convention (drop `work.nix` + any `.crt`/`.pem` files there for automatic discovery)

## 3. Convert flake.nix and default.nix to named, profile-keyed outputs

- [ ] 3.1 Replace the single `darwinConfigurations."Adiels-MacBook-Pro"` in `nix/flake.nix` with two named outputs: `darwinConfigurations.personal` and `darwinConfigurations.work`
- [ ] 3.2 Ensure both outputs share the same base module list, differing only in which `profiles/*.nix` file is imported
- [ ] 3.3 Update `nix/darwin/default.nix` to accept a `profile` parameter (passed internally, not from CLI) and import `profiles/defaults.nix` plus the matching `profiles/{personal,work}.nix`
- [ ] 3.4 Thread the `profile` value through `specialArgs`/`extraSpecialArgs` so home-manager modules (aerospace, tuna, fish) can access it

## 4. Restructure aerospace config into directory with shared + merged per-profile diffs

- [ ] 4.1 Create `nix/modules/home/aerospace/` directory
- [ ] 4.2 Move existing aerospace settings to `aerospace/main.toml` as the shared base
- [ ] 4.3 Create `aerospace/personal.toml` for personal workspace name diffs (only the differing keys, may be empty/omitted if no diff exists)
- [ ] 4.4 Create `aerospace/work.toml` for work workspace name diffs (only the differing keys)
- [ ] 4.5 Rewrite `nix/modules/home/aerospace.nix` as `aerospace/default.nix`, parsing `main.toml` and the profile-specific override, merging via `lib.recursiveUpdate`
- [ ] 4.6 Verify aerospace config renders correctly for both profiles via `nix eval` or `--dry-build`

## 5. Restructure tuna config into directory with shared reference + full per-profile configs

- [ ] 5.1 Create `nix/modules/home/tuna/` directory structure
- [ ] 5.2 Copy the current `tuna/config.toml` to `tuna/config.shared.toml` as a documented human-authoring reference (not programmatically merged)
- [ ] 5.3 Create `tuna/personal/config.toml` — full tuna config with personal app combo shortcuts
- [ ] 5.4 Create `tuna/work/config.toml` — full tuna config with corporate app combos
- [ ] 5.5 Rewrite `nix/modules/home/tuna.nix` as `tuna/default.nix`, resolving `home.file` source to the active profile's config file

## 6. Split fish into shared base + per-profile bindings

- [ ] 6.1 Keep `nix/modules/home/fish.nix` as the shared base (plugins, interactiveShellInit skeleton) — no rename
- [ ] 6.2 Extract personal shell aliases/hooks into `nix/modules/home/fish-personal.bindings`
- [ ] 6.3 Extract work proxy/corporate settings into `nix/modules/home/fish-work.bindings`
- [ ] 6.4 Update the fish import in `home.nix` to load `fish.nix` unconditionally plus the resolved per-profile bindings file, merged via `lib.mkMerge` on `shellInit`

## 7. Wire the resolver into home.nix

- [ ] 7.1 Import `nix/lib/resolve-module.nix` in `nix/darwin/home.nix`
- [ ] 7.2 Replace the hardcoded `../modules/home/aerospace.nix` import with a resolver call pointing at the `aerospace/` directory
- [ ] 7.3 Replace the hardcoded tuna module import with a resolver call pointing at the `tuna/` directory
- [ ] 7.4 Replace the `fish.nix` import with the resolver call described in task 6.4
- [ ] 7.5 Confirm ghostty, helix, neovim, zellij, and oh_my_posh imports remain unconditional and untouched

## 8. Update init.sh

- [ ] 8.1 Remove the `run_hostname_sed` function entirely (obsolete — darwinConfigurations are no longer hostname-keyed)
- [ ] 8.2 Add `deploy_personal` function → `darwin-rebuild switch --flake ".#personal" --impure`
- [ ] 8.3 Add `deploy_work` function → `darwin-rebuild switch --flake ".#work" --impure`
- [ ] 8.4 Update the CLI dispatch section (`--paths`, `--bootstrap`, etc.) to remove any reference to the removed hostname step and document the new `--personal`/`--work` flags

## 9. Verify both profiles build and deploy correctly

- [ ] 9.1 Run `darwin-rebuild switch --flake ".#personal" --dry-build` — confirm it succeeds
- [ ] 9.2 Verify personal-only brew casks/packages are present in the dry-build output, and work-only entries are absent
- [ ] 9.3 Run `darwin-rebuild switch --flake ".#work" --dry-build` — confirm it succeeds (this can be tested from the personal machine, since profile selection is explicit)
- [ ] 9.4 Verify work-only brew casks/packages are present, and personal-only entries are absent
- [ ] 9.5 Temporarily rename `~/.config/darwin-secrets/work.nix` (if present) and re-run the work dry-build to confirm the missing-secrets warning appears without failing the build
- [ ] 9.6 Confirm `darwin-rebuild switch --flake "." --impure` (bare, no profile target) now fails as expected, validating that hostname-based auto-resolution has been fully removed
