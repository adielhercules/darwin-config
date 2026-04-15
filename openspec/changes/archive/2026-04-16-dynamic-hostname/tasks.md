## 1. Nix Config Placeholders

- [x] 1.1 Replace `"mymbp"` with `"<hostname>"` in `nix/darwin/default.nix` (the attribute set key on line 19)
- [x] 1.2 Replace `"mymbp"` with `"<hostname>"` in `nix/flake.nix` (the `darwinPackages` reference on line 62)

## 2. init.sh — Hostname Substitution

- [x] 2.1 Add `run_hostname_sed` function to `init.sh` that reads hostname via `scutil --get LocalHostName` and runs `sed -i ''` to replace `<hostname>` in both `nix/darwin/default.nix` and `nix/flake.nix`
- [x] 2.2 Call `run_hostname_sed` from `run_paths` (alongside the existing `run_paths_sed` call)

## 3. init.sh — Dynamic Deploy Target

- [x] 3.1 Update `run_deploy` in `init.sh` to replace the hardcoded `.#mymbp` with `.#$(scutil --get LocalHostName)` so the deploy target is always the current machine's hostname

## 4. Git Hook — Hostname Placeholder Guard

- [x] 4.1 Extend `.githooks/pre-commit` to check `nix/darwin/default.nix`: if staged, its content must contain `<hostname>` — reject with an error if not
- [x] 4.2 Extend `.githooks/pre-commit` to check `nix/flake.nix` for the `<hostname>` placeholder (in addition to the existing `<init-required>` check)

## 5. Verification

- [x] 5.1 Run `init.sh --paths` on the local machine and confirm both nix files have the real hostname substituted
- [x] 5.2 Run `init.sh --deploy` (or `--all`) and confirm `darwin-rebuild` targets the correct flake attribute
- [x] 5.3 Stage a nix file with a resolved hostname and confirm the pre-commit hook rejects the commit
- [x] 5.4 Stage nix files with `<hostname>` placeholder and confirm the hook allows the commit
