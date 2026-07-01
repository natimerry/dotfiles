#!/usr/bin/env sh
set -eu

ROFI="${ROFI:-rofi}"

has() {
  command -v "$1" >/dev/null 2>&1
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

wifi_enabled() {
  [ "$(nmcli -t -f WIFI general 2>/dev/null | sed -n '1p')" = "enabled" ]
}

active_wifi() {
  nmcli -t --escape no -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null |
    awk -F: '$1 == "yes" { print $2 "\t" $3; exit }'
}

status() {
  if ! has nmcli; then
    printf '{"text":"WiFi","tooltip":"nmcli is not installed","class":"disabled"}\n'
    return 0
  fi

  if ! wifi_enabled; then
    printf '{"text":"WiFi off","tooltip":"Wi-Fi is disabled","class":"disabled"}\n'
    return 0
  fi

  active="$(active_wifi || true)"
  if [ -n "$active" ]; then
    ssid="$(printf '%s' "$active" | awk -F '\t' '{print $1}')"
    signal="$(printf '%s' "$active" | awk -F '\t' '{print $2}')"
    short="$ssid"
    if [ "$(printf '%s' "$short" | wc -c)" -gt 18 ]; then
      short="$(printf '%s' "$short" | cut -c 1-17)…"
    fi
    printf '{"text":"WiFi %s","tooltip":"Connected to %s (%s%%)","class":"connected"}\n' \
      "$(json_escape "$short")" "$(json_escape "$ssid")" "$(json_escape "$signal")"
  else
    printf '{"text":"WiFi","tooltip":"Disconnected. Click to pick a network.","class":"disconnected"}\n'
  fi
}

rofi_menu() {
  prompt="$1"
  if ! has "$ROFI"; then
    echo "rofi is not installed" >&2
    exit 1
  fi
  "$ROFI" -dmenu -i -p "$prompt"
}

ask_password() {
  ssid="$1"
  "$ROFI" -dmenu -password -p "Password for $ssid"
}

network_choices() {
  {
    if wifi_enabled; then
      echo "Toggle WiFi off"
      echo "Disconnect"
    else
      echo "Toggle WiFi on"
    fi
    echo "Rescan"
    nmcli -t --escape no -f SSID,SIGNAL,SECURITY dev wifi list --rescan yes 2>/dev/null |
      awk -F: '$1 != "" && !seen[$1]++ {
        security = $3 == "" ? "open" : $3
        printf "%s  %s%%  %s\n", $1, $2, security
      }'
  } | rofi_menu "WiFi"
}

connect_network() {
  choice="$1"
  ssid="$(printf '%s' "$choice" | sed 's/  [0-9][0-9]*%  .*$//')"
  [ -n "$ssid" ] || exit 0

  security="$(printf '%s' "$choice" | sed 's/^.*  [0-9][0-9]*%  //')"
  if [ "$security" = "open" ]; then
    nmcli dev wifi connect "$ssid"
  else
    if nmcli connection show "$ssid" >/dev/null 2>&1; then
      nmcli connection up "$ssid"
    else
      password="$(ask_password "$ssid")"
      [ -n "$password" ] || exit 0
      nmcli dev wifi connect "$ssid" password "$password"
    fi
  fi
}

pick() {
  if ! has nmcli; then
    echo "nmcli is not installed" >&2
    exit 1
  fi

  choice="$(network_choices || true)"
  [ -n "$choice" ] || exit 0

  case "$choice" in
    "Toggle WiFi off")
      nmcli radio wifi off
      ;;
    "Toggle WiFi on")
      nmcli radio wifi on
      ;;
    "Disconnect")
      nmcli device disconnect "$(nmcli -t -f DEVICE,TYPE dev status | awk -F: '$2 == "wifi" { print $1; exit }')" || true
      ;;
    "Rescan")
      nmcli dev wifi rescan || true
      pick
      ;;
    *)
      connect_network "$choice"
      ;;
  esac
}

case "${1:-status}" in
  status) status ;;
  pick) pick ;;
  *) echo "Usage: wifi-rofi.sh [status|pick]" >&2; exit 2 ;;
esac
