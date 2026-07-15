## Context

- OpenCode is installed via Homebrew, managed through this Nix-Darwin +
  Home Manager configuration (`nix/darwin/profiles/defaults.nix`).
- The current global opencode config at `~/.config/opencode/opencode.jsonc`
  is unmanaged and minimal (just `$schema`).
- Home Manager modules for user tooling live under `nix/modules/home/` and are
  wired up via the `imports` list in `nix/darwin/home.nix` (see `rtk.nix`,
  `helix.nix` for the established pattern).
- `rtk.nix` already touches the opencode ecosystem: it runs
  `rtk init -g --opencode --auto-patch` on activation, which installs a plugin
  file at `~/.config/opencode/plugins/rtk.ts`. It does not read or write
  `opencode.jsonc`, so there is no overlap with this change.
- OpenCode's real config schema (verified against https://opencode.ai/docs/config
  and https://opencode.ai/docs/agents) uses:
  - `agent` (singular) as the top-level key for agent definitions
  - `permission` (per-agent or global) with `edit`/`bash`/`webfetch`/`websearch`/
    `task`/etc. keys accepting `"allow" | "ask" | "deny"` (or glob-pattern maps)
  - `permission.task` to allowlist which subagents a primary agent may invoke
    via the Task tool
  - Built-in subagents: `general` (full tool access, parallel multi-step work),
    `explore` (read-only, fast codebase search), `scout` (read-only, external
    docs/dependency source inspection — not general web browsing)
  - No generic "collapse tool output" or "agents" (plural) config option exists;
    subagent isolation (child sessions) is inherent to how Task-tool invocation
    works and is not something this change needs to implement.
  - `plan` is another built-in primary agent (alongside `build`), configurable
    the same way under `agent.plan` — same `prompt`/`permission.task` shape.
  - OpenCode has no config or plugin primitive for a persistent custom TUI
    sidebar/panel (verified against https://opencode.ai/docs/tui and
    https://opencode.ai/docs/plugins). The closest supported mechanism is a
    plugin subscribing to the generic `event` hook and calling
    `client.tui.showToast({ body: { message, variant } })` (per
    https://opencode.ai/docs/sdk#tui) to show a transient toast — this is a
    per-event popup, not a persistent section.

## Goals / Non-Goals

**Goals:**
- The primary `build` agent proactively delegates research, file exploration,
  and web-fetch work to subagents instead of performing it inline.
- The primary `plan` agent gets the same delegation behavior as `build`, for
  parity across primary agents.
- A dedicated subagent exists for web research, since no built-in subagent
  covers general web browsing/fetching.
- The entire config is generated declaratively from Nix and deployed via
  `just deploy` — no manual edits to `~/.config/opencode/opencode.jsonc`.
- The module is always enabled, with no feature flag, consistent with `rtk.nix`.
- A lightweight personalized greeting appears at the start of every new
  opencode session.

**Non-Goals:**
- Building a custom mechanism to hide/collapse tool output on the main thread.
  This is inherent to subagent child-session behavior in OpenCode and requires
  no additional configuration.
- Changing MCP servers, LSP servers, formatters, or other unrelated opencode
  config domains.
- Modifying the Helix `"C-a"` opencode launch keybinding.
- Building a persistent custom TUI sidebar/panel — not supported by OpenCode
  today (see Context). The greeting is delivered as a session-start toast
  instead.

## Decisions

1. **Config expressed as an inline Nix attrset, not a checked-in `.jsonc` file**
   - Uses `xdg.configFile."opencode/opencode.jsonc".text = builtins.toJSON { ... }`
     inside `nix/modules/home/opencode.nix`.
   - Matches the existing convention in this repo (e.g. `fish.nix` inlines its
     config directly in Nix rather than referencing a separate dotfile).
   - Trade-off: JSONC comments are lost since `builtins.toJSON` emits plain
     JSON. Mitigated by documenting intent with Nix `#` comments in the module
     itself, which is more useful anyway since that's where the config is
     authored and reviewed.

2. **Delegate via `prompt` + `permission.task`, not a fabricated "tools" array**
   - The `build` agent's `prompt` field is overridden with instructions to
     prefer delegating research/exploration/web-fetch tasks to subagents.
   - `permission.task` on `build` is scoped to explicitly allow the built-in
     `explore`, `scout`, `general` subagents plus the new custom web-research
     subagent, and deny everything else by default (`"*": "deny"` first, then
     specific allows — last matching rule wins per OpenCode's evaluation order).
   - Delegation is prompt-driven (best-effort LLM behavior), not a hard
     enforcement mechanism — there is no config primitive in OpenCode to force
     tool calls into subagents mechanically.
   - The same `prompt` string and `permission.task` allowlist are applied to
     `agent.plan`, factored into a single shared Nix `let` binding so both
     primary agents stay in sync without duplicating the instruction text.

3. **New custom subagent: `web-research`**
   - `mode: "subagent"`, `permission: { webfetch: "allow", websearch: "allow", edit: "deny", bash: "deny" }`.
   - Needed because `scout` is scoped to dependency/library source inspection
     (clone + inspect upstream repos), not general web browsing or documentation
     lookups.

4. **Module always enabled, no feature flag**
   - Confirmed with user: no `lcars.opencode.agentMode.enable` toggle in
     `features.nix`. The module behaves like `rtk.nix` — unconditionally active
     once imported.

5. **Session-start greeting via a dedicated plugin, not a config field**
   - No `opencode.jsonc` field can render custom persistent UI, so the
     greeting is implemented as a new global plugin,
     `~/.config/opencode/plugins/hi-adiel.ts`, generated by the same
     `opencode.nix` module via `xdg.configFile."opencode/plugins/hi-adiel.ts".text`.
   - The plugin subscribes to the generic `event` hook, filters for
     `event.type === "session.created"`, and calls
     `client.tui.showToast({ body: { message: "Hi Adiel", variant: "info" } })`.
   - Fires on **every** new session (not deduped by day or one-time), per
     user preference — matches the session-scoped nature of OpenCode.
   - Kept as a separate file from `rtk.ts` (which is managed by `rtk.nix`'s
     activation script, not by this module) to avoid any coupling between the
     two plugin sources; OpenCode loads all files in the plugins directory
     independently, so both coexist without conflict.

## Risks / Trade-offs

- [Delegation is advisory, not enforced] → Mitigation: keep `permission.task`
  scoped tightly so only intended subagents are reachable, and document the
  expected behavior in the module's Nix comments for future maintainers.
- [Lost JSONC comments in generated config] → Mitigation: comments live in the
  Nix module source instead, which is the actual source of truth developers
  will edit.
- [Schema drift if OpenCode changes config format] → Mitigation: `$schema`
  field is retained in the generated JSON so editors/tools can still validate
  against the live schema at `https://opencode.ai/config.json`.
- [Toast fires on every session, could feel noisy over time] → Accepted
  trade-off per explicit user preference; easy to change later to a
  once-per-day/once-ever dedupe if desired (would require persisting state to
  a file under the plugin's control).
