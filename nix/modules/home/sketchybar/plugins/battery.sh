#!/usr/bin/env bash
# Battery item plugin.
#
# NOTE: SF Symbols/SF Pro private-use-area codepoints for battery-level
# glyphs (charging bolt, level tiers, etc.) were deliberately NOT hardcoded
# here — they could not be confidently verified during this change (see
# openspec/changes/archive/2026-07-30-add-yabai-sketchybar/tasks.md, task
# group 9 notes), and guessing unicode codepoints risks silently rendering
# garbage/tofu glyphs.
# This script is label-only: just the percentage, plus a plain, universally
# renderable unicode bolt (U+26A1 "⚡", a standard emoji character, NOT an
# SF-Symbols guess) appended when charging. `icon.drawing=off` is set for
# this item in sketchybarrc.sh accordingly. Revisit with visual
# verification if battery-level icons are wanted later.

BATT_INFO="$(pmset -g batt)"
PERCENT="$(echo "$BATT_INFO" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')"
CHARGING="no"
if echo "$BATT_INFO" | grep -q 'AC Power'; then
  CHARGING="yes"
fi

LABEL="${PERCENT}%"
if [ "$CHARGING" = "yes" ]; then
  LABEL="${LABEL} ⚡"
fi

sketchybar --set "$NAME" label="$LABEL"
