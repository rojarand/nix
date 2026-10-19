# Tools that should exist on every machine (macOS laptop and Raspberry Pi).
#
# Everything listed here is installed through Nix on BOTH platforms, so do not
# also list these in `homebrew` in ../configuration.nix. Two package managers
# owning the same binary is how you get silent version mismatches.
#
# This file only covers packages. Shell setup lives in ./default.nix.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Terminal / CLI tools.
    ffmpeg
    git
    herdr
    neovim
    ripgrep
    tmux

    # zsh integration, sourced by the activation scripts in ./default.nix.
    zsh-autosuggestions
    zsh-completions
    zsh-syntax-highlighting
  ];
}
