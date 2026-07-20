## MODIFIED Requirements

### Requirement: Plugin files are managed as source
Plugin `.ts` files SHALL be stored as editable source files in `config/opencode/plugins/` and deployed to `~/.config/opencode/plugins/` via Nix `xdg.configFile.source`.

#### Scenario: Plugin file is deployed from source
- **WHEN** `just deploy` is run
- **THEN** each `.ts` file in `config/opencode/plugins/` SHALL exist as a file (not symlink to Nix store) at `~/.config/opencode/plugins/<filename>.ts`

#### Scenario: Plugin source file is editable
- **WHEN** a developer edits `config/opencode/plugins/notifications.ts`
- **THEN** the change SHALL be reflected at `~/.config/opencode/plugins/notifications.ts` after the next `just deploy`

## REMOVED Requirements

### Requirement: subagent-launch plugin is deployed as source
**Reason**: `subagent-launch.ts` has been removed and consolidated into `notifications.ts`.
**Migration**: Subagent launch notifications are now handled by the notifications plugin. The `subagent-launch.ts` file and its Nix deployment entry are removed.
