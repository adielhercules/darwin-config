## ADDED Requirements

### Requirement: macOS notification on permission question
The notifications plugin SHALL send a macOS system notification when a permission question requires user input.

#### Scenario: Permission question triggers notification
- **WHEN** a `permission.asked` event fires in opencode
- **THEN** a macOS notification SHALL be sent with title "OpenCode" and message "Question needs your answer"

### Requirement: macOS notification on all tasks complete
The notifications plugin SHALL send a macOS system notification when all tasks are complete and no active subagents remain. This triggers only on `session.idle` events (not `session.status`).

#### Scenario: All tasks complete triggers notification
- **WHEN** a `session.idle` event fires AND the active subagent count is zero
- **THEN** a macOS notification SHALL be sent with title "OpenCode" and message "All tasks complete"

#### Scenario: Subagent still active suppresses notification
- **WHEN** a `session.idle` event fires AND there are still active subagents
- **THEN** no "all tasks complete" notification SHALL be sent

### Requirement: Notification mechanism uses terminal-notifier
The plugin SHALL use `terminal-notifier` (brew package) for macOS notifications.

#### Scenario: terminal-notifier notification succeeds
- **WHEN** `terminal-notifier` is installed via homebrew
- **THEN** notifications SHALL be sent via `terminal-notifier -title "..." -message "..." -sound default`

#### Scenario: terminal-notifier notification failure is logged
- **WHEN** `terminal-notifier` fails to send a notification
- **THEN** a warning SHALL be logged to console but no error SHALL be thrown

### Requirement: In-app toast for subagent launch
The subagent-launch plugin SHALL continue to show an in-app toast when a subagent is launched.

#### Scenario: Subagent launch toast
- **WHEN** a `session.created` event fires with a `parentID`
- **THEN** a toast notification SHALL be shown with the subagent name
