{ config, lib, pkgs, user, homeDirectory, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in
{
  imports = [ ./common.nix ];

  home = {
    username = user;
    inherit homeDirectory;
    stateVersion = "26.05";

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      # Neovim spawns helpers such as `rg` by bare name, so the Home Manager
      # profile has to be on PATH for GUI-launched terminals (WezTerm from the
      # Dock never reads ~/.zshrc) as well as for login shells. Without this,
      # snacks.nvim's grep picker fails with "Failed to spawn rg".
      PATH = lib.mkForce (lib.concatStringsSep ":" [
        "$HOME/.nix-profile/bin"
        "/run/current-system/sw/bin"
        "/etc/profiles/per-user/$USER/bin"
        "/nix/var/nix/profiles/default/bin"
        "/usr/local/bin"
        "/usr/bin"
        "/bin"
        "/usr/sbin"
        "/sbin"
      ]);
    };

    file.".config/wezterm".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
    file.".config/nvim".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
    # Only config.toml is managed. herdr writes sockets, logs and session
    # state next to its config, so linking the whole directory would drop
    # runtime files into this repository and break `nix flake` (sockets
    # cannot be copied into the store).
    file.".config/herdr/config.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr/config.toml";

    # Git bash aliases, kept as a plain file so the shell can source them.
    file.".git_aliases".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.git_aliases";

    # Homes migrated from the earlier setup still carry a hand-made
    # ~/.git_aliases pointing at wherever the aliases used to live (for example
    # ~/aliases/git-bash-aliases/.git_aliases). Home Manager refuses to replace
    # such a path during checkLinkTargets, so activation aborts with
    # "Existing file '/root/.git_aliases' would be clobbered" before anything
    # else runs. Retire the stale link so the file.".git_aliases" above becomes
    # the single source of truth. The file it pointed at is left untouched.
    #
    # Ordered before checkLinkTargets, and idempotent: once Home Manager owns
    # the path the link already matches `wanted` and nothing happens.
    activation.removeLegacyGitAliasesLink =
      lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        target="$HOME/.git_aliases"
        wanted="${dotfiles}/home/.git_aliases"

        if [ -L "$target" ] && [ "$(readlink "$target")" != "$wanted" ]; then
          stale="$(readlink "$target")"
          run rm -f "$target"
          echo "git aliases: removed stale link $target -> $stale so Home Manager can manage it" >&2
        fi
      '';

    file.".pi/agent/AGENTS.md".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
    file.".claude/CLAUDE.md".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
    file.".codex/AGENTS.md".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
    file.".config/opencode/AGENTS.md".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";


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

    # Neovim spawns helper binaries such as `rg` by bare name, so interactive
    # shells must have the Home Manager profile on PATH. Without this, opening
    # an editor or terminal on a machine whose shell predates Home Manager
    # leaves `rg` unresolved and snacks.nvim's grep picker fails with
    # "Failed to spawn rg". This block is applied independently of the
    # enhancements block above so it is also added to an already-patched
    # ~/.zshrc.
    activation.installNixProfilePath = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      zshrc="$HOME/.zshrc"
      marker="# BEGIN nix-env-setup path"

      if ! grep -qF "$marker" "$zshrc" 2>/dev/null; then
        cat >> "$zshrc" <<'EOF'

# BEGIN nix-env-setup path
# Added by Home Manager from nix-env-setup.
# Makes tools installed by Nix (notably `rg`, used by Neovim's grep picker)
# resolvable from interactive shells.
if [ -d "$HOME/.nix-profile/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.nix-profile/bin:"*) ;;
    *) export PATH="$HOME/.nix-profile/bin:$PATH" ;;
  esac
fi
# END nix-env-setup path
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

    # tmux reads ~/.tmux.conf in preference to the generated
    # ~/.config/tmux/tmux.conf, and it only loads one of them. A stale
    # hand-written ~/.tmux.conf therefore silently overrides everything set in
    # programs.tmux below - historically it rebound the prefix to C-q, which
    # made Ctrl-b and the vi pane bindings dead. Retire that file so this
    # module is the single source of truth. The original is kept alongside for
    # reference rather than destroyed.
    #
    # Runs after writeBoundary so the generated config already exists, and is
    # idempotent: once the legacy file is gone there is nothing left to do.
    activation.removeLegacyTmuxConf =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        legacy="$HOME/.tmux.conf"
        generated="$HOME/.config/tmux/tmux.conf"

        if [ -f "$legacy" ] && [ ! -L "$legacy" ] && [ -f "$generated" ]; then
          backup="$legacy.pre-nix"
          if [ -f "$backup" ] && cmp -s "$legacy" "$backup"; then
            # Already preserved by an earlier activation.
            rm -f "$legacy"
          else
            run mv "$legacy" "$backup"
            echo "tmux: moved legacy $legacy to $backup so the Nix config at $generated takes effect" >&2
          fi
        fi
      '';

    activation.installGitAliasesZshIntegration = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      zshrc="$HOME/.zshrc"
      marker="# BEGIN nix-env-setup git aliases"

      if ! grep -qF "$marker" "$zshrc" 2>/dev/null; then
        cat >> "$zshrc" <<'EOF'

# BEGIN nix-env-setup git aliases
# Added by Home Manager from nix-env-setup.
if [ -f "$HOME/.git_aliases" ]; then
    . "$HOME/.git_aliases"
fi
# END nix-env-setup git aliases
EOF
      fi
    '';

    activation.installGitAliasesBashIntegration = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      bashrc="$HOME/.bashrc"
      marker="# BEGIN nix-env-setup git aliases"

      if ! grep -qF "$marker" "$bashrc" 2>/dev/null; then
        cat >> "$bashrc" <<'EOF'

# BEGIN nix-env-setup git aliases
# Added by Home Manager from the git-bash-aliases project.
if [ -f "$HOME/.git_aliases" ]; then
    . "$HOME/.git_aliases"
fi
# END nix-env-setup git aliases
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

  # Match herdr's pane navigation: prefix + h/j/k/l move between panes
  # (left/down/up/right). This also binds prefix + H/J/K/L to resize panes.
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
  };
}
