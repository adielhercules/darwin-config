## Context

The OpenCode TUI runs in Ghostty on macOS. Two plugins currently handle notifications:
- `subagent-launch.ts` — shows an in-app TUI toast via `client.tui.showToast()` when a subagent is created
- `notifications.ts` — sends macOS system notifications via `terminal-notifier` for permission questions and task completion

The `notifications.ts` plugin has a typo (`sendNotifiction`) that silently breaks its subagent notification. Both plugins listen for `session.created` events independently. Notifications lack context — the title is always "OpenCode" with no indication of which project or session triggered them.

The plugin API provides `PluginInput` with `directory` (working directory), `client` (full SDK client), and `project` info. Events like `session.created` include full `Session` objects with `title`, while `permission.asked` and `session.idle` only provide `sessionID`.

## Goals / Non-Goals

**Goals:**
- Consolidate subagent-launch toast into the notifications plugin as a system notification
- Fix the `sendNotifiction` typo
- Add project and session context to all notifications
- Add `question.asked` event notification
- Bring Ghostty to front when a notification is clicked
- Efficiently resolve session titles without redundant API calls

**Non-Goals:**
- Targeting a specific Ghostty tab/window (not yet supported by Ghostty's AppleScript API)
- Supporting non-macOS platforms
- Changing the `agent-state.ts` plugin (separate concern)
- Adding notification preferences/configuration

## Decisions

### 1. Single plugin file, system notifications only

**Decision**: Merge subagent-launch into notifications.ts and use only `terminal-notifier` system notifications (no `client.tui.showToast()`).

**Rationale**: System notifications persist in the notification center and are visible even when the terminal isn't in focus. In-app toasts disappear quickly. One plugin is simpler to maintain.

**Alternative considered**: Keep both plugins — rejected because it duplicates event handling and the user explicitly wants consolidation.

### 2. Session title cache with API fallback

**Decision**: Maintain a `Map<string, string>` mapping session IDs to titles. Populate from `session.created` events (which include full `Session` objects). For events that only have `sessionID` (like `permission.asked`, `question.asked`), fetch via `client.session.get()` and cache the result.

**Rationale**: Most events happen in sequence within a session, so the cache hit rate will be high. The API call is a single HTTP request to the local OpenCode server — negligible latency.

**Alternative considered**: Always fetch — rejected because it's wasteful when the cache already has the title.

### 3. Ghostty activation via `-activate` flag

**Decision**: Add `-activate com.mitchellh.ghostty` to all `terminal-notifier` calls.

**Rationale**: This is the simplest approach that works. When a notification is clicked, Ghostty comes to front. Tab-level targeting isn't reliable yet in Ghostty's AppleScript API.

**Alternative considered**: Use `-execute` with AppleScript to focus specific tabs — rejected because Ghostty doesn't expose a `tty` property on terminals for matching.

### 4. Directory basename in notification title

**Decision**: Use `basename(directory)` for the notification title (e.g., `Agent - darwin-config`).

**Rationale**: Full paths are too long for notification titles. The directory basename is short, meaningful, and disambiguates which project a notification belongs to.

### 5. Session name in notification body

**Decision**: Append `in <session title>` to all notification messages.

**Rationale**: When running multiple OpenCode sessions, knowing which session triggered the notification is essential for context.

## Risks / Trade-offs

- **[Risk] `client.session.get()` fails** → Fallback to `"OpenCode"` as session name. The notification still fires with reduced context.
- **[Risk] Ghostty not installed** → `-activate` flag is silently ignored by `terminal-notifier`. Notifications still work, just without focus.
- **[Trade-off] In-app toasts removed** → Users who preferred the non-intrusive TUI toast now get system notifications. System notifications are more persistent but more intrusive.
- **[Trade-off] Session cache grows unbounded** → In practice, sessions are created and deleted regularly. Could add eviction but unnecessary for typical usage.
