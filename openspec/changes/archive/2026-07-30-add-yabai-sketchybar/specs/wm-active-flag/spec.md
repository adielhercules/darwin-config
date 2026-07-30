## ADDED Requirements

### Requirement: Build-time window manager selection flag
The system SHALL declare `lcars.wm.active` (`nix/options/wm.nix`) as an enum option (`"yabai"` | `"aerospace"`) with default `"yabai"`, following the existing `lcars.*` feature-flag convention (`nix/options/shell.nix`). Exactly one window manager SHALL be enabled at build/deploy time based on this flag's value — there SHALL be no runtime pause/resume mechanism.

#### Scenario: Default selects yabai
- **WHEN** `lcars.wm.active` is left at its default (or explicitly set to `"yabai"` in `nix/features.nix`)
- **THEN** `services.yabai.enable` evaluates to `true` and `programs.aerospace.enable`/`programs.aerospace.launchd.enable` evaluate to `false`

#### Scenario: Flipping to aerospace switches exclusively
- **WHEN** `lcars.wm.active` is set to `"aerospace"`
- **THEN** `services.yabai.enable` evaluates to `false` and `programs.aerospace.enable`/`programs.aerospace.launchd.enable` evaluate to `true`, with no manual coordination step required

#### Scenario: Flag is available in both darwin-system and home-manager contexts
- **WHEN** a darwin-system module (e.g. `nix/modules/darwin/yabai/default.nix`) or a home-manager module (e.g. `nix/modules/home/aerospace/default.nix`, `nix/modules/home/tuna/default.nix`) declares `lcars` as a module argument
- **THEN** `lcars.wm.active` resolves correctly in both contexts, via the existing `mkSpecialArgs` plumbing in `nix/darwin/default.nix` — no additional wiring is required beyond declaring the option
