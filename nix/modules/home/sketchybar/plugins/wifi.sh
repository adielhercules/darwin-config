#!/usr/bin/env bash
# Wifi/Ethernet item plugin. Event-driven (wifi_change + mouse.clicked, no
# polling). Deliberately avoids the deprecated `airport` binary (confirmed
# removed on macOS 26/Tahoe) — Wi-Fi vs Ethernet vs disconnected is
# distinguished via `networksetup -getairportnetwork`'s exit code instead:
# it succeeds (with a network name, or "You are not associated...") on a
# genuine Wi-Fi interface, and fails outright ("... is not a Wi-Fi
# interface") on a wired/other interface.

source "$CONFIG_DIR/icons.sh"

update() {
  INTERFACE="$(route get default 2>/dev/null | awk '/interface:/{print $2}')"
  IP="$(ipconfig getifaddr "$INTERFACE" 2>/dev/null)"

  if AIRPORT_INFO="$(networksetup -getairportnetwork "$INTERFACE" 2>&1)"; then
    IS_WIFI=1
    SSID="$(echo "$AIRPORT_INFO" | sed -n 's/^Current Wi-Fi Network: //p')"
  else
    IS_WIFI=0
    SSID=""
  fi

  if [ "$IS_WIFI" = "1" ]; then
    if [ -n "$IP" ]; then
      ICON="$ICON_WIFI_CONNECTED"
      LABEL="${SSID:-Wi-Fi} ($IP)"
    else
      ICON="$ICON_WIFI_CONNECTED"
      LABEL="Disconnected"
    fi
  else
    if [ -n "$IP" ]; then
      ICON="$ICON_ETHERNET_CONNECTED"
      LABEL="Ethernet ($IP)"
    else
      ICON="$ICON_WIFI_CONNECTED"
      LABEL="Disconnected"
    fi
  fi

  sketchybar --set "$NAME" icon="$ICON" label="$LABEL"
}

click() {
  CURRENT_WIDTH="$(sketchybar --query "$NAME" | jq -r .label.width)"
  if [ "$CURRENT_WIDTH" = "0" ]; then
    WIDTH=dynamic
  else
    WIDTH=0
  fi
  sketchybar --animate sin 20 --set "$NAME" label.width="$WIDTH"
}

case "$SENDER" in
"wifi_change") update ;;
"mouse.clicked") click ;;
*) update ;;
esac
