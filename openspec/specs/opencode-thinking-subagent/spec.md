## ADDED Requirements

### Requirement: Thinking subagent exists
A `thinking` subagent SHALL be available for delegation from primary agents (`build`, `plan`).

#### Scenario: Thinking subagent is configured
- **WHEN** opencode starts with the deployed config
- **THEN** a `thinking` agent SHALL be registered with `mode: "subagent"`

#### Scenario: Thinking subagent has read-only permissions
- **WHEN** the `thinking` subagent is invoked
- **THEN** it SHALL have `allow` for `read`, `grep`, `glob`, `list`
- **AND** it SHALL have `deny` for `edit`, `bash`, `webfetch`, `websearch`

### Requirement: Primary agents can delegate to thinking
The `build` and `plan` primary agents SHALL have `thinking` in their allowed task delegation list.

#### Scenario: Build agent delegates to thinking
- **WHEN** the `build` agent needs complex reasoning or architectural analysis
- **THEN** it SHALL be able to spawn a `thinking` subagent via the Task tool

#### Scenario: Plan agent delegates to thinking
- **WHEN** the `plan` agent needs complex reasoning or architectural analysis
- **THEN** it SHALL be able to spawn a `thinking` subagent via the Task tool

### Requirement: Thinking subagent model is configurable
The `thinking` subagent SHALL inherit the primary agent's model by default, with a clear override option in `opencode.nix`.

#### Scenario: Default model inheritance
- **WHEN** no model override is specified in `opencode.nix`
- **THEN** the `thinking` subagent SHALL use the same model as the primary agent

#### Scenario: Model override
- **WHEN** a developer uncomments and sets `model = "headroom/claude-opus-4-6"` in the thinking agent config
- **THEN** the `thinking` subagent SHALL use the specified model after redeployment

### Requirement: Thinking subagent has a system prompt
The `thinking` subagent SHALL have a system prompt that instructs it to perform structured analysis without file modifications.

#### Scenario: Thinking subagent receives prompt
- **WHEN** a `thinking` subagent session is created
- **THEN** it SHALL receive instructions to read first, think structured, be concise, and avoid side effects
