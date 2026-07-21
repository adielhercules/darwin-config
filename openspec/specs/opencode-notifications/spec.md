## ADDED Requirements

### Requirement: Smart notification behavior based on Ghostty focus
The notifications plugin SHALL detect whether Ghostty is the frontmost application and suppress system notifications when it is focused, since the user is already looking at the TUI.

#### Scenario: Ghostty is frontmost suppresses system notification
- **WHEN** a notification event fires AND Ghostty is the frontmost application
- **THEN** no macOS system notification SHALL be sent via terminal-notifier

#### Scenario: Ghostty is not frontmost sends system notification
- **WHEN** a notification event fires AND Ghostty is NOT the frontmost application
- **THEN** a macOS system notification SHALL be sent via terminal-notifier

#### Scenario: Ghostty detection uses osascript
- **WHEN** the plugin needs to check if Ghostty is focused
- **THEN** it SHALL use `osascript` to query `System Events` for the frontmost application process name
- **AND** compare the result to "Ghostty"

#### Scenario: osascript failure defaults to not focused
- **WHEN** the osascript command fails or returns an unexpected value
- **THEN** the plugin SHALL assume Ghostty is NOT focused and proceed with the notification

### Requirement: TUI toast for subagent launches
The notifications plugin SHALL show a TUI toast inside the terminal when a subagent is launched, regardless of Ghostty focus state. This provides in-context awareness without requiring a system notification.

#### Scenario: Subagent launch shows TUI toast
- **WHEN** a `session.created` event fires with a `parentID`
- **THEN** a TUI toast SHALL be shown via `client.tui.showToast()` with message "<agentName> subagent launched"
- **AND** no macOS system notification SHALL be sent

#### Scenario: Session title populated from event
- **WHEN** a `session.created` event fires AND the event includes session info with a title
- **THEN** the session title SHALL be cached for use by other events

### Requirement: macOS notification on permission question
The notifications plugin SHALL send a macOS system notification when a permission question requires user input, but only if Ghostty is not focused.

#### Scenario: Permission question triggers notification
- **WHEN** a `permission.asked` event fires in opencode AND Ghostty is not focused
- **THEN** a macOS notification SHALL be sent with title "Agent - <dirname>" and message "Question needs your answer in <session title>"

#### Scenario: Permission question suppressed when focused
- **WHEN** a `permission.asked` event fires AND Ghostty is focused
- **THEN** no macOS system notification SHALL be sent

#### Scenario: Session title is resolved from cache or API
- **WHEN** a `permission.asked` event fires AND the session title is not in the cache
- **THEN** the plugin SHALL fetch the session title via `client.session.get()` and cache it

### Requirement: macOS notification on all tasks complete (root session only)
The notifications plugin SHALL send a macOS system notification when the root/parent session goes idle, but only if Ghostty is not focused. Subagent sessions going idle SHALL NOT trigger this notification.

#### Scenario: Root session idle triggers notification
- **WHEN** a `session.idle` event fires for a root session (no `parentID`) AND Ghostty is not focused
- **THEN** a macOS notification SHALL be sent with title "Agent - <dirname>" and message "All tasks complete in <session title>"

#### Scenario: Root session idle suppressed when focused
- **WHEN** a `session.idle` event fires for a root session AND Ghostty is focused
- **THEN** no macOS system notification SHALL be sent

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

### Requirement: Notification format includes project and session context
All system notifications SHALL include the project directory name in the title and the session title in the body.

#### Scenario: Title uses directory basename
- **WHEN** any system notification is sent
- **THEN** the title SHALL be "Agent - <basename(directory)>"

#### Scenario: Body includes session title
- **WHEN** any system notification is sent
- **THEN** the body SHALL end with "in <session title>"

#### Scenario: Session title fetch fails
- **WHEN** `client.session.get()` fails to return a session title
- **THEN** the plugin SHALL use "OpenCode" as the session title fallback

### Requirement: macOS notification on question asked
The notifications plugin SHALL send a macOS system notification when a question is asked, but only if Ghostty is not focused.

#### Scenario: Question asked triggers notification
- **WHEN** a `question.asked` event fires in opencode AND Ghostty is not focused
- **THEN** a macOS notification SHALL be sent with title "Agent - <dirname>" and message "New question asked in <session title>"

#### Scenario: Question asked suppressed when focused
- **WHEN** a `question.asked` event fires AND Ghostty is focused
- **THEN** no macOS system notification SHALL be sent

## REMOVED Requirements

### Requirement: macOS system notification for subagent launch
**Reason**: Replaced by TUI toast for in-context awareness. System notifications are now suppressed when Ghostty is focused, so subagent launches use TUI toasts instead.
**Migration**: Subagent launch notifications are now shown as TUI toasts via `client.tui.showToast()`.
