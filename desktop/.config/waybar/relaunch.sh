#!/usr/bin/env sh
set -eu

WAYBAR_DIR="${WAYBAR_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/waybar}"
LOG_FILE="${WAYBAR_LOG:-/tmp/waybar-relaunch.log}"
LOCK_DIR="${WAYBAR_RELAUNCH_LOCK:-/tmp/waybar-relaunch.lock}"

while ! mkdir "$LOCK_DIR" 2>/dev/null; do
  sleep 0.05
done
trap 'rmdir "$LOCK_DIR"' EXIT

pkill -x waybar >/dev/null 2>&1 || true

tries=0
while pgrep -x waybar >/dev/null 2>&1 && [ "$tries" -lt 20 ]; do
  tries=$((tries + 1))
  sleep 0.1
done

setsid waybar -c "$WAYBAR_DIR/config.jsonc" -s "$WAYBAR_DIR/style.css" >"$LOG_FILE" 2>&1 &
