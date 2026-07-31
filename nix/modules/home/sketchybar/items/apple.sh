#!/usr/bin/env bash
# Apple menu island — leftmost item on the bar. Click toggles a popup with
# a handful of common macOS system actions (About This Mac, Preferences,
# Lock Screen, Log Out, Restart, Shut Down), mirroring the native macOS
# Apple menu. Icons are sourced from icons.sh.

POPUP_OFF='sketchybar --set apple.logo popup.drawing=off'

apple_logo=(
  icon="$ICON_APPLE"
  icon.font="Hack Nerd Font:Regular:16.0"
  label.drawing=off
  popup.height=30
  popup.background.color="$COLOR_ITEM_BG"
  popup.background.border_color="$COLOR_BG"
  popup.background.border_width=1
  popup.background.corner_radius=8
  click_script="sketchybar --set apple.logo popup.drawing=toggle"
)

apple_this_mac=(
  icon="$ICON_INFO"
  icon.font="Hack Nerd Font:Regular:14.0"
  label="This Mac"
  click_script="open /System/Library/CoreServices/'About This Mac.app'; $POPUP_OFF"
)

apple_prefs=(
  icon="$ICON_PREFERENCES"
  icon.font="Hack Nerd Font:Regular:14.0"
  label="Preferences"
  click_script="open -a 'System Settings'; $POPUP_OFF"
)

apple_lock=(
  icon="$ICON_LOCK"
  icon.font="Hack Nerd Font:Regular:14.0"
  label="Lock Screen"
  click_script="pmset displaysleepnow; $POPUP_OFF"
)

apple_logout=(
  icon="$ICON_LOGOUT"
  icon.font="Hack Nerd Font:Regular:14.0"
  label="Log Out"
  click_script="osascript -e 'tell application \"System Events\" to log out'; $POPUP_OFF"
)

apple_restart=(
  icon="$ICON_RESTART"
  icon.font="Hack Nerd Font:Regular:14.0"
  label="Restart"
  click_script="osascript -e 'tell application \"System Events\" to restart'; $POPUP_OFF"
)

apple_shutdown=(
  icon="$ICON_POWER"
  icon.font="Hack Nerd Font:Regular:14.0"
  label="Shut Down"
  click_script="osascript -e 'tell application \"System Events\" to shut down'; $POPUP_OFF"
)

sketchybar --add item apple.logo left \
  --set apple.logo "${apple_logo[@]}" \
  --add item apple.this_mac popup.apple.logo \
  --set apple.this_mac "${apple_this_mac[@]}" \
  --add item apple.prefs popup.apple.logo \
  --set apple.prefs "${apple_prefs[@]}" \
  --add item apple.lock popup.apple.logo \
  --set apple.lock "${apple_lock[@]}" \
  --add item apple.logout popup.apple.logo \
  --set apple.logout "${apple_logout[@]}" \
  --add item apple.restart popup.apple.logo \
  --set apple.restart "${apple_restart[@]}" \
  --add item apple.shutdown popup.apple.logo \
  --set apple.shutdown "${apple_shutdown[@]}"
