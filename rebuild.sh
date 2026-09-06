#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Do not run this script with sudo. Run ./rebuild.sh as your normal user." >&2
  exit 1
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
"$DIR/check-root-owned-files.sh" "$DIR"
ln -sfn "$DIR" "$HOME/.dotfiles"
exec sudo /run/current-system/sw/bin/darwin-rebuild switch --flake "path:$DIR#mb-ran-6167"
