#!/usr/bin/env bash
set -euo pipefail

# Using sudo would update root's profile instead of the invoking user's
# profile. Running directly as root (for example in a container) is fine.
if [[ -n "${SUDO_USER:-}" ]]; then
  echo "Do not run this script with sudo. Run ./rebuild-linux.sh as the user whose profile should be updated." >&2
  exit 1
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
flake="git+file://${DIR}"
user="$(id -un)"

ln -sfn "$DIR" "$HOME/.dotfiles"
exec nix run "${flake}#home-manager" -- switch --flake "${flake}#${user}"
