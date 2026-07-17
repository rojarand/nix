{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in
{
  home = {
    username = user;
    homeDirectory = "/Users/${user}";
    stateVersion = "26.05";

    packages = with pkgs; [
      git
      vim
    ];

    sessionVariables = {
      EDITOR = "vim";
      VISUAL = "vim";
    };

    file.".config/wezterm".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  };

  programs.git = {
    enable = true;
    extraConfig = {
      core.editor = "vim";
    };
  };
}
