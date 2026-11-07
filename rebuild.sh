#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Do not run this script with sudo. Run ./rebuild.sh as your normal user." >&2
  exit 1
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" "$HOME/.dotfiles"
sudo /run/current-system/sw/bin/darwin-rebuild switch --flake "path:$DIR#mb-ran-6167"

case "${SHELL:-}" in
  */zsh) echo 'Rebuild complete. Run: source ~/.zshrc' ;;
  */bash) echo 'Rebuild complete. Run: source ~/.bashrc' ;;
  *) echo 'Rebuild complete. Source your shell configuration to load the changes in this terminal.' ;;
esac
