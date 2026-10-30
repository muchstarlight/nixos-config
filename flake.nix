{
  description = "多主机 NixOS 配置：显式主机组合、Home Manager 与离线检查";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # 保留上游依赖，避免稳定分支 libqalculate 的兼容问题。
    noctalia.url = "github:noctalia-dev/noctalia/v5.3.0";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    inputs:
    let
      system = "x86_64-linux";
      mkHost = import ./lib/mk-host.nix { inherit inputs; };
      mkLaptop =
        migrationPreview:
        mkHost {
          inherit system;
          hostModule = ./hosts/laptop/configuration.nix;
          specialArgs = { inherit migrationPreview; };
          homeUsers.muchstarlight = import ./hosts/laptop/home.nix;
          backupFileExtension = "before-nixos-20261030";
          chrootGuard = !migrationPreview;
        };
      laptop = mkLaptop false;
      preview = mkLaptop true;
    in
    {
      nixosConfigurations = {
        inherit laptop;
        laptop-preview = preview;
      };
      packages.${system} = import ./nix/packages.nix {
        inherit inputs system;
        laptop = preview;
      };
      checks.${system} = import ./nix/checks.nix {
        inherit inputs system mkHost;
        laptop = preview;
        installedLaptop = laptop;
      };
      formatter.${system} = inputs.nixpkgs.legacyPackages.${system}.nixfmt-tree;
    };
}
