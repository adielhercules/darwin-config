# opencode-agent-config

Home-Manager-managed opencode configuration that configures primary agents to
delegate research, file exploration, and web-fetch work to subagents, and
provides a personalized session-start greeting toast.

---

### Requirement: Primary agent delegates non-trivial work to subagents
The `build` primary agent's system prompt MUST instruct it to delegate research,
multi-file exploration, and web-fetch/lookup tasks to subagents rather than
performing them inline in the main conversation.

#### Scenario: User asks a research-heavy question
- **WHEN** the user asks a question that requires searching across multiple
  files or exploring unfamiliar parts of the codebase
- **THEN** the `build` agent invokes the `explore` or `general` subagent to
  perform the search and returns only the relevant findings to the main thread

#### Scenario: User asks for external documentation or web lookup
- **WHEN** the user asks the agent to look up external documentation, a
  library's behavior, or fetch a URL
- **THEN** the `build` agent invokes the `web-research` subagent (or `scout`
  for dependency source inspection) instead of calling `webfetch`/`websearch`
  directly from the main thread

### Requirement: Custom web-research subagent exists
The system MUST define a `web-research` subagent scoped to web content lookup,
since the built-in `scout` subagent only covers dependency/library source
inspection, not general web browsing.

#### Scenario: Web-research subagent has correct permissions
- **WHEN** the `web-research` subagent is invoked
- **THEN** it has `webfetch: "allow"` and `websearch: "allow"` permissions,
  and `edit: "deny"` / `bash: "deny"` permissions, so it can only fetch/browse
  and cannot modify the workspace or run shell commands

### Requirement: Task delegation is scoped via permission.task
The `build` agent's `permission.task` configuration MUST explicitly allowlist
which subagents it can invoke, denying all others by default.

#### Scenario: Allowed subagents are reachable
- **WHEN** the `build` agent attempts to invoke `explore`, `scout`, `general`,
  or `web-research` via the Task tool
- **THEN** the invocation succeeds because each is explicitly allowed in
  `permission.task`

#### Scenario: Unlisted subagents are unreachable via Task tool
- **WHEN** the `build` agent attempts to invoke any subagent not explicitly
  allowlisted
- **THEN** the invocation is denied because `permission.task` defaults to
  `"*": "deny"` before the specific allow rules

### Requirement: Configuration is generated and deployed via Home Manager
The entire opencode agent configuration MUST be expressed as a Nix attrset in
a Home Manager module and deployed to `~/.config/opencode/opencode.jsonc`
without any manually maintained JSON/JSONC file checked into the repo.

#### Scenario: Running just deploy applies the configuration
- **WHEN** the user runs `just deploy` (which runs
  `darwin-rebuild switch --flake ... --impure`)
- **THEN** `~/.config/opencode/opencode.jsonc` is generated from
  `nix/modules/home/opencode.nix` and reflects the current agent/prompt/
  permission configuration

#### Scenario: Module is always enabled
- **WHEN** the Home Manager configuration is built
- **THEN** the opencode module is active unconditionally, with no feature
  flag required to enable it, consistent with the existing `rtk.nix` module

### Requirement: Module is imported into the Darwin home configuration
The new `nix/modules/home/opencode.nix` module MUST be added to the `imports`
list in `nix/darwin/home.nix` so it is included in every profile build.

#### Scenario: Module is present in the imports list
- **WHEN** inspecting `nix/darwin/home.nix`
- **THEN** `../modules/home/opencode.nix` appears in the `imports` list
  alongside the other home modules (e.g. `rtk.nix`, `helix.nix`)

### Requirement: Plan agent delegates non-trivial work to subagents
The `plan` primary agent MUST be configured with the same delegation `prompt`
and `permission.task` allowlist as the `build` agent, so planning sessions
also delegate research, multi-file exploration, and web-fetch/lookup work to
subagents instead of performing them inline.

#### Scenario: Plan agent prompt matches build agent's delegation instructions
- **WHEN** inspecting the generated `agent.plan.prompt` in
  `~/.config/opencode/opencode.jsonc`
- **THEN** it contains the same delegate-to-subagents instructions as
  `agent.build.prompt` (sourced from a single shared Nix binding)

#### Scenario: Plan agent's task permissions match build agent's
- **WHEN** inspecting the generated `agent.plan.permission.task` in
  `~/.config/opencode/opencode.jsonc`
- **THEN** it allows `explore`, `scout`, `general`, and `web-research` and
  denies all other subagents by default (`"*": "deny"`), matching
  `agent.build.permission.task`

### Requirement: Session-start greeting toast
The system MUST show a personalized "Hi Adiel" toast notification via a
global opencode plugin every time a new session is created, since OpenCode
has no config or plugin primitive for a persistent custom TUI sidebar
section.

#### Scenario: Toast fires on new session creation
- **WHEN** a new opencode session is created (e.g. via `/new` or a fresh
  `opencode` launch)
- **THEN** the `hi-adiel` plugin's `session.created` event handler calls
  `client.tui.showToast({ body: { message: "Hi Adiel", variant: "info" } })`

#### Scenario: Toast fires on every session, not deduplicated
- **WHEN** multiple new sessions are created in sequence (e.g. repeated
  `/new` commands)
- **THEN** the toast is shown again for each new session, with no
  once-per-day or once-ever deduplication

#### Scenario: Greeting plugin coexists with rtk's plugin
- **WHEN** both `~/.config/opencode/plugins/hi-adiel.ts` (managed by
  `opencode.nix`) and `~/.config/opencode/plugins/rtk.ts` (managed by
  `rtk.nix`'s activation script) are present
- **THEN** both plugins load independently without conflict, since OpenCode
  loads all files in the plugins directory separately
