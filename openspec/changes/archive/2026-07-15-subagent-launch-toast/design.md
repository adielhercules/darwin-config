## Context

`nix/modules/home/opencode.nix` currently defines a `hiAdielPlugin` that shows
a static "Hi Adiel" toast on every `session.created` event, regardless of
whether the session is a root/user session or a subagent session. This
provides no useful signal, and the goal is to repurpose the toast mechanism
to surface subagent launches instead.

OpenCode has no dedicated event for "Task tool invoked" — subagent sessions
are just regular sessions with two distinguishing fields on the `info`
payload of `session.created`:
- `parentID` — set to the parent session's ID for subagent sessions (unset
  for root/user sessions)
- `agent` — the resolved subagent name (e.g. `"explore"`, `"web-research"`)

## Goals / Non-Goals

**Goals:**
- Show a toast reading `"<agent-id> Subagent launched"` whenever a subagent
  session is created (Task tool invocation).
- Do not show any toast on root/user session creation.
- Keep the existing plugin-file delivery mechanism (a file under
  `xdg.configFile."opencode/plugins/..."`) since that pattern already works
  and is consistent with how `rtk.ts` is managed.

**Non-Goals:**
- Deduplicating repeated subagent launches (e.g. suppressing repeat toasts
  for the same subagent type within a session) — out of scope for this
  change.
- Pretty/title-cased subagent names (e.g. "Explore Subagent launched") — the
  user explicitly opted for raw agent id as-is.
- Handling any event other than `session.created` (e.g. no need to inspect
  `message.part.updated` tool-call args) since `session.created`'s `agent`
  field is the simpler, canonical signal.

## Decisions

- **Detection via `session.created` + `parentID`**: Chosen over inspecting
  `message.part.updated` tool-call parts for `task` invocations because
  `session.created`'s `info.agent` field is already the resolved/canonical
  subagent name, whereas the tool-call args would require digging into
  `part.state.input.subagent_type` — a less direct source of truth in
  practice, per empirical investigation of the opencode source
  (`packages/opencode/src/tool/task.ts`, `packages/opencode/src/session/session.ts`).
- **Read `info` defensively**: Access `event.properties?.info ?? event.properties`
  to tolerate minor SDK event-wrapper shape differences across opencode
  versions, since the exact nesting key wasn't confirmed with 100% certainty
  at doc-review time.
- **Rename plugin file `hi-adiel.ts` → `subagent-launch.ts`**: Keeps the file
  name aligned with its new purpose; avoids confusion for future readers of
  the Nix module.
- **Raw agent id in message, no title-casing**: Per explicit user decision,
  keep implementation simple (no extra name-formatting logic to maintain).

## Risks / Trade-offs

- [Risk] The exact `event.properties` nesting key might differ from what's
  assumed, causing the toast to silently never fire → Mitigation: defensive
  fallback (`event.properties?.info ?? event.properties`) covers the two
  most likely shapes; can be further verified by logging `JSON.stringify(event)`
  once during manual testing if the toast doesn't appear as expected.
- [Risk] Toast spam if many subagents are launched in quick succession (e.g.
  parallel Task calls) → Accepted trade-off per proposal (no deduplication
  is a non-goal); matches the level of noise the user explicitly requested.

## Migration Plan

1. Edit `nix/modules/home/opencode.nix`: remove `hiAdielPlugin`, add
   `subagentLaunchPlugin`, update the `xdg.configFile` binding to write to
   `opencode/plugins/subagent-launch.ts`.
2. Rebuild home-manager (`darwin-rebuild switch` / project's standard rebuild
   command) to regenerate `~/.config/opencode/plugins/subagent-launch.ts`
   and remove the stale `hi-adiel.ts` (home-manager manages generation
   declaratively, so the old file is replaced/removed on activation).
3. Manually verify: start a new opencode session (expect no toast), then
   trigger a Task tool call (expect `"<agent-id> Subagent launched"` toast).

No rollback complexity — this is a local dev-tooling config change with no
persisted state or external consumers.
