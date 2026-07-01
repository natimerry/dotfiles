#!/usr/bin/env sh
set -eu

MODE="${1:-sync}"

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
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

KDE_SCHEME_DIR="$DATA_HOME/color-schemes"
KDE_SCHEME="$KDE_SCHEME_DIR/Wpg.colors"

GTK3_DIR="$CONFIG_HOME/gtk-3.0"
GTK4_DIR="$CONFIG_HOME/gtk-4.0"
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
  write_kde_scheme
  write_gtk
  sync_flatpak_gtk
  restart_waybar

  printf '%s\n' "Synced wpg colours to Waybar, Alacritty, Rofi, KDE, GTK, and Flatpak GTK"
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

write_kde_scheme() {
  mkdir -p "$KDE_SCHEME_DIR"

  bg="$(rgb "$background")"
  fg="$(rgb "$foreground")"

  c0="$(rgb "$color0")"
  c1="$(rgb "$color1")"
  c2="$(rgb "$color2")"
  c3="$(rgb "$color3")"
  c4="$(rgb "$color4")"
  c5="$(rgb "$color5")"
  c6="$(rgb "$color6")"
  c7="$(rgb "$color7")"
  c8="$(rgb "$color8")"

  cat >"$KDE_SCHEME" <<EOF
[ColorEffects:Disabled]
Color=$fg
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=$fg
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
BackgroundAlternate=$c8
BackgroundNormal=$c0
DecorationFocus=$c4
DecorationHover=$c6
ForegroundActive=$c3
ForegroundInactive=$c8
ForegroundLink=$c4
ForegroundNegative=$c1
ForegroundNeutral=$c5
ForegroundNormal=$fg
ForegroundPositive=$c2
ForegroundVisited=$c5

[Colors:Complementary]
BackgroundAlternate=$c8
BackgroundNormal=$c0
DecorationFocus=$c4
DecorationHover=$c6
ForegroundActive=$c3
ForegroundInactive=$c8
ForegroundLink=$c4
ForegroundNegative=$c1
ForegroundNeutral=$c5
ForegroundNormal=$fg
ForegroundPositive=$c2
ForegroundVisited=$c5

[Colors:Header]
BackgroundAlternate=$c8
BackgroundNormal=$c0
DecorationFocus=$c4
DecorationHover=$c6
ForegroundActive=$c3
ForegroundInactive=$c8
ForegroundLink=$c4
ForegroundNegative=$c1
ForegroundNeutral=$c5
ForegroundNormal=$fg
ForegroundPositive=$c2
ForegroundVisited=$c5

[Colors:Header][Inactive]
BackgroundAlternate=$c8
BackgroundNormal=$c0
DecorationFocus=$c4
DecorationHover=$c6
ForegroundActive=$c3
ForegroundInactive=$c8
ForegroundLink=$c4
ForegroundNegative=$c1
ForegroundNeutral=$c5
ForegroundNormal=$fg
ForegroundPositive=$c2
ForegroundVisited=$c5

[Colors:Selection]
BackgroundAlternate=$c6
BackgroundNormal=$c4
DecorationFocus=$c4
DecorationHover=$c6
ForegroundActive=$fg
ForegroundInactive=$c7
ForegroundLink=$c7
ForegroundNegative=$c1
ForegroundNeutral=$c3
ForegroundNormal=$bg
ForegroundPositive=$c2
ForegroundVisited=$c5

[Colors:Tooltip]
BackgroundAlternate=$c8
BackgroundNormal=$c0
DecorationFocus=$c4
DecorationHover=$c6
ForegroundActive=$c3
ForegroundInactive=$c8
ForegroundLink=$c4
ForegroundNegative=$c1
ForegroundNeutral=$c5
ForegroundNormal=$fg
ForegroundPositive=$c2
ForegroundVisited=$c5

[Colors:View]
BackgroundAlternate=$c0
BackgroundNormal=$bg
DecorationFocus=$c4
DecorationHover=$c6
ForegroundActive=$c3
ForegroundInactive=$c8
ForegroundLink=$c4
ForegroundNegative=$c1
ForegroundNeutral=$c5
ForegroundNormal=$fg
ForegroundPositive=$c2
ForegroundVisited=$c5

[Colors:Window]
BackgroundAlternate=$c0
BackgroundNormal=$bg
DecorationFocus=$c4
DecorationHover=$c6
ForegroundActive=$c3
ForegroundInactive=$c8
ForegroundLink=$c4
ForegroundNegative=$c1
ForegroundNeutral=$c5
ForegroundNormal=$fg
ForegroundPositive=$c2
ForegroundVisited=$c5

[General]
AccentColor=$c4
ColorScheme=Wpg
Name=Wpg
shadeSortColumn=true

[KDE]
LookAndFeelPackage=org.kde.breezedark.desktop
contrast=4
widgetStyle=Breeze

[WM]
activeBackground=$c0
activeBlend=$c0
activeForeground=$fg
inactiveBackground=$bg
inactiveBlend=$bg
inactiveForeground=$c8
EOF

  if has plasma-apply-colorscheme; then
    plasma-apply-colorscheme Wpg >/dev/null 2>&1 || true
  fi

  if has kwriteconfig6; then
    kwriteconfig6 --file kdeglobals --group General --key ColorScheme Wpg
    kwriteconfig6 --file kdeglobals --group General --key AccentColor "$c4"
    kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage org.kde.breezedark.desktop
    kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Breeze
  fi

  if has kbuildsycoca6; then
    kbuildsycoca6 >/dev/null 2>&1 || true
  fi
}

ensure_gtk_import() {
  dir="$1"
  gtk_css="$dir/gtk.css"

  if [ ! -e "$gtk_css" ]; then
    printf "@import url('colors.css');\n" >"$gtk_css"
    return 0
  fi

  if grep -Fq "colors.css" "$gtk_css"; then
    return 0
  fi

  temp_file="$(mktemp "$dir/.gtk.css.XXXXXX")"

  {
    printf "@import url('colors.css');\n"
    cat "$gtk_css"
  } >"$temp_file"

  mv "$temp_file" "$gtk_css"
}

ensure_gtk_setting() {
  settings_file="$1"
  key="$2"
  value="$3"

  touch "$settings_file"

  if ! grep -q '^\[Settings\]' "$settings_file"; then
    temp_file="$(mktemp "$(dirname "$settings_file")/.settings.ini.XXXXXX")"

    {
      printf '[Settings]\n'
      cat "$settings_file"
    } >"$temp_file"

    mv "$temp_file" "$settings_file"
  fi

  if grep -q "^$key=" "$settings_file"; then
    sed -i "s|^$key=.*|$key=$value|" "$settings_file"
  else
    printf '%s=%s\n' "$key" "$value" >>"$settings_file"
  fi
}

write_gtk() {
  mkdir -p "$GTK3_DIR" "$GTK4_DIR"

  for dir in "$GTK3_DIR" "$GTK4_DIR"; do
    cat >"$dir/colors.css" <<EOF
@define-color borders_breeze $color8;
@define-color content_view_bg_breeze $background;
@define-color error_color_backdrop_breeze $color1;
@define-color error_color_breeze $color1;
@define-color insensitive_base_color_breeze $color0;
@define-color insensitive_base_fg_color_breeze $color8;
@define-color insensitive_bg_color_breeze $color0;
@define-color insensitive_borders_breeze $color8;
@define-color insensitive_fg_color_breeze $color8;
@define-color link_color_breeze $color4;
@define-color link_visited_color_breeze $color5;
@define-color success_color_breeze $color2;
@define-color theme_base_color_breeze $background;
@define-color theme_bg_color_breeze $background;
@define-color theme_button_background_normal_breeze $color0;
@define-color theme_button_decoration_focus_breeze $color4;
@define-color theme_button_decoration_hover_breeze $color6;
@define-color theme_button_foreground_active_breeze $foreground;
@define-color theme_button_foreground_normal_breeze $foreground;
@define-color theme_fg_color_breeze $foreground;
@define-color theme_header_background_breeze $background;
@define-color theme_header_background_light_breeze $background;
@define-color theme_header_foreground_breeze $foreground;
@define-color theme_hovering_selected_bg_color_breeze $color6;
@define-color theme_selected_bg_color_breeze $color4;
@define-color theme_selected_fg_color_breeze $background;
@define-color theme_text_color_breeze $foreground;
@define-color theme_titlebar_background_breeze $background;
@define-color theme_titlebar_background_light_breeze $background;
@define-color theme_titlebar_foreground_breeze $foreground;
@define-color theme_unfocused_base_color_breeze $background;
@define-color theme_unfocused_bg_color_breeze $background;
@define-color theme_unfocused_fg_color_breeze $foreground;
@define-color theme_unfocused_selected_bg_color_breeze $color8;
@define-color theme_unfocused_selected_fg_color_breeze $foreground;
@define-color theme_unfocused_text_color_breeze $foreground;
@define-color theme_unfocused_view_bg_color_breeze $color0;
@define-color theme_unfocused_view_text_color_breeze $color8;
@define-color theme_view_active_decoration_color_breeze $color4;
@define-color theme_view_hover_decoration_color_breeze $color6;
@define-color tooltip_background_breeze $background;
@define-color tooltip_border_breeze $color8;
@define-color tooltip_text_breeze $foreground;
@define-color unfocused_borders_breeze $color8;
EOF

    ensure_gtk_import "$dir"
    ensure_gtk_setting "$dir/settings.ini" "gtk-theme-name" "Breeze"
    ensure_gtk_setting "$dir/settings.ini" "gtk-application-prefer-dark-theme" "true"
  done

  if has gsettings; then
    gsettings set org.gnome.desktop.interface gtk-theme Breeze >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark >/dev/null 2>&1 || true
  fi
}

link_gtk_file() {
  src="$1"
  dest="$2"

  [ -e "$src" ] || return 0

  mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ]; then
    :
  elif [ -e "$dest" ]; then
    backup="$dest.pre-wpg"
    if [ ! -e "$backup" ]; then
      mv "$dest" "$backup"
    else
      rm -f "$dest"
    fi
  fi

  ln -sfn "$src" "$dest"
}

sync_flatpak_gtk() {
  flatpak_root="$HOME/.var/app"

  [ -d "$flatpak_root" ] || return 0

  for app_config in "$flatpak_root"/*/config; do
    [ -d "$app_config" ] || continue

    for version in gtk-3.0 gtk-4.0; do
      link_gtk_file "$CONFIG_HOME/$version/gtk.css" "$app_config/$version/gtk.css"
      link_gtk_file "$CONFIG_HOME/$version/colors.css" "$app_config/$version/colors.css"
      link_gtk_file "$CONFIG_HOME/$version/settings.ini" "$app_config/$version/settings.ini"
    done
  done
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
