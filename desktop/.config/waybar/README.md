# Waybar wpg setup

This config keeps Waybar colors in `wal.css` and imports that file from `style.css`.
Change wallpapers with Waypaper, then run `scripts/wpg-sync-theme.sh reset`. It reads
Waypaper's active wallpaper, imports that image into wpg when needed, regenerates wpg
colors without changing the wallpaper, syncs Waybar/Alacritty/Rofi/KDE/GTK, and restarts
Waybar.

The Waybar palette button and `Super+F1` use that same reset flow.

```sh
~/.config/waybar/scripts/wpg-sync-theme.sh reset
~/.config/waybar/scripts/wpg-sync-theme.sh sync
```

Layout:

- Left: workspaces.
- Center: active window title.
- Right: wpg current-Waypaper refresh, rofi Wi-Fi picker, taskbar, volume, CPU, memory, temperature, clock, decoration.
