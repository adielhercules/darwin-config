## MODIFIED Requirements

### Requirement: macOS notification on permission question
The notifications plugin SHALL send a macOS system notification when a permission question requires user input.

#### Scenario: Permission question triggers notification
- **WHEN** a `permission.asked` event fires in opencode
- **THEN** a macOS notification SHALL be sent with title "Agent - <dirname>" and message "Question needs your answer in <session title>"

#### Scenario: Session title is resolved from cache or API
- **WHEN** a `permission.asked` event fires AND the session title is not in the cache
- **THEN** the plugin SHALL fetch the session title via `client.session.get()` and cache it

### Requirement: macOS notification on all tasks complete
The notifications plugin SHALL send a macOS system notification when all tasks are complete and no active subagents remain. This triggers only on `session.idle` events (not `session.status`).

#### Scenario: All tasks complete triggers notification
- **WHEN** a `session.idle` event fires AND the active subagent count is zero
- **THEN** a macOS notification SHALL be sent with title "Agent - <dirname>" and message "All tasks complete in <session title>"

#### Scenario: Subagent still active suppresses notification
- **WHEN** a `session.idle` event fires AND there are still active subagents
- **THEN** no "all tasks complete" notification SHALL be sent

### Requirement: Notification mechanism uses terminal-notifier
The plugin SHALL use `terminal-notifier` (brew package) for macOS notifications.

#### Scenario: terminal-notifier notification succeeds
- **WHEN** `terminal-notifier` is installed via homebrew
- **THEN** notifications SHALL be sent via `terminal-notifier -title "..." -message "..." -sound default -activate com.mitchellh.ghostty`

#### Scenario: terminal-notifier notification failure is logged
- **WHEN** `terminal-notifier` fails to send a notification
- **THEN** a warning SHALL be logged to console but no error SHALL be thrown

#### Scenario: Ghostty activation on notification click
- **WHEN** a notification is clicked
- **THEN** Ghostty SHALL be brought to front via the `-activate com.mitchellh.ghostty` flag

### Requirement: macOS notification on subagent launch
The notifications plugin SHALL send a macOS system notification when a subagent session is created.

#### Scenario: Subagent launch triggers notification
- **WHEN** a `session.created` event fires with a `parentID`
- **THEN** a macOS notification SHALL be sent with title "Agent - <dirname>" and message "<agentName> subagent launched in <session title>"

#### Scenario: Session title populated from event
- **WHEN** a `session.created` event fires AND the event includes session info with a title
- **THEN** the session title SHALL be cached for use by other events

### Requirement: Notification format includes project and session context
All notifications SHALL include the project directory name in the title and the session title in the body.

#### Scenario: Title uses directory basename
- **WHEN** any notification is sent
- **THEN** the title SHALL be "Agent - <basename(directory)>"

#### Scenario: Body includes session title
- **WHEN** any notification is sent
- **THEN** the body SHALL end with "in <session title>"

#### Scenario: Session title fetch fails
- **WHEN** `client.session.get()` fails to return a session title
- **THEN** the plugin SHALL use "OpenCode" as the session title fallback

## ADDED Requirements

### Requirement: macOS notification on question asked
The notifications plugin SHALL send a macOS system notification when a question is asked.

#### Scenario: Question asked triggers notification
- **WHEN** a `question.asked` event fires in opencode
- **THEN** a macOS notification SHALL be sent with title "Agent - <dirname>" and message "New question asked in <session title>"

## REMOVED Requirements

### Requirement: In-app toast for subagent launch
**Reason**: Replaced by macOS system notification in the consolidated notifications plugin.
**Migration**: Subagent launch notifications are now handled by the notifications plugin as system notifications via `terminal-notifier`.
