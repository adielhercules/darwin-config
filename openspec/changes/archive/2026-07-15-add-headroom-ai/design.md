## Context

The nix-darwin config manages a macOS development environment. Tools not in nixpkgs are handled via Homebrew (`homebrew.brews`) or, for Python-based CLIs, via `uv tool install` in Home Manager activation scripts (established pattern: `rtk.nix`). Headroom is a Python+Rust CLI tool not yet in nixpkgs. `uv` is not currently in the config and must be added.

## Goals / Non-Goals

**Goals:**
- `headroom` CLI globally available after `darwin-rebuild switch`
- `uv` available at user-level (reusable for future Python tools)
- Installation is idempotent — safe to run on every rebuild
- Follows existing module pattern established by `rtk.nix`

**Non-Goals:**
- Packaging headroom natively in Nix (complex Python+Rust/maturin build)
- System-wide `uv` installation via `environment.systemPackages`
- Pinning headroom to a specific version (latest on initial install)
- Configuring headroom (proxy, MCP, memory settings) — that's a separate concern

## Decisions

### Decision 1: `uv tool install` over `pip install --user`
`uv` is significantly faster than pip and isolates tools in their own virtual environments, avoiding dependency conflicts. `uv tool install` places the binary on `$PATH` via `~/.local/bin`. This matches the project's preference for modern tooling (`bun`, `rustup`, etc.).

**Alternatives considered:**
- `pip install --user`: Slower, no isolation, no lock files
- `pkgs.python3Packages.buildPythonPackage`: Requires packaging Rust extensions (maturin), fragile for a rapidly-moving tool
- Homebrew formula: No formula exists upstream; maintaining a custom tap is heavy overhead

### Decision 2: New dedicated `headroom.nix` module over inline addition
Every post-install hook in this config lives in its own file under `nix/modules/home/` (`rtk.nix`, `neovim.nix`, `tuna/default.nix`). Consistency and separation of concerns favour a new file.

### Decision 3: `home.packages = [ pkgs.uv ]` at user-level
`uv` is a developer tool, not a system utility. User-level placement via Home Manager is consistent with how `pyenv`, `rustup`, and similar tools are managed in `home.nix`.

### Decision 4: `headroom-ai[all]` extras
The `[all]` extras include MCP server support (`headroom_compress`, `headroom_retrieve`, `headroom_stats`) which directly complements opencode's MCP integration. Base install would omit these.

## Risks / Trade-offs

- **Network dependency at rebuild time**: `uv tool install` requires internet access during `darwin-rebuild switch`. If offline, the activation script silently skips (guarded by `command -v uv`).
  → Mitigation: The guard ensures rebuild doesn't fail; tool simply won't be installed until next online rebuild.

- **uv tool path not on $PATH by default**: `uv tool` installs to `~/.local/bin`. This directory must be in `$PATH`.
  → Mitigation: `uv` automatically adds `~/.local/bin` to PATH suggestions; the existing shell config (fish/zsh) should already include it. If not, a `home.sessionPath` entry can be added.

- **Headroom version drift**: No version pin means `uv tool install` installs latest. On a fresh machine it may install a different version than an existing machine.
  → Mitigation: Acceptable for a dev tool at this stage; can add `--constraint` or `uv.lock` later if pinning becomes necessary.

## Migration Plan

1. Add `headroom.nix` module
2. Import in `home.nix`
3. Run `darwin-rebuild switch`
4. Verify: `headroom --version` and `headroom mcp --help`

**Rollback**: Remove the import from `home.nix` and rebuild. The `uv` tool install persists in `~/.local/share/uv/` but the activation script simply won't re-run.
