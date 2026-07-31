#!/usr/bin/env bash
# sketchybar entrypoint (bash configType, see ../sketchybar/default.nix and
# design.md Decision 6). Static/WM-agnostic: both yabai's and AeroSpace's
# workspace-change events are registered unconditionally below (harmless if
# one of them never fires, since only one WM is ever enabled at build time —
# see nix/options/wm.nix) so this file doesn't need Nix templating for the
# event name. The workspace.sh plugin script itself IS Nix-templated per
# active WM (see default.nix), since only it needs to know which CLI to
# query.

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

# Explicitly loads Hack Nerd Font directly into sketchybar's CoreText
# context (see default.nix's loadFontSh) — sketchybar's own documented fix
# for missing icon glyphs, done regardless of whatever the OS font
# registry/ATS cache currently believes is installed.
source "$CONFIG_DIR/load_font.sh"

# Bar itself is fully transparent (alpha 0) — only the individual item
# "islands" below have a visible background, giving the floating-pill look
# requested. `padding_left`/`padding_right` here is the bar's own edge
# inset (space between the screen edge and the first/last island), not the
# gap between islands (that's each item's own padding_left/right below).
sketchybar --bar height=28 \
  position=top \
  sticky=on \
  padding_left=8 \
  padding_right=8 \
  color=0x00000000

# Every item gets a capsule-shaped background pill (corner_radius = half
# the pill height, i.e. a full capsule/stadium shape) using the same
# COLOR_ITEM_BG for all islands, plus padding_left/right which creates the
# small gap between adjacent islands (each pill "owns" this much empty,
# transparent space on either side of it).
sketchybar --default icon.font="Hack Nerd Font:Regular:14.0" \
  label.font="JetBrainsMono Nerd Font:Regular:13.0" \
  icon.color="$COLOR_FG" \
  label.color="$COLOR_FG" \
  background.drawing=on \
  background.color="$COLOR_ITEM_BG" \
  background.height=22 \
  background.corner_radius=11 \
  padding_left=4 \
  padding_right=4 \
  label.padding_left=8 \
  label.padding_right=8 \
  icon.padding_left=8 \
  icon.padding_right=8

# Custom events used to refresh the workspace indicator. Both are registered
# unconditionally; only the one matching the active WM will ever actually
# fire (yabai's `space_changed` signal / AeroSpace's `exec-on-workspace-change`
# each trigger only their own event — see yabai/default.nix and
# aerospace/main.toml).
sketchybar --add event yabai_space_change
sketchybar --add event aerospace_workspace_change

# Apple menu island — leftmost item on the bar.
source "$CONFIG_DIR/items/apple.sh"

sketchybar --add item workspace left \
  --set workspace script="$CONFIG_DIR/plugins/workspace.sh" \
  update_freq=2 \
  icon.drawing=off \
  label.color="$COLOR_ACCENT" \
  --subscribe workspace yabai_space_change aerospace_workspace_change

# Right side items, added in order so wifi is leftmost and clock is
# rightmost among the right-side group (matching native macOS menu-bar
# ordering).
source "$CONFIG_DIR/items/wifi.sh"

sketchybar --add item battery right \
  --set battery script="$CONFIG_DIR/plugins/battery.sh" \
  update_freq=60 \
  icon.drawing=off \
  label.color="$COLOR_FG"

sketchybar --add item clock right \
  --set clock script="$CONFIG_DIR/plugins/clock.sh" \
  update_freq=30 \
  icon.drawing=off \
  label.color="$COLOR_FG"

# Force an immediate refresh of every item on bar launch. This alone isn't
# fully reliable for the workspace item: sketchybar and yabai are both
# `RunAtLoad` launchd agents that start concurrently, so this initial
# trigger can fire before yabai's IPC socket is ready (confirmed live:
# "yabai-msg: failed to connect to socket.." during startup), leaving the
# label blank until the next real event. `workspace` is given a small
# `update_freq=2` above specifically so it self-heals from this race by
# simply retrying a couple seconds later, rather than staying blank
# forever — it's still event-driven in between polls via --subscribe.
# Both WM triggers are safe to fire unconditionally (harmless no-op for
# whichever WM isn't active); workspace.sh queries the active WM's current
# state regardless of which trigger woke it up.
sketchybar --trigger yabai_space_change
sketchybar --trigger aerospace_workspace_change

sketchybar --update
