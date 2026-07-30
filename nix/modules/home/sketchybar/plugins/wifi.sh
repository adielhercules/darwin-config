#!/usr/bin/env bash
# Wifi item plugin. Label-only (no icon glyph) — see battery.sh's comment
# for the rationale (SF Symbols codepoints deliberately deferred).
# `icon.drawing=off` is set for this item in sketchybarrc.sh accordingly.
#
# NOTE: `networksetup -getairportnetwork en0` was tried first but is
# unreliable on recent macOS versions — it can report "not associated"
# even when Wi-Fi is genuinely connected (confirmed live on this machine:
# en0 had a valid IP and was the active default-route interface, yet
# `networksetup -getairportnetwork` still claimed no association).
# `ipconfig getsummary en0`'s `SSID :` line is the reliable alternative.

SSID="$(ipconfig getsummary en0 2>/dev/null | awk -F ' : ' '/^[[:space:]]*SSID[[:space:]]*:/ {print $2}')"
if [ -z "$SSID" ]; then
  LABEL="Offline"
else
  LABEL="$SSID"
fi

sketchybar --set "$NAME" label="$LABEL"
