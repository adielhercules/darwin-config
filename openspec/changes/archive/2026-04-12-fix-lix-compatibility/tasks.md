# Tasks: fix-lix-compatibility

## Fix mutable paths lock entry

- [x] Remove `paths.url = "path:./paths"` input from `nix/flake.nix`
- [x] Define `paths = { rootPath = "/Users/adielhercules/darwin-config"; }` as inline let-binding in `flake.nix` outputs
- [x] Remove `paths` node from `nix/flake.lock`
- [x] Restore `nixpkgs-unstable` and `stylix` entries in root node of `flake.lock` (accidentally removed during edit)

## Fix darwin-rebuild missing from fish PATH after reboot

- [x] Add `fish_add_path /run/current-system/sw/bin` to `shellInit` in `nix/modules/home/fish.nix`
- [x] Add `fish_add_path /run/current-system/sw/bin` to `shellInit` in `nix/home/fish.nix`

## Fix nix subcommands in Justfile for Lix

- [x] Add `nix_flags := "--extra-experimental-features 'nix-command flakes'"` variable to Justfile
- [x] Update `optimise` recipe
- [x] Update `up` recipe
- [x] Update `up-unstable-to` recipe
- [x] Update `up-secrets` recipe
- [x] Update `update-brew` recipe (4 commands)
- [x] Update `repl` recipe
- [x] Update `gc` recipe (2 commands, one sudo)
- [x] Update `clean` recipe

## Validation

- [x] `just deploy` succeeded
- [x] `just optimise` succeeded
