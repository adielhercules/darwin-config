## Why

yabai currently defaults to `stack` layout (single focused window per space, per
`openspec/changes/archive/2026-07-30-add-yabai-sketchybar/design.md` Decision 2).
Per explicit user request, the default should instead be `float`: windows should
be free-floating by default rather than tiled/stacked. Individual spaces can
still be manually switched to `stack` or `bsp` later via yabai's per-space
layout controls — that capability is unaffected by this change.

Additionally, `mouse_follows_focus = "on"` was fine under `stack`'s
single-focused-window model (only one window is ever visible/focused per
space), but under `float` multiple windows can be visible/focused
simultaneously, so cursor-warping on every focus change becomes disruptive.
This change turns it off.

## What Changes

- `nix/modules/darwin/yabai/default.nix`: `services.yabai.config.layout` changes
  from `"stack"` to `"float"`; inline comment updated to explain the new
  rationale (free-floating default; per-space override to `stack`/`bsp` still
  possible)
- `nix/modules/darwin/yabai/default.nix`: `services.yabai.config.mouse_follows_focus`
  changes from `"on"` to `"off"`; inline comment updated to explain why (avoids
  disruptive cursor warping now that multiple windows can be visible/focused
  under `float`)
- `nix/modules/darwin/yabai/default.nix`: the comment above the existing
  `app="^Simulator$"`/`app="^Finder$"` `manage=off` rules is clarified to note
  these rules are kept explicit on purpose (so Simulator/Finder always float
  even if a space's layout is later manually overridden to `stack`/`bsp`),
  independent of the new global `float` default — the rule lines themselves
  are unchanged
- `window_placement = "second_child"` is left unchanged (inert/BSP-only
  setting, out of scope)
- `nix/modules/darwin/yabai/work.nix` is unchanged — confirmed no
  layout/mouse-focus-related content there

## Capabilities

### Modified Capabilities
- `yabai-window-manager`: default layout changes from `stack` to `float`;
  `mouse_follows_focus` changes from `on` to `off`

## Impact

- **`nix/modules/darwin/yabai/default.nix`**: two `config` value changes plus
  three comment updates (layout, mouse_follows_focus, and the
  Simulator/Finder rule-comment clarification)
- **`openspec/specs/yabai-window-manager/spec.md`**: update the
  "yabai enabled by default" scenario to reflect `float` layout instead of
  `stack`, and note `mouse_follows_focus = off`
