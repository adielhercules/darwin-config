## Context

The darwin-config repo manages a macOS development machine declaratively via Nix + nix-darwin + Home Manager + nix-homebrew. Two AI coding tools are in active use: **OpenCode** (installed via `homebrew.brews`, integrated via an `.opencode/` plugin) and **GitHub Copilot** (VS Code extension with agent hooks). Both tools issue Bash tool calls during sessions, and the raw output of commands like `git status`, `cargo test`, and `ls` is consumed verbatim as LLM context — wasting 60–90% of tokens on noise.

`rtk` is a single Rust binary available as a Homebrew formula (`brew install rtk`). It acts as a transparent CLI proxy: the AI tool calls `git status`, the hook rewrites it to `rtk git status` before execution, and the filtered/compressed output is returned instead. No changes to how the AI tools operate — only to what they receive.

The existing activation pattern in this config is `home.activation.<name> = lib.hm.dag.entryAfter [ "writeBoundary" ] ''...''` (see `nix/modules/home/neovim.nix`). This is the appropriate mechanism for running `rtk init` commands idempotently after every rebuild.

## Goals / Non-Goals

**Goals:**
- Declaratively install `rtk` via Homebrew so it is always present after `darwin-rebuild switch`
- Automatically run `rtk init -g --opencode` and `rtk init -g --copilot` as Home Manager activation steps, so hooks are always initialized without any manual post-install steps
- Encapsulate the rtk configuration in its own `nix/modules/home/rtk.nix` module, consistent with the existing per-tool module pattern

**Non-Goals:**
- Managing `rtk`'s `~/.config/rtk/config.toml` declaratively (leave user-controlled)
- Enabling telemetry or opting into any rtk analytics
- Configuring rtk for tools other than OpenCode and Copilot
- Pinning a specific rtk version (Homebrew tracks latest)

## Decisions

### Decision 1: Homebrew brew (not nixpkgs) for the rtk binary

`rtk` is available in `nixpkgs` as `rtk` but the crates.io package with that name is a different project ("Rust Type Kit"). The correct package is `rtk-ai/rtk`, available as `brew install rtk` and confirmed in nixpkgs as `rtk` only recently. To avoid ambiguity and stay consistent with how other CLI tools (`opencode`, `yazi`, `aria2`) are managed in this config, `rtk` is added to `homebrew.brews` alongside them.

**Alternative considered**: Add as a nixpkgs package in `home.packages`. Rejected because the homebrew formula is the canonical install path recommended by the project, and all other similar CLI tools in this config use Homebrew.

### Decision 2: `home.activation` with `entryAfter [ "writeBoundary" ]` for `rtk init`

`rtk init -g --opencode` and `rtk init -g --copilot` are idempotent commands that write hook files to `~/.config/` and user-level settings. They must run after Home Manager has placed its own symlinks and files (post `writeBoundary`). The `home.activation` DAG is the canonical way in this config to run post-switch shell commands (see `neovim.nix`).

**Alternative considered**: A launchd user agent or a fish `shellInit` line. Rejected — these would run on every shell start rather than once on rebuild. Activation scripts are the right granularity.

### Decision 3: New `nix/modules/home/rtk.nix` module (not inline in `home.nix`)

Every AI/dev tool with meaningful configuration in this config has its own module file (`helix.nix`, `ghostty.nix`, `neovim.nix`, etc.). The rtk activation logic is self-contained and should follow the same pattern for maintainability.

### Decision 4: Guard `rtk init` with a `which rtk` check

Since Homebrew runs during the nix-darwin activation phase (before Home Manager activation), `rtk` should be on PATH by the time `home.activation` runs. However, to make the activation script safe on first boot or if Homebrew hasn't finished yet, the script should guard with `command -v rtk` before calling init — making it a no-op if rtk is not yet available, and self-healing on the next rebuild.

## Risks / Trade-offs

- **[Risk] Homebrew PATH not set during Home Manager activation** → Mitigation: guard with `command -v rtk || exit 0` so the activation is silently skipped if rtk isn't on PATH yet; it will succeed on the next `darwin-rebuild switch`.
- **[Risk] `rtk init` overwrites existing hook files** → rtk init is designed to be idempotent and merges/updates hook files safely; this is expected behavior.
- **[Risk] OpenCode plugin hook conflicts with manually placed hooks** → `.opencode/` is managed by the repo (via `.opencode/package.json`); rtk installs its hook into `~/.config/opencode/` (global), not the project directory, so there is no conflict.

## Migration Plan

1. Add `"rtk"` to `homebrew.brews` in `nix/darwin/default.nix`
2. Create `nix/modules/home/rtk.nix` with `home.activation` entries
3. Add the import to `nix/darwin/home.nix`
4. Run `darwin-rebuild switch` — Homebrew installs rtk, then Home Manager activation runs `rtk init` for both tools
5. Verify: `rtk --version`, `rtk init --show`

**Rollback**: Remove `"rtk"` from `homebrew.brews` and the import from `home.nix`, then rebuild. `homebrew.onActivation.cleanup = "zap"` will uninstall rtk automatically.

## Open Questions

- Does `rtk init -g --copilot` require VS Code to be installed? (It writes to `~/.vscode/settings.json` — if VS Code is absent the file may not exist yet.) If so, the activation script should check for this and proceed gracefully.
