## 1. Plugin implementation

- [x] 1.1 In `nix/modules/home/opencode.nix`, remove the `hiAdielPlugin` let-binding
      and its associated comment block.
- [x] 1.2 Add a new `subagentLaunchPlugin` let-binding whose `event` hook:
      - filters for `event.type === "session.created"`
      - reads `info` via `event.properties?.info ?? event.properties`
      - returns early if `!info?.parentID`
      - calls `client.tui.showToast({ body: { message: \`${info.agent ?? "Subagent"} Subagent launched\`, variant: "info" } })`
- [x] 1.3 Update the `xdg.configFile."opencode/plugins/hi-adiel.ts"` binding to
      `xdg.configFile."opencode/plugins/subagent-launch.ts"`, pointing at
      `subagentLaunchPlugin`.

## 2. Verification

- [x] 2.1 Rebuild home-manager / run the project's standard rebuild command.
- [x] 2.2 Confirm `~/.config/opencode/plugins/subagent-launch.ts` exists and
      `hi-adiel.ts` no longer exists (or is removed on next activation).
- [x] 2.3 Start a new opencode session and confirm no toast is shown on
      session creation.
- [x] 2.4 Trigger a Task tool subagent call (e.g. `explore` or `web-research`)
      and confirm a toast reading `"<agent-id> Subagent launched"` appears.

## 3. Archive

- [x] 3.1 Once verified, archive this change per the `openspec-archive-change`
      skill so the delta spec merges into `openspec/specs/opencode-agent-config/spec.md`.
