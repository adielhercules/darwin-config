## Why

The opencode agent/subagent configuration is currently generated inline as Nix strings inside `opencode.nix`, making plugins hard to edit, test, and version-control properly. Additionally, there's no dedicated subagent for complex reasoning/thinking tasks, forcing primary agents to do deep analysis inline and bloat their conversation threads.

## What Changes

- **Source-driven plugins**: Move plugin `.ts` files from Nix-inline generation to proper source files in `nix/modules/home/opencode/plugins/`, deployed via `xdg.configFile.source`
- **Source-driven agents**: Add `nix/modules/home/opencode/agents/` directory with `.md` agent definition files, deployed via `xdg.configFile.source`
- **New thinking subagent**: Dedicated subagent for deep reasoning, architectural decisions, and structured analysis — read-only permissions, inherits primary model
- **New code-reviewer subagent**: Tech-specific code reviewer that reviews code by build, provides actionable feedback, and asks the primary to delegate fixes back to build
- **New research-summarizer subagent**: Consolidates web-research findings into concise, structured summaries for the primary agent
- **Notifications plugin**: New `notifications.ts` plugin using `terminal-notifier` for system notifications on permission questions and task completion
- **Delegation updates**: `build` and `plan` primary agents can now delegate to all custom subagents

## Capabilities

### New Capabilities

- `opencode-source-plugins`: Plugin .ts files managed as source in `nix/modules/home/opencode/plugins/` and deployed by Nix, replacing inline Nix string generation
- `opencode-thinking-subagent`: Dedicated subagent for deep reasoning and structured analysis with read-only permissions
- `opencode-code-reviewer-subagent`: Tech-specific code reviewer with read-only permissions, provides actionable feedback
- `opencode-research-summarizer-subagent`: Research consolidation subagent, distills findings into concise summaries
- `opencode-notifications`: macOS system notifications via `terminal-notifier` for permission questions and task completion events

### Modified Capabilities

<!-- No existing specs to modify -->

## Impact

- **Files created**: `nix/modules/home/opencode/plugins/subagent-launch.ts`, `nix/modules/home/opencode/plugins/notifications.ts`, `nix/modules/home/opencode/agents/thinking.md`, `nix/modules/home/opencode/agents/code-reviewer.md`, `nix/modules/home/opencode/agents/research-summarizer.md`
- **Files modified**: `nix/modules/home/opencode.nix` (rewritten to deploy from source, all subagents), `nix/darwin/profiles/defaults.nix` (added `terminal-notifier` brew)
- **Runtime**: Requires `just deploy` and opencode restart for changes to take effect
- **Dependencies**: `terminal-notifier` added to homebrew for macOS notifications
