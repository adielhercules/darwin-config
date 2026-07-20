## 1. Delete subagent-launch plugin

- [x] 1.1 Delete `config/opencode/plugins/subagent-launch.ts`
- [x] 1.2 Remove `xdg.configFile."opencode/plugins/subagent-launch.ts"` entry from `nix/modules/home/opencode.nix` (lines 144-145)
- [x] 1.3 Update directory layout comment in `nix/modules/home/opencode.nix` (lines 20-21) to remove `subagent-launch.ts` reference

## 2. Rewrite notifications plugin

- [x] 2.1 Update plugin signature to accept `directory` from `PluginInput`: `async ({ directory }) => {`
- [x] 2.2 Add session title cache: `const sessionTitles = new Map<string, string>()`
- [x] 2.3 Add `-activate com.mitchellh.ghostty` to `terminal-notifier` args in `sendNotification()`
- [x] 2.4 Fix typo: `sendNotifiction` → `sendNotification` on line 52
- [x] 2.5 Update `session.created` handler: cache session title from `event.properties.info`, use `sendNotification("Agent - ...", ...)` format
- [x] 2.6 Update `permission.asked` handler: fetch session title via `client.session.get()`, use new notification format
- [x] 2.7 Add `question.asked` event handler with notification
- [x] 2.8 Update `session.idle` handler: use new notification format with session title
- [x] 2.9 Update header comment to reflect all triggers and removal of subagent-launch

## 3. Update Nix deployment

- [x] 3.1 Update `nix/modules/home/opencode.nix` comment block to remove subagent-launch.ts from directory layout

## 4. Validate

- [x] 4.1 Run `nix fmt` to format the modified files
- [x] 4.2 Run `just check` to validate the configuration builds
