## MODIFIED Requirements

### Requirement: Subagent-launch toast
The system MUST show a toast notification via a global opencode plugin every
time a subagent session is created (i.e. a session launched by the Task
tool on behalf of a primary agent), since OpenCode has no config or plugin
primitive for a persistent custom TUI sidebar section.

#### Scenario: Toast fires on subagent session creation
- **WHEN** a subagent session is created (e.g. a primary agent invokes the
  Task tool, such as `explore`, `scout`, `general`, or `web-research`)
- **THEN** the plugin's `session.created` event handler detects the
  session's `info.parentID` is set (indicating a child/subagent session)
  and calls `client.tui.showToast({ body: { message: "<agent-id> Subagent
  launched", variant: "info" } })`, where `<agent-id>` is the raw subagent
  type/name (`info.agent`), e.g. `"explore Subagent launched"`

#### Scenario: Toast does not fire on root/user session creation
- **WHEN** a new root opencode session is created (e.g. via `/new` or a
  fresh `opencode` launch, not originating from the Task tool)
- **THEN** the session's `info.parentID` is unset, and the plugin's
  `session.created` handler does not call `client.tui.showToast`

#### Scenario: Toast fires on every subagent launch, not deduplicated
- **WHEN** multiple subagent sessions are launched in sequence (e.g. several
  Task tool calls within one conversation)
- **THEN** the toast is shown again for each subagent session created, with
  no once-per-day or once-ever deduplication
