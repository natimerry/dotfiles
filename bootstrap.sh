#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
packages=(shell desktop theme terminal editors)

command -v stow >/dev/null 2>&1 || {
  printf 'GNU Stow is required. On Fedora: sudo dnf install stow\n' >&2
  exit 1
}

stow --dir "$repo" --target "$HOME" --no-folding --restow "${packages[@]}"
