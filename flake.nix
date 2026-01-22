{
  description = "NixOS configuration";

  inputs = {
    # store
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # home-manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niri
    niri.url = "github:sodiboo/niri-flake";
  };

  outputs = inputs@{ nixpkgs, home-manager, niri, ... }: {
    nixosConfigurations = {
      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/laptop/configuration.nix
          
          # Niri 模块 (系统级)
          niri.nixosModules.niri

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.muchstarlight = { config, pkgs, ... }: {
              imports = [
                ./modules/home/base.nix
                ./modules/home/apps.nix
                ./modules/home/cli-tools.nix
              ];
            };
            home-manager.extraSpecialArgs = inputs;
          }
        ];
      };
    };
  };
}