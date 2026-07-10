#!/usr/bin/env sh
set -eu

MODE="${1:-sync}"

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
PATH="$HOME/.local/bin:$HOME/.local/share/pipx/venvs/wpgtk/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export PATH

WAL_DIR="$CACHE_HOME/wal"
COLORS_SH="$WAL_DIR/colors.sh"
WPG_WALLPAPER_DIR="$CONFIG_HOME/wpg/wallpapers"
LOG_DIR="$CACHE_HOME/waybar"
LOG_FILE="$LOG_DIR/wpg-sync-theme.log"

WAYBAR_DIR="${WAYBAR_DIR:-$CONFIG_HOME/waybar}"
ALACRITTY_COLORS="${ALACRITTY_COLORS:-$CONFIG_HOME/alacritty/colors.toml}"

ROFI_COLORS="$CONFIG_HOME/rofi/wallust/colors-rofi.rasi"

has() {
  command -v "$1" >/dev/null 2>&1
}

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

setup_logging() {
  mkdir -p "$LOG_DIR"
  exec >>"$LOG_FILE" 2>&1
  printf '\n[%s] %s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$0" "$MODE"
}

run_sync() {
  load_colors
  sync_waybar
  sync_alacritty
  sync_rofi
  restart_waybar

  printf '%s\n' "Synced wpg colours to Waybar, Alacritty, and Rofi"
}

load_colors() {
  [ -r "$COLORS_SH" ] ||
    die "Missing $COLORS_SH. Run wpg successfully first."

  # shellcheck disable=SC1090
  . "$COLORS_SH"
}

rgb() {
  hex="${1#\#}"

  [ "${#hex}" -eq 6 ] ||
    die "Invalid colour value: $1"

  r="${hex%????}"
  gb="${hex#??}"
  g="${gb%??}"
  b="${hex#????}"

  printf '%d,%d,%d' "0x$r" "0x$g" "0x$b"
}

get_current_wallpaper() {
  has waypaper || die "waypaper is not installed"
  has jq || die "jq is required to read waypaper's active wallpaper"

  wallpaper="$(
    waypaper --list |
      jq -r '
        (
          map(select(.monitor == "All"))[0].wallpaper
          // .[0].wallpaper
          // empty
        )
      '
  )"

  [ -n "$wallpaper" ] ||
    die "Could not find an active wallpaper from waypaper"

  [ -f "$wallpaper" ] ||
    die "Waypaper returned a missing wallpaper file: $wallpaper"

  printf '%s\n' "$wallpaper"
}

wpgtk_wallpaper_name() {
  basename "$1" | tr ' ' '_'
}

ensure_wpg_wallpaper_imported() {
  wallpaper="$1"
  wpgtk_name="$(wpgtk_wallpaper_name "$wallpaper")"
  imported="$WPG_WALLPAPER_DIR/$wpgtk_name"

  if [ ! -e "$imported" ]; then
    printf 'Importing Waypaper wallpaper into wpg: %s\n' "$wallpaper" >&2
    wpg -a "$wallpaper" --noreload >&2
  fi

  printf '%s\n' "$wpgtk_name"
}

reset_wpg_for_current_wallpaper() {
  has wpg || die "wpg is not installed"

  wallpaper="$(get_current_wallpaper)"
  wpgtk_name="$(ensure_wpg_wallpaper_imported "$wallpaper")"

  printf 'Resetting wpg colours for: %s\n' "$wallpaper"

  # Waypaper owns the wallpaper. wpg only imports/regenerates colours here.
  # wpgtk's execute_cmd is asynchronous, so reset suppresses that callback and
  # runs the sync path itself after wpg exports pywal files.
  WPG_SYNC_SKIP_CALLBACK=1 wpg -n -s "$wpgtk_name"
  run_sync
}

sync_waybar() {
  [ -r "$WAL_DIR/colors-waybar.css" ] || return 0

  mkdir -p "$WAYBAR_DIR"
  cp "$WAL_DIR/colors-waybar.css" "$WAYBAR_DIR/wal.css"
}

sync_alacritty() {
  [ -r "$WAL_DIR/colors-alacritty.toml" ] || return 0

  mkdir -p "$(dirname "$ALACRITTY_COLORS")"
  cp "$WAL_DIR/colors-alacritty.toml" "$ALACRITTY_COLORS"
}

sync_rofi() {
  if [ -r "$WAL_DIR/colors-rofi-dark.rasi" ]; then
    mkdir -p "$(dirname "$ROFI_COLORS")"
    cp "$WAL_DIR/colors-rofi-dark.rasi" "$ROFI_COLORS"
  elif [ -r "$WAL_DIR/colors-rofi-light.rasi" ]; then
    mkdir -p "$(dirname "$ROFI_COLORS")"
    cp "$WAL_DIR/colors-rofi-light.rasi" "$ROFI_COLORS"
  fi
}

restart_waybar() {
  if [ -x "$WAYBAR_DIR/relaunch.sh" ]; then
    "$WAYBAR_DIR/relaunch.sh"
  elif has pkill && has waybar; then
    pkill -SIGUSR2 waybar >/dev/null 2>&1 || true
  fi
}

setup_logging

case "$MODE" in
  reset)
    reset_wpg_for_current_wallpaper
    exit 0
    ;;
  sync)
    if [ "${WPG_SYNC_SKIP_CALLBACK:-0}" = 1 ]; then
      printf '%s\n' "Skipping wpgtk async sync callback; reset will sync directly"
      exit 0
    fi
    ;;
  *)
    printf 'Usage: %s [sync|reset]\n' "$0" >&2
    exit 2
    ;;
esac

run_sync
