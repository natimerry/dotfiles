#!/usr/bin/env sh
set -eu

WAYBAR_DIR="${WAYBAR_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/waybar}"
CONFIG_FILES="$WAYBAR_DIR/config.jsonc $WAYBAR_DIR/style.css $WAYBAR_DIR/wal.css"

trap 'pkill -x waybar >/dev/null 2>&1 || true' EXIT

while true; do
    setsid waybar -c "$WAYBAR_DIR/config.jsonc" -s "$WAYBAR_DIR/style.css" >/tmp/waybar-autores.log 2>&1 &
    inotifywait -e create,modify $CONFIG_FILES
    pkill -x waybar >/dev/null 2>&1 || true
    sleep 0.2
done
