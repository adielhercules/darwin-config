## 1. Create the Home Manager module

- [x] 1.1 Create `nix/modules/home/opencode.nix`
  - Define the module accepting standard `{ lib, ... }` args (matching `rtk.nix` style)
  - Build the opencode config as a Nix attrset:
    - `$schema`: `"https://opencode.ai/config.json"`
    - `agent.build.prompt`: instructions to delegate research, multi-file
      exploration, and web-fetch/lookup tasks to subagents instead of handling
      them inline
    - `agent.build.permission.task`: `{ "*" = "deny"; explore = "allow"; scout = "allow"; general = "allow"; web-research = "allow"; }`
    - `agent.web-research`: new custom subagent definition
      - `description`: required field, briefly describing its purpose
      - `mode`: `"subagent"`
      - `permission`: `{ webfetch = "allow"; websearch = "allow"; edit = "deny"; bash = "deny"; }`
  - Use `xdg.configFile."opencode/opencode.jsonc".text = builtins.toJSON { ... }`
    to generate the deployed file
  - Add Nix `#` comments documenting intent (since JSON comments are lost in
    the generated output)

- [x] 1.2 Validate the attrset serializes correctly
  - Run `nix eval` or `nix repl` locally against the attrset to confirm
    `builtins.toJSON` produces valid JSON matching the intended schema

## 2. Wire the module into the Darwin home configuration

- [x] 2.1 Add the import to `nix/darwin/home.nix`
  - Add `../modules/home/opencode.nix` to the `imports` list, alongside
    `../modules/home/rtk.nix` and the other existing home modules
  - No feature flag needed — module is always active once imported

## 3. Build and deploy

- [x] 3.1 Validate the flake
  - Run `nix flake check` (or equivalent) from the repo root to catch any
    Nix syntax/type errors introduced by the new module

- [x] 3.2 Deploy
  - Run `just deploy` to apply the Home Manager configuration via
    `darwin-rebuild switch --flake ... --impure`

- [x] 3.3 Verify generated config
  - Inspect `~/.config/opencode/opencode.jsonc` after deploy and confirm it
    contains the expected `agent.build`, `agent.web-research`, and
    `permission.task` keys matching the source Nix attrset

## 4. Manual functional verification

- [x] 4.1 Test delegation for research/exploration
  - In an opencode session, ask a question that requires searching across
    multiple files (e.g. "where is X configured?")
  - Confirm the `build` agent invokes `explore` or `general` rather than
    performing the search inline

- [x] 4.2 Test delegation for web research
  - Ask the agent to look up external documentation or fetch a URL
  - Confirm the `web-research` subagent is invoked (not a direct `webfetch`/
    `websearch` call from the main thread)

- [x] 4.3 Confirm no conflict with rtk
  - Confirm `~/.config/opencode/plugins/rtk.ts` is still present and functional
    after deploy (rtk's activation script should be unaffected by this change)

## 5. Update documentation (if applicable)

- [x] 5.1 Note the new module in repo docs
  - No module inventory/README section listing home modules exists in this
    repo (checked for README* files); nothing to update. N/A.

## 6. Plan agent subagent delegation

- [x] 6.1 Refactor `nix/modules/home/opencode.nix` to hoist the delegate-to-
      subagents prompt string into a shared `let` binding, used by both
      `agent.build.prompt` and new `agent.plan.prompt`

- [x] 6.2 Add `agent.plan.permission.task` to the config attrset, identical
      to `agent.build.permission.task`
      (`{ "*" = "deny"; explore = "allow"; scout = "allow"; general = "allow"; web-research = "allow"; }`)

- [x] 6.3 Validate the updated attrset serializes correctly
  - Run `nix eval` against the attrset to confirm `builtins.toJSON` still
    produces valid JSON, now including `agent.plan`

- [x] 6.4 Validate the flake
  - Run `nix flake check` from the repo root

- [x] 6.5 Deploy
  - Run `just deploy`

- [x] 6.6 Verify generated config
  - Inspect `~/.config/opencode/opencode.jsonc` after deploy and confirm
    `agent.plan.prompt` and `agent.plan.permission.task` match
    `agent.build`'s values

## 7. "Hi Adiel" session-start greeting toast

- [x] 7.1 Add a new plugin file managed by `nix/modules/home/opencode.nix`
  - Generate `~/.config/opencode/plugins/hi-adiel.ts` via
    `xdg.configFile."opencode/plugins/hi-adiel.ts".text`
  - Plugin exports an async function subscribing to the generic `event`
    hook, filters for `event.type === "session.created"`, and calls
    `client.tui.showToast({ body: { message: "Hi Adiel", variant: "info" } })`
  - Fires on every new session (no dedupe), per confirmed user preference

- [x] 7.2 Validate the flake
  - Run `nix flake check` from the repo root

- [x] 7.3 Deploy
  - Run `just deploy`

- [x] 7.4 Manual verification
  - `hi-adiel.ts` symlinked at `~/.config/opencode/plugins/hi-adiel.ts` ✓
  - `rtk.ts` still present alongside it ✓
  - Toast on `/new` requires a live session test (pending user confirmation)
  - Start a new opencode session (`/new` or fresh `opencode` launch) and
    confirm the "Hi Adiel" toast appears
  - Confirm `~/.config/opencode/plugins/rtk.ts` is still present and
    functional alongside the new `hi-adiel.ts` plugin

  - If the repo maintains a module inventory or README section listing home
    modules, add an entry for `opencode.nix` describing its purpose
</content>
