## Context

The opencode configuration in `nix/modules/home/opencode.nix` currently generates everything inline:
- `opencode.jsonc` as a Nix attrset serialized to JSON
- Plugin `.ts` files as Nix multi-line strings (`''...''`)

This works but has drawbacks: plugin TS code loses syntax highlighting, can't be linted/tested independently, and diffs are noisy in git. The `subagent-launch.ts` plugin is already a symlink to a Nix store path, making direct editing impossible.

Additionally, the built-in subagents (`explore`, `scout`, `general`) cover codebase research and dependency inspection, but there's no dedicated subagent for pure reasoning/thinking tasks. Complex analysis currently happens inline in the primary agent's conversation, bloating context.

## Goals / Non-Goals

**Goals:**
- Plugin `.ts` files should be editable source files with proper syntax highlighting and git diffs
- Agent definitions should be portable `.md` files with frontmatter (matching OpenCode's file-based agent convention)
- Add a `thinking` subagent for deep reasoning that stays read-only (no file edits, no shell)
- macOS notifications for events requiring user attention (questions, task completion)
- Maintain Nix as the deployment mechanism (no change to `just deploy` workflow)

**Non-Goals:**
- Changing the `opencode.jsonc` generation approach (still Nix attrset → JSON)
- Modifying the built-in `explore`, `scout`, `general` subagent behavior
- Cross-platform notification support (macOS only via `osascript`)
- Hot-reloading opencode config (requires restart by design)

## Decisions

### 1. Source files in `nix/modules/home/opencode/` deployed by Nix

**Decision**: Plugin `.ts` files and agent `.md` files live in `nix/modules/home/opencode/` and are deployed via `xdg.configFile.source`.

**Alternatives considered**:
- **Inline Nix strings (status quo)**: No syntax highlighting, noisy diffs, can't lint
- **Project-level `.opencode/`**: Only applies when opencode is opened in this specific repo, not globally
- **Separate repo/submodule**: Over-engineered for 3-4 files
- **`dotfiles/opencode/`**: Rejected because the files belong with the Nix module that deploys them

**Rationale**: Keeping source files alongside `opencode.nix` in `nix/modules/home/opencode/` co-locates the config with its deployment logic. The relative path `./opencode` is simple and avoids cross-directory references.

### 2. Thinking subagent as read-only analysis agent

**Decision**: The `thinking` subagent has `read`, `grep`, `glob`, `list` permissions but `deny` for `edit`, `bash`, `webfetch`, `websearch`.

**Alternatives considered**:
- **Full-access thinking agent**: Could edit files, but then it's indistinguishable from `general`
- **Thinking with web access**: Adds complexity; web research is already `web-research`'s job
- **No thinking agent**: Primary agents do analysis inline, bloating context

**Rationale**: Pure read-only analysis forces structured thinking without side effects. The primary agent delegates reasoning to `thinking` and acts on the recommendations. This separation keeps the primary agent's thread focused on orchestration.

### 3. osascript for notifications (not terminal-notifier)

**Decision**: Use `osascript -e 'display notification ...'` as the primary notification mechanism. `terminal-notifier` added to brews as optional enhancement.

**Alternatives considered**:
- **terminal-notifier only**: Requires installation, more features but heavier
- **Fish `done` plugin integration**: Can't call fish plugins from TypeScript plugins (different process)
- **Ghostty escape sequences**: Only works in Ghostty, not portable

**Rationale**: `osascript` is built into macOS, zero dependencies, works everywhere. `terminal-notifier` is added to brews for richer notifications (sound, icons) but the plugin doesn't depend on it.

### 4. Notification triggers

**Decision**: Notify on `permission.asked` (question) and `session.idle` with no active subagents (all done).

**Alternatives considered**:
- **Notify on every session.created**: Too noisy for subagent launches
- **Notify on tool.execute.before**: Too frequent, fires on every tool call
- **Notify on session.error**: Useful but not requested

**Rationale**: These two events represent the cases where the user's attention is most needed: either they need to answer a question, or they've been waiting and all work is complete.

## Risks / Trade-offs

- **[Risk] `xdg.configFile.source` creates symlinks**: If the source file is moved/deleted, the deployed config breaks. → Mitigation: Source files are in the same repo, tracked by git. Nix build fails if source is missing.
- **[Risk] Thinking subagent model override**: Users might forget to update the model when primary model changes. → Mitigation: Default inherits from primary; override is commented with clear instructions.
- **[Trade-off] osascript notifications are basic**: No custom icons, no action buttons. → Acceptable: The fish `done` plugin uses the same mechanism; `terminal-notifier` available for richer notifications.
- **[Trade-off] Active subagent tracking is approximate**: Counter-based, not perfectly synchronized with OpenCode's internal session state. → Acceptable: False positives (notify "all done" while subagent still running) are rare and non-destructive.
