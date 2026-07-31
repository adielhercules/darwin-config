wifi=(
  padding_right=0
  padding_left=6
  label.width=0
  icon="$ICON_WIFI_CONNECTED"
  icon.font="Hack Nerd Font:Regular:14.0"
  script="$CONFIG_DIR/plugins/wifi.sh"
)

sketchybar --add item wifi right \
  --set wifi "${wifi[@]}" \
  --subscribe wifi wifi_change mouse.clicked
