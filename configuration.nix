{ pkgs, lib, user, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };

  # Install fonts through nix-darwin so macOS GUI apps (including the
  # Homebrew WezTerm cask) can discover them via CoreText.
  fonts.packages = [
    pkgs.nerd-fonts.hack
  ];

  system.stateVersion = 6;

  # GUI apps on macOS (WezTerm opened from the Dock, Spotlight, or Finder)
  # inherit the launchd environment, not the shell's. Neovim then cannot find
  # helper binaries such as `rg` and snacks.nvim's grep picker fails with
  # "Failed to spawn rg". Put the Nix profiles on the system-wide search path
  # so those apps resolve the same tools as a login shell.
  environment.pathsToLink = [ "/bin" ];
  environment.variables = {
    PATH = lib.mkForce (lib.concatStringsSep ":" [
      "/run/current-system/sw/bin"
      "/etc/profiles/per-user/${user}/bin"
      "/nix/var/nix/profiles/default/bin"
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ]);
  };
  system.defaults = {
    NSGlobalDomain = {
      # AppleInterfaceStyle = "Dark";
      # KeyRepeat = 2;          # fast key repeat
      # InitialKeyRepeat = 15;  # short delay before repeat
      # _HIHideMenuBar = true;  # auto-hide the menu bar
      # AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    # finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    # finder.CreateDesktop = false;          # clean desktop
    # trackpad.Clicking = true;              # tap to click
  };
  nix-homebrew = {
    enable = true;
    inherit user;
    autoMigrate = true;
  };
  homebrew = {
    enable = true;
    # onActivation.cleanup = "zap";  # remove anything not listed here, !!!apply only on a fresh installation
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    # CLI tools shared with Linux hosts are installed through Nix in
    # ../home/common.nix, not here. Only keep macOS-only GUI apps and tools
    # that are not packaged in nixpkgs in this list.
    brews = [
      "jira-cli"
    ];
    casks = [
      "wezterm"
      "opensuperwhisper"
      "automic-vault/isotopes/automic-vault"
      # "claude-code"
    ];
  };
}
