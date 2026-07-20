## Why

The OpenCode plugin ecosystem has two overlapping notification plugins: `subagent-launch.ts` (in-app toast) and `notifications.ts` (macOS system notifications). The `notifications.ts` plugin also has a typo (`sendNotifiction`) that silently breaks subagent notifications. Additionally, notifications lack context — they don't indicate which project or session triggered them, and there's no notification for question events. Consolidating into a single plugin with richer notifications reduces duplication and improves user awareness.

## What Changes

- **Delete** `config/opencode/plugins/subagent-launch.ts` — its subagent toast functionality is replaced by a system notification in the consolidated plugin
- **Fix typo** in `notifications.ts`: `sendNotifiction` → `sendNotification`
- **Update notification format** to include project context:
  - Title: `Agent - <dirname>` (basename of working directory)
  - Body: `<content> in <session title>` (e.g. "Question needs your answer in darwin-config")
- **Add `question.asked` event handler** — sends a system notification when a question is asked
- **Add Ghostty activation** — `-activate com.mitchellh.ghostty` flag on all notifications so clicking brings the terminal to front
- **Add session title cache** — caches session titles from `session.created` events; fetches via `client.session.get()` for events that only provide `sessionID`
- **Update Nix deployment** — remove `subagent-launch.ts` from `opencode.nix` `xdg.configFile` entries and directory layout comment

## Capabilities

### Modified Capabilities
- `opencode-notifications`: Notification format changes (title/body), new `question.asked` trigger, Ghostty activation, session title resolution, removal of in-app toast requirement (replaced by system notification)
- `opencode-source-plugins`: Removal of `subagent-launch.ts` from source plugin set

## Impact

- **Files modified**: `config/opencode/plugins/notifications.ts`, `nix/modules/home/opencode.nix`
- **Files deleted**: `config/opencode/plugins/subagent-launch.ts`
- **Dependencies**: `terminal-notifier` (brew, already required), Ghostty (for `-activate` flag)
- **Breaking**: In-app toasts for subagent launch are replaced by macOS system notifications — users will see system notifications instead of TUI toasts
