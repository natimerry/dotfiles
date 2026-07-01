#!/usr/bin/env sh
set -eu

WAYBAR_DIR="${WAYBAR_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/waybar}"
LOCAL_WAL="$WAYBAR_DIR/wal.css"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wal"
PYWAL_CSS="$CACHE_DIR/colors-waybar.css"
PYWAL_ALACRITTY="$CACHE_DIR/colors-alacritty.toml"
WAL_BIN="${WAL_BIN:-wal}"
DESKTOP_THEME_SCRIPT="$WAYBAR_DIR/scripts/wal-desktop-theme.sh"
APPLY_DESKTOP_THEME="${APPLY_DESKTOP_THEME:-0}"
ALACRITTY_COLORS="${ALACRITTY_COLORS:-${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/colors.toml}"
SYNC_ALACRITTY="${SYNC_ALACRITTY:-1}"
SYNC_WAL_GTK="${SYNC_WAL_GTK:-0}"

usage() {
  cat <<EOF
Usage:
  pywal-waybar.sh setup
  pywal-waybar.sh restore
  pywal-waybar.sh pick
  pywal-waybar.sh watch [wallpaper-directory]
  pywal-waybar.sh auto
  pywal-waybar.sh /path/to/wallpaper

Environment:
  WAYBAR_DIR  Waybar config directory. Defaults to \$XDG_CONFIG_HOME/waybar.
  WAL_BIN     pywal command. Defaults to wal.
  SYNC_WAL_GTK=1 runs wal-gtk after pywal if wal-gtk is installed.
EOF
}

has() {
  command -v "$1" >/dev/null 2>&1
}

write_fallback() {
  cat > "$LOCAL_WAL" <<'EOF'
@define-color background #1a1b26;
@define-color foreground #e5e9f0;
@define-color cursor #e5e9f0;

@define-color color0 #1a1b26;
@define-color color1 #f7768e;
@define-color color2 #9ece6a;
@define-color color3 #e0af68;
@define-color color4 #7aa2f7;
@define-color color5 #bb9af7;
@define-color color6 #7dcfff;
@define-color color7 #c0caf5;
@define-color color8 #414868;
@define-color color9 #f7768e;
@define-color color10 #9ece6a;
@define-color color11 #e0af68;
@define-color color12 #7aa2f7;
@define-color color13 #bb9af7;
@define-color color14 #7dcfff;
@define-color color15 #c0caf5;
EOF
}

install_hint() {
  os_id="linux"
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    os_id="${ID:-linux}"
  fi

  case "$os_id" in
    fedora)
      echo "wal was not found. Fedora-friendly install path: sudo dnf install pipx && pipx install pywal"
      ;;
    arch|endeavouros|manjaro)
      echo "wal was not found. Install pywal from your distro repos or AUR, then run: pywal-waybar.sh setup"
      ;;
    debian|ubuntu|pop|linuxmint)
      echo "wal was not found. Debian/Ubuntu path: sudo apt install pipx && pipx install pywal"
      ;;
    opensuse*|suse)
      echo "wal was not found. openSUSE path: sudo zypper install python3-pipx && pipx install pywal"
      ;;
    *)
      echo "wal was not found. Install pywal so the wal command is available, then run: pywal-waybar.sh setup"
      ;;
  esac
}

sync_colors() {
  if [ -r "$PYWAL_CSS" ]; then
    cp "$PYWAL_CSS" "$LOCAL_WAL"
    echo "Synced $LOCAL_WAL from $PYWAL_CSS"
  else
    write_fallback
    echo "No pywal cache found; wrote fallback colors to $LOCAL_WAL"
  fi
}

sync_alacritty() {
  [ "$SYNC_ALACRITTY" = "1" ] || return 0
  [ -r "$PYWAL_ALACRITTY" ] || return 0

  alacritty_dir="$(dirname "$ALACRITTY_COLORS")"
  [ -d "$alacritty_dir" ] || return 0

  if [ -r "$ALACRITTY_COLORS" ] && [ ! -r "$ALACRITTY_COLORS.pre-pywal" ]; then
    cp "$ALACRITTY_COLORS" "$ALACRITTY_COLORS.pre-pywal" || {
      echo "Could not back up $ALACRITTY_COLORS; skipping Alacritty sync" >&2
      return 0
    }
  fi

  cp "$PYWAL_ALACRITTY" "$ALACRITTY_COLORS" || {
    echo "Could not write $ALACRITTY_COLORS; skipping Alacritty sync" >&2
    return 0
  }
  echo "Synced $ALACRITTY_COLORS from $PYWAL_ALACRITTY"
}

restart_waybar() {
  if [ -x "$WAYBAR_DIR/relaunch.sh" ]; then
    "$WAYBAR_DIR/relaunch.sh"
    return 0
  fi

  if ! has waybar; then
    return 0
  fi

  if has pkill; then
    pkill -x waybar >/dev/null 2>&1 || true
  fi

  nohup waybar >/dev/null 2>&1 &
}

apply_desktop_theme() {
  if [ "$APPLY_DESKTOP_THEME" = "1" ] && [ -x "$DESKTOP_THEME_SCRIPT" ]; then
    "$DESKTOP_THEME_SCRIPT" || true
  fi
}

sync_wal_gtk() {
  [ "$SYNC_WAL_GTK" = "1" ] || return 0

  if ! has wal-gtk; then
    echo "SYNC_WAL_GTK=1 set, but wal-gtk is not installed" >&2
    return 0
  fi

  wal-gtk || true
}

latest_image_in_dir() {
  dir="$1"
  [ -d "$dir" ] || return 1
  find "$dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' -o -iname '*.gif' \) -printf '%T@ %p\n' 2>/dev/null |
    sort -nr |
    sed 's/^[^ ]* //' |
    sed -n '1p'
}

waypaper_wallpaper() {
  has waypaper || return 1
  waypaper --list 2>/dev/null |
    sed -n 's/.*"wallpaper"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' |
    sed 's#\\/#/#g' |
    sed -n '1p'
}

detect_wallpaper() {
  image="$(waypaper_wallpaper || true)"
  if [ -n "$image" ] && [ -r "$image" ]; then
    printf '%s\n' "$image"
    return 0
  fi

  if [ -r "$CACHE_DIR/wal" ]; then
    image="$(sed -n '1p' "$CACHE_DIR/wal")"
    [ -r "$image" ] && {
      printf '%s\n' "$image"
      return 0
    }
  fi

  for dir in \
    "${XDG_CACHE_HOME:-$HOME/.cache}/waypaper" \
    "$HOME/wall" \
    "$HOME/Wallpapers" \
    "$HOME/Pictures/Wallpapers" \
    "$HOME/Pictures" \
    "$HOME/pictures"; do
    image="$(latest_image_in_dir "$dir" || true)"
    [ -n "$image" ] && [ -r "$image" ] && {
      printf '%s\n' "$image"
      return 0
    }
  done

  return 1
}

run_wal() {
  image="$1"
  if [ ! -r "$image" ]; then
    echo "Wallpaper is not readable: $image" >&2
    exit 1
  fi

  if ! has "$WAL_BIN"; then
    install_hint >&2
    exit 127
  fi

  "$WAL_BIN" -n -q -i "$image"
  sync_colors
  sync_alacritty
  sync_wal_gtk
  apply_desktop_theme
  restart_waybar
}

pick_image() {
  start_dir="${XDG_PICTURES_DIR:-$HOME/Pictures}"
  [ -d "$start_dir" ] || start_dir="$HOME"

  if has kdialog; then
    kdialog --getopenfilename "$start_dir" "image/png image/jpeg image/webp image/bmp image/gif"
  elif has zenity; then
    zenity --file-selection --filename="$start_dir/" --file-filter='Images | *.png *.jpg *.jpeg *.webp *.bmp *.gif'
  elif has yad; then
    yad --file-selection --filename="$start_dir/" --file-filter='Images | *.png *.jpg *.jpeg *.webp *.bmp *.gif'
  else
    echo "No graphical file picker found. Pass a wallpaper path directly." >&2
    exit 1
  fi
}

restore_colors() {
  image="$(waypaper_wallpaper || true)"
  if [ -z "$image" ] || [ ! -r "$image" ]; then
    echo "Could not read current Waypaper wallpaper. Falling back to auto detection." >&2
    image="$(detect_wallpaper)" || {
      echo "Could not detect a wallpaper. Pass a path directly." >&2
      exit 1
    }
  fi

  run_wal "$image"
}

watch_dir() {
  dir="${1:-$HOME/Pictures/Wallpapers}"
  [ -d "$dir" ] || {
    echo "Wallpaper directory does not exist: $dir" >&2
    exit 1
  }

  if ! has inotifywait; then
    echo "inotifywait is required for watch mode." >&2
    exit 1
  fi

  inotifywait -m -e close_write,moved_to,create --format '%w%f' "$dir" |
    while IFS= read -r file; do
      case "$file" in
        *.jpg|*.jpeg|*.png|*.webp|*.bmp|*.gif) run_wal "$file" ;;
      esac
    done
}

cmd="${1:-setup}"

case "$cmd" in
  setup|init)
    sync_colors
    sync_alacritty
    sync_wal_gtk
    apply_desktop_theme
    if ! has "$WAL_BIN"; then
      install_hint >&2
    fi
    ;;
  auto)
    image="$(detect_wallpaper)" || {
      echo "Could not detect a wallpaper. Pass a path directly." >&2
      exit 1
    }
    run_wal "$image"
    ;;
  restore)
    restore_colors
    ;;
  pick)
    image="$(pick_image)"
    [ -n "$image" ] && run_wal "$image"
    ;;
  watch)
    watch_dir "${2:-}"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    run_wal "$cmd"
    ;;
esac
