## 1. Flake & Dependency Fixes

- [x] 1.1 Replace hardcoded `rootPath` with `self` in `nix/flake.nix` (line 70): change `rootPath = "/Users/adielhercules/darwin-config"` to `rootPath = self`
- [x] 1.2 Add `inputs.nixpkgs.follows = "nixpkgs"` to the `nix-homebrew` input in `nix/flake.nix` (line 30)
- [x] 1.3 Fix path concatenation in `nix/darwin/default.nix`: change `files = "${rootPath}/config"` to `files = rootPath + "/config"`, `nixPath = "${rootPath}/nix"` to `nixPath = rootPath + "/nix"`, and `libFiles = "${rootPath}/lib"` to `libFiles = rootPath + "/lib"`
- [x] 1.4 Remove dead `x86_64-linux` formatter entry from `nix/flake.nix` (lines 108-111): remove the `x86_64-linux` attribute from the `formatter` block

## 2. Identity & Secrets (depends on 1.1)

- [x] 2.1 ~~Update `nix/lib/git-email.nix` to read from `~/.local/git-email`~~ **Replaced by 2.1a–2.1d below** (git email now managed imperatively)
- [x] 2.1a Rewrite `init.sh` `run_set_email()`: write `~/.config/git/config.local` in git config format (`[user]\n\temail = ...`) instead of `~/.local/git-email`
- [x] 2.1b Rewrite `init.sh` `require_email()`: check `~/.config/git/config.local` exists and is non-empty
- [x] 2.1c Update `init.sh` help text: document `--email` writes to `~/.config/git/config.local`
- [x] 2.1d Update `init.sh` variable: change `EMAIL_FILE` to `GIT_LOCAL` pointing to `$HOME/.config/git/config.local`
- [x] 2.2 ~~Update `init.sh` line 15~~ Done as part of 2.1a
- [x] 2.3 Update `nix/modules/home/git-personal.nix` and `nix/modules/home/git-work.nix`: remove `user.email`, remove `lib` arg, remove `git-email.nix` import; keep only `user.name`
- [x] 2.3a Delete `nix/lib/git-email.nix` (no longer needed)
- [x] 2.3b Add `programs.git.includes = [ "~/.config/git/config.local" ];` to `nix/darwin/home.nix` git block
- [x] 2.4 ~~Replace hardcoded `uid = 501`~~ Use `builtins.getEnv "SUDO_UID"` for dynamic UID detection (`builtins.exec` is unavailable in Lix); abort with clear message if `SUDO_UID` not set

## 3. Module Code Quality

- [x] 3.1 Remove `lib.mkForce` from helix settings in `nix/modules/home/helix.nix` (line 8): change `settings = lib.mkForce {` to `settings = {`
- [x] 3.2 Remove duplicate `fd` from `home.packages` in `nix/darwin/home.nix` (remove the second occurrence in the "# For rust" section)
- [x] 3.3 Remove duplicate `unstable.devenv` from `home.packages` in `nix/darwin/home.nix` (already in `nix/darwin/profiles/defaults.nix` systemPackages)
- [x] 3.4 Extract zellij plugin/zjstatus inline config block (~110 lines) from `nix/modules/home/zellij.nix` into a separate file `nix/modules/home/zellij/zjstatus.nix` that returns the interpolated string; import and reference it in `zellij.nix`
- [x] 3.5 Remove commented-out code from `nix/modules/home/helix.nix` (commented C-e keybind block)
- [x] 3.6 Add comment to `nix/modules/home/fish.nix` explaining why `fish-colored-man` uses `fetchFromGitHub` instead of nixpkgs fishPlugin (package may not be available in nixpkgs 26.05-darwin)

## 4. Cleanup

- [x] 4.1 Rename `nix/modules/home/oh_my_posh.nix` to `nix/modules/home/oh-my-posh.nix` via `git mv`; update the import path in `nix/darwin/home.nix`
- [x] 4.2 Remove commented-out code from `nix/modules/home/ghostty.nix` (commented macos-option-as-alt and keybind)
- [x] 4.3 Remove commented-out code from `nix/darwin/home.nix` (commented packages and sessionVariables)
- [x] 4.4 Improve `home.stateVersion` comment in `nix/darwin/home.nix`: replace `# Please read the comment before changing.` with an explanation linking to the home-manager state-version documentation
- [x] 4.5 Remove obsolete `run_paths_sed` function from `init.sh` (no longer needed since rootPath = self); update `run_all` and CLI dispatch

## 5. Guardrails

- [x] 5.1 Add "Post-Apply Validation" section to `AGENTS.md` after the existing "Validation Commands" section, documenting the 5-step mandatory validation sequence (git add, nix flake check, nix fmt, deadnix, statix)
- [x] 5.2 Add `post-apply` rules to `openspec/config.yaml` requiring the validation sequence after every change implementation
- [x] 5.3 Update the "Validation Commands" section in `AGENTS.md` to include `deadnix` and `statix` commands

## 6. Additional Fixes (found during validation)

- [x] 6.1 Remove unused `pkgs` from `nix/modules/home/opencode.nix` function args (deadnix finding)
- [x] 6.2 Merge repeated `xdg.configFile` assignments into single attrset in `nix/modules/home/opencode.nix` (statix finding)
- [x] 6.3 Remove unused `lib` from `nix/modules/home/helix.nix` function args (caused by 3.1 removing `lib.mkForce`)
- [x] 6.4 Remove unnecessary parentheses in `nix/modules/home/zellij/zjstatus.nix` (statix finding)
- [x] 6.5 Replace empty `{ ... }:` with `_:` in `git-personal.nix` and `git-work.nix` (statix finding after removing args)
- [x] 6.6 Fix `files` path in `default.nix`: change `rootPath + "/config"` to `rootPath + "/../config"` (`self` = `nix/`, not repo root)
- [x] 6.7 Fix `oh-my-posh.nix` import path in `home.nix`: change `./modules/home/` to `../modules/home/` (relative to `nix/darwin/`)
- [x] 6.8 Fix `programs.git.includes` format: use `{ path = "..."; }` attrset instead of bare string
- [x] 6.9 Add `lib.mkDefault` to helix theme to resolve conflict with stylix's `"stylix"` theme

## 7. Validation

- [x] 7.1 Stage all changes: `git add nix/ init.sh AGENTS.md openspec/`
- [x] 7.2 Run `nix flake check --no-build ./nix` — expect pass
- [x] 7.3 Run `nix fmt` — apply any formatting fixes, then re-stage
- [x] 7.4 Run `deadnix --fail .` — expect no dead code
- [x] 7.5 Run `statix check .` — expect no warnings
- [ ] 7.6 Run `just check` (on user request, requires sudo) — expect darwin-rebuild check pass
- [x] 7.7 Verify git status is clean and show diff to user
