## Why

The current opencode setup uses only the default bare-minimum global config
(`~/.config/opencode/opencode.jsonc` contains just the `$schema` key), with no
agent-oriented behavior tuning. This means research, file exploration, and web
lookups tend to run inline in the primary agent's conversation, cluttering the
main thread with intermediate tool output instead of delegating that work to
subagents. By configuring the primary `build` agent to proactively delegate
non-trivial work to subagents (`explore`, `scout`, `general`, and a new
web-research subagent), we get a cleaner main thread and faster, more modular
task execution — deployed declaratively through the existing Home Manager
setup so it's version-controlled and reproducible across machines.

## What Changes

- Add a new Home Manager module `nix/modules/home/opencode.nix` that generates
  `~/.config/opencode/opencode.jsonc` from a Nix attrset (`xdg.configFile."opencode/opencode.jsonc".text`)
- Configure the primary `build` agent's `prompt` to instruct it to delegate
  research, file exploration, and web-fetch tasks to subagents rather than
  performing them inline
- Define a new custom subagent for web research (webfetch/websearch enabled,
  edit denied), since the built-in `scout` subagent is scoped to dependency/library
  source inspection, not general web research
- Scope `permission.task` on the `build` agent to allow delegation to the
  built-in `explore`, `scout`, and `general` subagents plus the new custom
  web-research subagent
- Apply the same delegation `prompt` and `permission.task` scoping to the
  built-in `plan` primary agent, so planning sessions also delegate research/
  exploration/web-fetch work to subagents instead of doing it inline
- Add a global opencode plugin (`~/.config/opencode/plugins/hi-adiel.ts`) that
  shows a "Hi Adiel" toast notification on every new session, as a lightweight
  personalized greeting (OpenCode has no config/plugin primitive for a
  persistent custom TUI sidebar section, so a session-start toast via
  `client.tui.showToast` is the closest supported mechanism)
- Always import and enable the module (no feature flag) in `nix/darwin/home.nix`,
  matching the pattern of `rtk.nix`

## Capabilities

### New Capabilities

- `opencode-agent-config`: Home-Manager-managed opencode configuration that
  configures the primary agent to delegate research, file exploration, and
  web-fetch work to subagents, keeping the main conversation thread focused on
  orchestration and summaries. Also includes a personalized session-start
  greeting toast.

### Modified Capabilities

<!-- None -->

## Impact

- `nix/modules/home/opencode.nix` — new Home Manager module (generates config,
  no separate `.jsonc` file checked into the repo; config is expressed as a Nix
  attrset per the confirmed "option 2" design); also generates the
  `hi-adiel.ts` greeting plugin file via the same module
- `nix/darwin/home.nix` — add the new module to `imports`
- `~/.config/opencode/opencode.jsonc` — now Nix-managed (previously an untracked
  empty-ish global config); now includes `agent.plan` delegation config
  alongside `agent.build`
- `~/.config/opencode/plugins/hi-adiel.ts` — new Nix-managed global plugin file
  (separate from `rtk.ts`, which remains managed by `rtk.nix`'s activation
  script, not by this module)
- No conflict with the existing `rtk.nix` module, which only manages
  `~/.config/opencode/plugins/rtk.ts` and does not touch `opencode.jsonc`
