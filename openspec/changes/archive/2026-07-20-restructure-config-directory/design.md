## Context

The `dotfiles/` directory currently holds static configuration files (YAML, JSON, shell scripts) referenced by Nix modules via the `files` specialArg. The flat structure and misleading name provide no organizational signal. Meanwhile, several pure config files (OpenCode plugins/agents, Helix scripts, Fish functions) live inside `nix/modules/home/` alongside the Nix modules that deploy them, creating an inconsistent pattern.

Additionally, the Neovim configuration (`nvim.astro-v5/`) and its associated Nix module (`neovim.nix`) are no longer needed.

## Goals / Non-Goals

**Goals:**
- Rename `dotfiles/` → `config/` to accurately reflect its purpose.
- Organize static config files into tool-specific subdirectories under `config/`.
- Remove Neovim configuration cleanly (module, packages, symlinks).
- Establish a clear convention: pure config files live in `config/`, Nix modules live in `nix/`.

**Non-Goals:**
- Refactoring how the `files` specialArg is threaded through modules.
- Moving config files that have Nix interpolation dependencies (Zellij `config.kdl`, Tuna TOML, Aerospace TOML, Fish `.bindings`).
- Changing the deployment behavior of any tool (everything still lands in the same `~/.config/` paths).

## Decisions

### Decision 1: `config/` naming convention for subdirectories

**Choice**: Tool-name directories (`config/fish/`, `config/helix/`, `config/opencode/`, `config/stylix/`).

**Alternatives considered**:
- `config/themes/`, `config/prompts/`, etc. (category-based) — rejected because it fragments related files across abstract categories.
- Flat `config/` with prefixed filenames — rejected because it doesn't scale.

**Rationale**: Mirrors how Nix modules are already organized (`nix/modules/home/helix/`, `nix/modules/home/zellij/`). Each subdirectory maps 1:1 to a tool, making discovery intuitive.

### Decision 2: Use `files` specialArg for all moved files

**Choice**: Modules that currently use relative paths (`./opencode`, `./helix/yazi-picker.sh`, `./fish/zz.fish`) will accept `files` as a function argument and use `"${files}/<tool>/<file>"` paths.

**Alternatives considered**:
- Keep relative paths and move files adjacent to modules — rejected because it defeats the purpose of separating config from Nix code.
- Create per-module path variables — rejected as unnecessary indirection.

**Rationale**: The `files` variable is already available to all home-manager modules via `extraSpecialArgs`. Using it consistently for all static config files creates a single, predictable pattern.

### Decision 3: Neovim removal is complete but conservative

**Choice**: Remove `neovim.nix`, the `nvim.astro-v5/` directory, neovim from system packages, and duplicate nix tooling packages. Leave `defaults.nix` packages that are used by other tools (`nodejs_22`, `lua5_1`, `bun`).

**Alternatives considered**:
- Remove only the Nix module, keep the dotfiles — rejected because the user explicitly wants nvim gone.
- Remove all nix tooling packages — rejected because `nixd`, `nixfmt`, `deadnix`, `statix` are useful independent of nvim.

**Rationale**: Clean removal with no residual references. The duplicate nix tools in `home.nix` (lines 74-79) were explicitly tagged `# TODO:More nvim` and should be cleaned up.

## Risks / Trade-offs

- **[Risk]** Moving OpenCode files changes the source path, which could break if any hardcoded path exists elsewhere. → **Mitigation**: The `opencodeSource` variable in `opencode.nix` is the single source of truth; updating it propagates to all `xdg.configFile` entries.
- **[Risk]** The `helix/` and `fish/` directories under `nix/modules/home/` become empty after moves and should be deleted to avoid confusion. → **Mitigation**: Explicit deletion step in tasks.
- **[Trade-off]** Modules now depend on the `files` specialArg instead of relative paths. If `files` is ever removed from `extraSpecialArgs`, multiple modules break simultaneously. → **Acceptable**: `files` is a core part of the architecture (defined in `default.nix` and threaded through `mkSpecialArgs`); removing it would break the entire config.
