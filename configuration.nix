{ pkgs, user, ... }:

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
