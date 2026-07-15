{ pkgs, user, ... }:

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
  };

  programs.git = {
    enable = true;
    extraConfig = {
      core.editor = "vim";
    };
  };
}
