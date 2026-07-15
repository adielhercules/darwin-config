## Why

The current OpenCode configuration shows a generic "Hi Adiel" toast on every new session start, which provides no real signal about what's happening in the session. A more useful notification is one that fires whenever a subagent (Task tool) is launched, surfacing which subagent type was invoked (e.g. `explore`, `web-research`, `general`, `scout`) so it's easier to notice delegation happening in real time.

## What Changes

- **BREAKING**: Remove the session-start "Hi Adiel" greeting toast plugin.
- Add a new plugin that listens for `session.created` events and detects subagent sessions (sessions with `info.parentID` set, i.e. created by the Task tool).
- Show a toast with message `"<agent-id> Subagent launched"` using the raw subagent type/name (e.g. `"explore Subagent launched"`) whenever such a subagent session is created.
- Rename the plugin file from `hi-adiel.ts` to `subagent-launch.ts` to reflect its new purpose.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `opencode-agent-config`: Replaces the "session-start greeting toast" requirement with a "subagent-launch toast" requirement — the toast notification mechanism now fires on subagent session creation (detected via `parentID` on the `session.created` event) instead of on every new session, and displays the subagent's type/name instead of a static greeting.

## Impact

- `nix/modules/home/opencode.nix`: replace `hiAdielPlugin` binding with a new subagent-launch-toast plugin; rename the generated plugin file under `xdg.configFile."opencode/plugins/..."`.
- No other code, API, or dependency changes. Existing live spec (`openspec/specs/opencode-agent-config/spec.md`) is left untouched until this change is archived, at which point the delta spec here will be merged in.
