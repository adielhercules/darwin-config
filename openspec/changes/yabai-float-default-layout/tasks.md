## 1. Config changes

- [x] 1.1 `nix/modules/darwin/yabai/default.nix`: change `layout = "stack";` to
  `layout = "float";`, updating the inline comment to explain the new
  free-floating-by-default rationale (per-space override to `stack`/`bsp`
  still possible)
- [x] 1.2 `nix/modules/darwin/yabai/default.nix`: change
  `mouse_follows_focus = "on";` to `mouse_follows_focus = "off";`, with a
  comment explaining this avoids disruptive cursor warping now that multiple
  windows can be visible/focused under `float` (was fine under `stack`'s
  single-focused-window model)
- [x] 1.3 Leave `window_placement = "second_child";` unchanged
- [x] 1.4 Clarify (comment-only) the rationale above the
  `app="^Simulator$"`/`app="^Finder$"` `manage=off` rules: kept explicit so
  Simulator/Finder always float even if a space's layout is later manually
  overridden to `stack`/`bsp`, independent of the new global `float` default —
  do not change the rule lines themselves
- [x] 1.5 Confirm `nix/modules/darwin/yabai/work.nix` needs no changes

## 2. Spec update

- [x] 2.1 `openspec/specs/yabai-window-manager/spec.md`: update the
  "yabai enabled by default" scenario under "yabai enabled conditionally via
  the build-time WM flag" to say `float` layout instead of `stack`, and note
  `mouse_follows_focus = off`

## 3. Validation

- [x] 3.1 `git add nix/`
- [x] 3.2 `nix flake check --no-build ./nix`
- [x] 3.3 `nix fmt`
- [x] 3.4 `deadnix --fail .`
- [x] 3.5 `statix check .`
- [ ] 3.6 `just check` — intentionally not run by the AI agent (requires
  sudo, per repo rules); run manually when ready
