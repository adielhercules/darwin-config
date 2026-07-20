## ADDED Requirements

### Requirement: macOS notification on permission question
The notifications plugin SHALL send a macOS system notification when a permission question requires user input.

#### Scenario: Permission question triggers notification
- **WHEN** a `permission.asked` event fires in opencode
- **THEN** a macOS notification SHALL be sent with title "Agent - <dirname>" and message "Question needs your answer in <session title>"

#### Scenario: Session title is resolved from cache or API
- **WHEN** a `permission.asked` event fires AND the session title is not in the cache
- **THEN** the plugin SHALL fetch the session title via `client.session.get()` and cache it

### Requirement: macOS notification on all tasks complete (root session only)
The notifications plugin SHALL send a macOS system notification when the root/parent session goes idle. Subagent sessions going idle SHALL NOT trigger this notification. The plugin tracks which sessions are subagents via their `parentID` from `session.created` events.

#### Scenario: Root session idle triggers notification
- **WHEN** a `session.idle` event fires for a root session (no `parentID`)
- **THEN** a macOS notification SHALL be sent with title "Agent - <dirname>" and message "All tasks complete in <session title>"

#### Scenario: Subagent idle does not trigger notification
- **WHEN** a `session.idle` event fires for a subagent session (has `parentID`)
- **THEN** no "all tasks complete" notification SHALL be sent
- **AND** the active subagent counter SHALL be decremented

#### Scenario: Root session idle resets counter
- **WHEN** a `session.idle` event fires for a root session
- **THEN** the active subagent counter SHALL be reset to zero regardless of previous count

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

### Requirement: macOS notification on question asked
The notifications plugin SHALL send a macOS system notification when a question is asked.

#### Scenario: Question asked triggers notification
- **WHEN** a `question.asked` event fires in opencode
- **THEN** a macOS notification SHALL be sent with title "Agent - <dirname>" and message "New question asked in <session title>"

## REMOVED Requirements

### Requirement: In-app toast for subagent launch
**Reason**: Replaced by macOS system notification in the consolidated notifications plugin.
**Migration**: Subagent launch notifications are now handled by the notifications plugin as system notifications via `terminal-notifier`.
