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
      neovim
    ];

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    file.".config/wezterm".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      bindkey '^f' autosuggest-accept
    '';
  };

  programs.git = {
    enable = true;
    settings = {
      core.editor = "nvim";
    };
  };
}
