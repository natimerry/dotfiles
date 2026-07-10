#!/bin/sh

savedir="${DOORS_SCREENSHOT_DIR:-$HOME/Pictures/screenshots}"
mkdir -p "$savedir"

file="$savedir/$(date +'%Y-%m-%d-%H%M%S_screenshot.png')"
mode="${1:-fullscreen}"

case "$mode" in
	fullscreen)
		sleep 0.2
		grim "$file"
		;;
	region)
		geometry="$(slurp)" || exit 0
		[ -n "$geometry" ] || exit 0
		grim -g "$geometry" "$file"
		;;
	*)
		notify-send "Screenshot" "Unknown screenshot mode: $mode"
		exit 1
		;;
esac

wl-copy < "$file"
notify-send "Screenshot" "File saved as '$file' and copied to the clipboard." -i "$file"
