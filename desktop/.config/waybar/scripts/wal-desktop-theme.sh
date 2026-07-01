#!/usr/bin/env sh
set -eu

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wal"
COLORS_SH="$CACHE_DIR/colors.sh"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
SCHEME_DIR="$DATA_HOME/color-schemes"
SCHEME_FILE="$SCHEME_DIR/Pywal.colors"
GTK3_CSS="$CONFIG_HOME/gtk-3.0/gtk.css"
GTK4_CSS="$CONFIG_HOME/gtk-4.0/gtk.css"

has() {
  command -v "$1" >/dev/null 2>&1
}

load_colors() {
  if [ ! -r "$COLORS_SH" ]; then
    echo "pywal colors were not found at $COLORS_SH" >&2
    echo "Run: wal -i /path/to/wallpaper" >&2
    exit 1
  fi

  # shellcheck disable=SC1090
  . "$COLORS_SH"
}

rgb() {
  hex="${1#\#}"
  r="${hex%????}"
  gb="${hex#??}"
  g="${gb%??}"
  b="${hex#????}"
  printf '%d,%d,%d' "0x$r" "0x$g" "0x$b"
}

write_kde_scheme() {
  mkdir -p "$SCHEME_DIR"

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

  cat > "$SCHEME_FILE" <<EOF
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
ColorScheme=Pywal
Name=Pywal
shadeSortColumn=true

[KDE]
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
    plasma-apply-colorscheme Pywal >/dev/null 2>&1 || true
  fi
}

write_gtk_css() {
  mkdir -p "$(dirname "$GTK3_CSS")" "$(dirname "$GTK4_CSS")"

  css="$(mktemp)"
  cat > "$css" <<EOF
@define-color wal_background $background;
@define-color wal_foreground $foreground;
@define-color wal_cursor $cursor;
@define-color wal_color0 $color0;
@define-color wal_color1 $color1;
@define-color wal_color2 $color2;
@define-color wal_color3 $color3;
@define-color wal_color4 $color4;
@define-color wal_color5 $color5;
@define-color wal_color6 $color6;
@define-color wal_color7 $color7;
@define-color wal_color8 $color8;
@define-color wal_color9 $color9;
@define-color wal_color10 $color10;
@define-color wal_color11 $color11;
@define-color wal_color12 $color12;
@define-color wal_color13 $color13;
@define-color wal_color14 $color14;
@define-color wal_color15 $color15;

window,
dialog,
popover,
menubar,
menu,
.background {
  background-color: @wal_background;
  color: @wal_foreground;
}

headerbar,
toolbar,
notebook > header {
  background-color: @wal_color0;
  color: @wal_foreground;
}

button,
entry,
spinbutton,
combobox,
switch,
trough,
treeview {
  background-color: @wal_color0;
  color: @wal_foreground;
  border-color: @wal_color8;
}

button:hover,
row:hover {
  background-color: @wal_color8;
}

*:selected,
selection,
row:selected {
  background-color: @wal_color4;
  color: @wal_background;
}

link,
button.link {
  color: @wal_color6;
}
EOF

  cp "$css" "$GTK3_CSS"
  cp "$css" "$GTK4_CSS"
  rm -f "$css"

  if has gsettings; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark >/dev/null 2>&1 || true
  fi
}

load_colors
write_kde_scheme
write_gtk_css

echo "Wrote KDE color scheme: $SCHEME_FILE"
echo "Wrote GTK CSS: $GTK3_CSS"
echo "Wrote GTK CSS: $GTK4_CSS"
