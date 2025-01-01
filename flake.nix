{
  description = "NixOS configuration";

  inputs = {
    # store
    nixpkgs.url = "github:Nixos/nixpkgs/nixpkgs-unstable";

    # home-manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      };
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
	  # configuration
          ./machine/laptop/configuration.nix
	  # user program
          ./user/default.nix
	  # home manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.muchstarlight = import ./user/home.nix;
            home-manager.extraSpecialArgs = inputs;
          }
        ];
      };
    };
  };
}
