## Why

The `dotfiles/` directory currently serves as a flat holding area for static configuration files referenced by Nix modules via the `files` specialArg. The name "dotfiles" is misleading (these aren't shell dotfiles), and the flat structure provides no organizational signal. Additionally, the Neovim configuration (`nvim.astro-v5/`) is no longer needed and should be removed.

## What Changes

- **BREAKING**: Rename `dotfiles/` → `config/` to better reflect its purpose as a container for static configuration consumed by Nix modules.
- Move `simple.omp.json` into `config/fish/` (Oh My Posh is a fish shell prompt tool).
- Move `lcars.yaml` into `config/stylix/` (the file is exclusively consumed by Stylix for system-wide theming).
- Move static OpenCode config files (plugins `.ts`, agents `.md`) from `nix/modules/home/opencode/` into `config/opencode/` — these are pure config with no Nix dependencies.
- Move `helix/yazi-picker.sh` from `nix/modules/home/helix/` into `config/helix/` — pure shell script.
- Move `fish/zz.fish` from `nix/modules/home/fish/` into `config/fish/` — pure fish function.
- **Remove** `dotfiles/nvim.astro-v5/` and `nix/modules/home/neovim.nix` entirely (Neovim no longer needed).
- Remove `neovim` from system packages in `defaults.nix` and clean up duplicate nix tooling packages in `home.nix`.

## Capabilities

### New Capabilities

- `config-directory-structure`: Establishes the `config/` directory as the canonical location for static configuration files consumed by Nix modules, with subdirectories organized by tool/purpose.

### Modified Capabilities

- `nix-repo-hygiene`: The "No orphaned or dead configuration artifacts" requirement is directly relevant — removing `neovim.nix` and cleaning up dead references aligns with this spec. No requirement changes needed, just implementation alignment.
- `opencode-source-plugins`: The source path for OpenCode plugins/agents changes from `nix/modules/home/opencode/` to `config/opencode/`. The deployment behavior (copying to `~/.config/opencode/`) remains identical.

## Impact

- **Files renamed/moved**: `dotfiles/` → `config/`, 6 static config files relocated into tool-specific subdirectories.
- **Files deleted**: `nix/modules/home/neovim.nix`, `dotfiles/nvim.astro-v5/` (entire directory), `nix/modules/home/opencode/plugins/`, `nix/modules/home/opencode/agents/`, `nix/modules/home/helix/`, `nix/modules/home/fish/` (all empty after moves).
- **Nix modules edited**: `nix/darwin/default.nix` (path update), `nix/darwin/home.nix` (remove neovim import + duplicate packages), `nix/darwin/profiles/defaults.nix` (remove neovim from systemPackages), `nix/modules/home/oh_my_posh.nix` (path update), `nix/modules/home/opencode.nix` (add `files` arg, update source path), `nix/modules/home/helix.scripts-manager.nix` (add `files` arg, update source path), `nix/modules/home/fish.nix` (add `files` arg, update source path).
- **No breaking changes for users**: The `files` specialArg propagates automatically; all module-level path changes are internal.
- **Validation**: `just check` must pass after all changes.
