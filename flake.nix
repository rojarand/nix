{
  description = "dotfiles";

  inputs = {
    # Use `github:NixOS/nixpkgs/nixpkgs-26.05-darwin` to use Nixpkgs 26.05.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    # Use `github:nix-darwin/nix-darwin/nix-darwin-26.05` to use Nixpkgs 26.05.
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Packages that are not in the pinned 26.05 release yet (e.g. herdr) are
    # pulled from nixpkgs-unstable through an overlay below. Do not make this
    # follow `nixpkgs`, that would defeat the purpose.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nix-homebrew, home-manager, nixpkgs, nixpkgs-unstable }:
    let
      # macOS account name and nix-darwin configuration name (usually hostname).
      user = "ran";
      hostName = "mb-ran-6167";

      # Linux (Raspberry Pi) account name.
      linuxUser = "zebul";
      linuxSystem = "aarch64-linux";

      # Expose selected unstable packages as `pkgs.<name>` on every platform.
      unstablePackages = [ "herdr" ];
      unstableOverlay = _final: prev:
        let
          unstable = nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system};
        in
        nixpkgs.lib.genAttrs unstablePackages (name: unstable.${name});
    in
    {
      homeConfigurations.${linuxUser} = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = linuxSystem;
          config.allowUnfree = true;
          overlays = [ unstableOverlay ];
        };
        extraSpecialArgs = {
          user = linuxUser;
        };
        modules = [ ./home ];
      };

      packages.${linuxSystem}.home-manager =
        home-manager.packages.${linuxSystem}.home-manager;

      darwinConfigurations.${hostName} = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit user; };
        modules = [
          ./configuration.nix
          { nixpkgs.overlays = [ unstableOverlay ]; }
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit user; };
            home-manager.users.${user} = import ./home;
          }
        ];
      };
    };
}
