## 1. Remove Neovim

- [x] 1.1 Delete `dotfiles/nvim.astro-v5/` directory
- [x] 1.2 Delete `nix/modules/home/neovim.nix`
- [x] 1.3 Remove neovim import from `nix/darwin/home.nix` (line 45: `../modules/home/neovim.nix`)
- [x] 1.4 Remove `neovim` from `environment.systemPackages` in `nix/darwin/profiles/defaults.nix` (line 16)
- [x] 1.5 Remove duplicate nix tooling packages from `nix/darwin/home.nix` (lines 74-79: `# TODO:More nvim` block)

## 2. Rename dotfiles/ → config/

- [x] 2.1 Run `git mv dotfiles config` to rename the directory
- [x] 2.2 Update `nix/darwin/default.nix` line 28: `files = "${rootPath}/dotfiles"` → `files = "${rootPath}/config"`

## 3. Move Oh My Posh config to config/fish/

- [x] 3.1 Create `config/fish/` directory
- [x] 3.2 Move `config/simple.omp.json` → `config/fish/simple.omp.json`
- [x] 3.3 Update `nix/modules/home/oh_my_posh.nix` line 6: `"${files}/simple.omp.json"` → `"${files}/fish/simple.omp.json"`

## 4. Move Stylix color scheme to config/stylix/

- [x] 4.1 Create `config/stylix/` directory
- [x] 4.2 Move `config/lcars.yaml` → `config/stylix/lcars.yaml`
- [x] 4.3 Update `nix/darwin/default.nix` line 133: `"${files}/lcars.yaml"` → `"${files}/stylix/lcars.yaml"`

## 5. Move OpenCode config to config/opencode/

- [x] 5.1 Create `config/opencode/plugins/` and `config/opencode/agents/` directories
- [x] 5.2 Move `nix/modules/home/opencode/plugins/*` → `config/opencode/plugins/`
- [x] 5.3 Move `nix/modules/home/opencode/agents/*` → `config/opencode/agents/`
- [x] 5.4 Delete empty `nix/modules/home/opencode/plugins/` and `nix/modules/home/opencode/agents/` directories
- [x] 5.5 Update `nix/modules/home/opencode.nix`: add `files` to function args, change `opencodeSource = ./opencode;` → `opencodeSource = "${files}/opencode";`

## 6. Move Helix yazi-picker.sh to config/helix/

- [x] 6.1 Create `config/helix/` directory
- [x] 6.2 Move `nix/modules/home/helix/yazi-picker.sh` → `config/helix/yazi-picker.sh`
- [x] 6.3 Delete empty `nix/modules/home/helix/` directory
- [x] 6.4 Update `nix/modules/home/helix.scripts-manager.nix`: add `files` to function args, change `source = ./helix/yazi-picker.sh;` → `source = "${files}/helix/yazi-picker.sh";`

## 7. Move Fish zz.fish to config/fish/

- [x] 7.1 Move `nix/modules/home/fish/zz.fish` → `config/fish/zz.fish`
- [x] 7.2 Delete empty `nix/modules/home/fish/` directory
- [x] 7.3 Update `nix/modules/home/fish.nix`: add `files` to function args, change `./fish/zz.fish` → `"${files}/fish/zz.fish"`

## 8. Validation

- [x] 8.1 Run `just check` to validate the configuration compiles
- [x] 8.2 Run `nix fmt -- --fail-on-change` to validate formatting
- [x] 8.3 Verify `config/` directory structure matches the design
