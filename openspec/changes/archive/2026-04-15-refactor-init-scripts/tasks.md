## 1. Modify nix/flake.nix

- [x] 1.1 Replace hardcoded `rootPath = "/Users/adielhercules/darwin-config"` with `rootPath = "<init-required>"` in `nix/flake.nix`

## 2. Create init.sh

- [x] 2.1 Create `init.sh` at repo root with Part 1: sed replacement of `<init-required>` in `nix/flake.nix` using `$SCRIPT_DIR`
- [x] 2.2 Add `git config core.hooksPath .githooks` to Part 1 of `init.sh`
- [x] 2.3 Add Part 2 to `init.sh`: bootstrap deploy via `nix run nix-darwin/master#darwin-rebuild` with `nix-command` and `flakes` experimental features
- [x] 2.4 Add Part 3 to `init.sh`: standard deploy via `sudo darwin-rebuild switch --flake ".#mymbp" --impure`
- [x] 2.5 `chmod +x init.sh`

## 3. Create pre-commit hook

- [x] 3.1 Create `.githooks/` directory at repo root
- [x] 3.2 Create `.githooks/pre-commit` that checks staged `nix/flake.nix` for `<init-required>` using `git show :nix/flake.nix`
- [x] 3.3 `chmod +x .githooks/pre-commit`

## 4. Delete dead files

- [x] 4.1 Delete `initialize_paths.sh`
- [x] 4.2 Delete `initial-deploy.sh`
- [x] 4.3 Delete `deploy.sh`
- [x] 4.4 Delete `nix/paths/flake.nix`
- [x] 4.5 Delete `paths/flake.nix`

## 5. Activate hook on current machine

- [x] 5.1 Run `git config core.hooksPath .githooks` locally (existing machine — do NOT re-run `init.sh` as it would overwrite the real rootPath with placeholder)
