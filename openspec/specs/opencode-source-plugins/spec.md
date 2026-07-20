## ADDED Requirements

### Requirement: Plugin files are managed as source
Plugin `.ts` files SHALL be stored as editable source files in `config/opencode/plugins/` and deployed to `~/.config/opencode/plugins/` via Nix `xdg.configFile.source`.

#### Scenario: Plugin file is deployed from source
- **WHEN** `just deploy` is run
- **THEN** each `.ts` file in `config/opencode/plugins/` SHALL exist as a file (not symlink to Nix store) at `~/.config/opencode/plugins/<filename>.ts`

#### Scenario: Plugin source file is editable
- **WHEN** a developer edits `config/opencode/plugins/notifications.ts`
- **THEN** the change SHALL be reflected at `~/.config/opencode/plugins/notifications.ts` after the next `just deploy`

### Requirement: Agent definitions are managed as source
Agent `.md` files with frontmatter SHALL be stored in `config/opencode/agents/` and deployed to `~/.config/opencode/agents/` via Nix `xdg.configFile.source`.

#### Scenario: Agent file is deployed from source
- **WHEN** `just deploy` is run
- **THEN** each `.md` file in `config/opencode/agents/` SHALL exist at `~/.config/opencode/agents/<filename>.md`

#### Scenario: Agent frontmatter is preserved
- **WHEN** an agent `.md` file has frontmatter with `description`, `mode`, and `permission` fields
- **THEN** those fields SHALL be preserved exactly as written in the deployed file

### Requirement: opencode.jsonc generation is preserved
The `opencode.jsonc` file SHALL continue to be generated from a Nix attrset via `builtins.toJSON`, not from a source file.

#### Scenario: Config is generated from Nix
- **WHEN** `just deploy` is run
- **THEN** `~/.config/opencode/opencode.jsonc` SHALL contain valid JSON generated from the `opencodeConfig` attrset in `opencode.nix`
