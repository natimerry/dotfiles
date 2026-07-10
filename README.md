# Dotfiles

Curated GNU Stow packages for shell, desktop, theming, terminal, and editor configuration.

```sh
./bootstrap.sh
```

Packages:

- `shell`: Bash/Zsh startup files
- `desktop`: Doors, Waybar, Waypaper, Mako, Rofi, Wofi, Thunar, and desktop defaults
- `theme`: static GTK 2/3/4 and Qt 6 appearance settings
- `terminal`: Alacritty and Ghostty source configuration
- `editors`: Helix configuration and themes

Generated wpgtk outputs, caches, wallpapers, samples, downloaded color collections,
application databases, histories, browser profiles, and secret-bearing configs are excluded.

Useful commands:

```sh
stow --dir ~/dotfiles --target ~ --no-folding --restow desktop
stow --dir ~/dotfiles --target ~ --no-folding --delete desktop
```
