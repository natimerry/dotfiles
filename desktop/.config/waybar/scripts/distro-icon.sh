#!/usr/bin/env sh
set -eu

id="linux"
name="Linux"

if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  id="${ID:-linux}"
  name="${PRETTY_NAME:-${NAME:-Linux}}"
fi

case "$id" in
  arch) icon="" ;;
  fedora) icon="" ;;
  debian) icon="" ;;
  ubuntu|pop|linuxmint) icon="" ;;
  opensuse*|suse) icon="" ;;
  nixos) icon="" ;;
  manjaro) icon="" ;;
  endeavouros) icon="" ;;
  gentoo) icon="" ;;
  void) icon="" ;;
  alpine) icon="" ;;
  *) icon="" ;;
esac

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

printf '{"text":"%s","tooltip":"%s"}\n' "$icon" "$(json_escape "$name")"
