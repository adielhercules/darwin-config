## Context

`nix/modules/darwin/yabai/default.nix` sets global yabai behavior via
`services.yabai.config` (rendered as `yabai -m config <k> <v>` lines). The
original `stack` layout choice was documented in
`openspec/changes/archive/2026-07-30-add-yabai-sketchybar/design.md` Decision
2, alongside `mouse_follows_focus = "on"`, which was a reasonable default
under `stack` since only one window is ever visible/focused per space at a
time.

## Goals / Non-Goals

**Goals:**
- Change the global default layout to `float` per explicit user request
- Turn off `mouse_follows_focus` since it becomes disruptive once multiple
  windows can be simultaneously visible/focused under `float`
- Clarify (comment-only) why the existing Simulator/Finder `manage=off` rules
  remain valuable even under a `float` default

**Non-Goals:**
- Changing `window_placement` (BSP-only, inert under `float`/`stack`) — left
  as-is
- Changing per-space layout override behavior/tooling (Tuna `y l` bindings
  already support switching a space's layout manually; unaffected)
- Any change to `work.nix` — confirmed no layout or mouse-focus content there

## Decisions

### Decision 1: Global default layout `float` (supersedes archived Decision 2)

Per explicit user request, `services.yabai.config.layout` changes from
`"stack"` to `"float"`. This makes all windows free-floating by default
(comparable to no tiling at all) rather than single-focused-stacked. Any
given space's layout can still be manually switched to `stack` or `bsp`
later via yabai's own `yabai -m space --layout <mode>` command (already
exposed through the Tuna `y l` submenu) — this change only affects the
*default*, not the mechanism for switching per-space.

### Decision 2: `mouse_follows_focus = off`

Under `stack`, exactly one window is ever focused/visible per space, so
warping the cursor to the newly focused window on every focus change was
unobtrusive. Under `float`, multiple windows can be visible and focus can
shift between them (e.g. via keyboard shortcuts) without the user's mouse
cursor "wanting" to move — warping it in that case is surprising/disruptive.
Turned off; `focus_follows_mouse` remains `off` as well (unchanged), so mouse
and keyboard focus remain fully decoupled in both directions.

### Decision 3: Simulator/Finder `manage=off` rules — comment clarification only

The existing rules are unchanged:
```
yabai -m rule --add app="^Simulator$" manage=off
yabai -m rule --add app="^Finder$" manage=off
```
Their purpose predates this change (excluding them from tiling regardless of
layout mode) and remains valid, but the rationale comment above them is
clarified: these rules stay valuable *specifically because* a space's layout
can still be manually overridden to `stack`/`bsp` later even though `float`
is now the global default — without them, Simulator/Finder would start
tiling again on any space a user switches away from `float`.

## Risks / Trade-offs

- **[Risk] `float` as a global default means no windows auto-tile anywhere
  unless a space is manually switched to `stack`/`bsp`** → acceptable, this is
  the explicit intent of the change; per-space override remains available via
  existing Tuna bindings.
- **[Low risk] `mouse_follows_focus = off` is a pure UX preference change** →
  no functional/config-plumbing risk, reversible by flipping the value back.

## Migration Plan

1. Update `services.yabai.config.layout` and `mouse_follows_focus` in
   `nix/modules/darwin/yabai/default.nix`, with comments reflecting the new
   rationale
2. Clarify the comment above the Simulator/Finder `manage=off` rules (no rule
   content change)
3. Update `openspec/specs/yabai-window-manager/spec.md`'s "yabai enabled by
   default" scenario to say `float` instead of `stack`, and note
   `mouse_follows_focus = off`
4. Run the mandatory post-apply validation sequence (flake check, `nix fmt`,
   `deadnix`, `statix`)

**Rollback**: revert `layout` to `"stack"` and `mouse_follows_focus` to
`"on"`, and revert the spec/comment wording changes.

## Open Questions

None.
