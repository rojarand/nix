#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Do not run this script with sudo. Run ./rebuild-pi.sh as your normal user." >&2
  exit 1
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" "$HOME/.dotfiles"
exec nix run "path:$DIR#home-manager" -- switch --flake "path:$DIR#zebul"
