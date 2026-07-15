## Why

AI coding agent sessions (opencode, Claude, etc.) consume large amounts of context with tool outputs, file contents, and conversation history, increasing cost and reducing effective context window. Headroom is a context compression layer that reduces token usage 15–95% while preserving answer accuracy — a natural complement to opencode already installed in this config.

## What Changes

- Add `uv` (Python tool manager) to `home.packages` at user-level via Home Manager
- Add a new Home Manager module `nix/modules/home/headroom.nix` that installs `headroom-ai[all]` as a global `uv` tool after each rebuild
- Import the new module in `nix/darwin/home.nix`

## Capabilities

### New Capabilities

- `headroom-ai-install`: Global installation of headroom-ai CLI and MCP server via `uv tool install`, managed declaratively through a Home Manager activation script

### Modified Capabilities

_(none — no existing spec requirements change)_

## Impact

- `nix/darwin/home.nix`: gains one import line
- `nix/modules/home/headroom.nix`: new file
- Runtime dependency: `uv` added to user environment (`home.packages`)
- `headroom` CLI available on `$PATH` after rebuild; MCP server tools (`headroom_compress`, `headroom_retrieve`, `headroom_stats`) available for use with opencode
