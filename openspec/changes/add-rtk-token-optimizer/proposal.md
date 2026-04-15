## Why

AI coding tools (OpenCode, GitHub Copilot) run hundreds of shell commands per session — `git`, `ls`, `grep`, `cargo test` — and pipe their full raw output directly into LLM context, consuming 60–90% more tokens than necessary. `rtk` (Rust Token Killer) is a single Rust binary CLI proxy that transparently intercepts these commands and compresses their output before it reaches the model, with under 10ms overhead. Installing it via the Nix config ensures it is always present and its hooks are initialized automatically on every machine rebuild, with no manual post-install steps.

## What Changes

- Add `"rtk"` to `homebrew.brews` in `nix/darwin/default.nix` so rtk is installed declaratively via Homebrew
- Create `nix/modules/home/rtk.nix` — a new Home Manager module that:
  - Runs `rtk init -g --opencode` via `home.activation` to install the OpenCode plugin hook
  - Runs `rtk init -g --copilot` via `home.activation` to install the GitHub Copilot `PreToolUse` hook
- Import the new module in `nix/darwin/home.nix`

## Capabilities

### New Capabilities
- `rtk-token-optimizer`: A declaratively managed `rtk` installation with automatic hook initialization for OpenCode and GitHub Copilot, reducing LLM token consumption by 60–90% per AI coding session.

### Modified Capabilities
<!-- No existing spec-level requirements are changing -->

## Impact

- **`nix/darwin/default.nix`**: Add `"rtk"` to `homebrew.brews`
- **`nix/modules/home/rtk.nix`**: New Home Manager module with `home.activation` entries for OpenCode and Copilot hook init
- **`nix/darwin/home.nix`**: Add import for the new `rtk.nix` module
- **No breaking changes** — rtk is a transparent proxy; existing AI tool workflows are unchanged
