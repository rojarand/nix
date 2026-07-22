{ config, lib, pkgs, user, ... }:

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
      zsh-autosuggestions
      zsh-completions
      zsh-syntax-highlighting
    ];

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    file.".config/wezterm".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
    file.".config/nvim".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";



    # The machine already has a hand-written ~/.zshrc, so Home Manager's
    # generated zsh config is not linked unless that file is moved away.
    # Patch the existing file on activation so WezTerm's login zsh gets
    # completion, autosuggestions, and syntax highlighting immediately.
    activation.installZshEnhancements = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      zshrc="$HOME/.zshrc"
      marker="# BEGIN nix-env-setup zsh enhancements"

      if ! grep -qF "$marker" "$zshrc" 2>/dev/null; then
        cat >> "$zshrc" <<'EOF'

# BEGIN nix-env-setup zsh enhancements
# Added by Home Manager from nix-env-setup.
fpath=(${pkgs.zsh-completions}/share/zsh/site-functions $fpath)
autoload -Uz compinit
if [ -n "$ZDOTDIR" ]; then
  compinit -d "$ZDOTDIR/.zcompdump"
else
  compinit -d "$HOME/.zcompdump"
fi
source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
bindkey '^f' autosuggest-accept
# END nix-env-setup zsh enhancements
EOF
      fi
    '';

    activation.installStarshipZshIntegration = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      zshrc="$HOME/.zshrc"
      marker="# BEGIN nix-env-setup starship"

      if ! grep -qF "$marker" "$zshrc" 2>/dev/null; then
        cat >> "$zshrc" <<'EOF'

# BEGIN nix-env-setup starship
# Added by Home Manager from nix-env-setup.
eval "$(${pkgs.starship}/bin/starship init zsh)"
# END nix-env-setup starship
EOF
      fi
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  programs.git = {
    enable = true;
    settings = {
      core.editor = "nvim";
    };
  };
}
