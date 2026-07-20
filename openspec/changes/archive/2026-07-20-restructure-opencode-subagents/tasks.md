## 1. Source Directory Structure

- [x] 1.1 Create `nix/modules/home/opencode/plugins/` directory
- [x] 1.2 Create `nix/modules/home/opencode/agents/` directory

## 2. Plugin Source Files

- [x] 2.1 Create `nix/modules/home/opencode/plugins/subagent-launch.ts` with typed Plugin import and proper error handling
- [x] 2.2 Create `nix/modules/home/opencode/plugins/notifications.ts` with terminal-notifier-based macOS notifications

## 3. Agent Definitions

- [x] 3.1 Create `nix/modules/home/opencode/agents/thinking.md` with frontmatter (description, mode, permission) and system prompt
- [x] 3.2 Create `nix/modules/home/opencode/agents/code-reviewer.md` with frontmatter and tech-specific review prompt
- [x] 3.3 Create `nix/modules/home/opencode/agents/research-summarizer.md` with frontmatter and research consolidation prompt

## 4. Nix Module Updates

- [x] 4.1 Rewrite `nix/modules/home/opencode.nix` to deploy plugins via `xdg.configFile.source` from `nix/modules/home/opencode/plugins/`
- [x] 4.2 Add agent `.md` deployment via `xdg.configFile.source` from `nix/modules/home/opencode/agents/`
- [x] 4.3 Add `thinking` subagent to `opencodeConfig.agent` with read-only permissions
- [x] 4.4 Add `code-reviewer` subagent to `opencodeConfig.agent` with read-only permissions
- [x] 4.5 Add `research-summarizer` subagent to `opencodeConfig.agent` with read-only permissions
- [x] 4.6 Add all subagents to `delegateTaskPermission` allowlist
- [x] 4.7 Update `delegatePrompt` to mention all subagents

## 5. Homebrew Dependencies

- [x] 5.1 Add `terminal-notifier` to brews in `nix/darwin/profiles/defaults.nix`

## 6. Validation

- [x] 6.1 Run `nix fmt` to fix formatting
- [x] 6.2 Run `nix flake check` to validate configuration
