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
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/laptop-colorful.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.muchstarlight = import ./home-manager/home.nix;
            home-manager.extraSpecialArgs = inputs;
          }
        ];
      };
    };
    colmena = {
      meta = {
        nixpkgs = import nixpkgs { system = "x86_64-linux"; };
        # 这个参数的功能与 `nixosConfigurations.xxx` 中的 `specialArgs` 一致，
        # 都是用于传递自定义参数到所有子模块。
        specialArgs = {
          inherit nixpkgs;
        };
      };

      # 主机名 = "home"
      "home" = { name, nodes, ... }: {
        deployment.targetHost = "192.168.2.10"; # 远程主机的 IP 地址
        deployment.targetUser = "root";  # 远程主机的用户名

        # 此参数的功能与 `nixosConfigurations.xxx` 中的 `modules` 一致
        # 都是用于导入所有子模块。
        imports = [
          ./hosts/server-home.nix
        ];
      };
      "aliyun" = { name, nodes, ... }: {
        deployment.targetHost = "192.168.10.1"; # 把ip地址在 .ssh/config 直接配成别名
        deployment.targetUser = "root";  # 远程主机的用户名

        # 此参数的功能与 `nixosConfigurations.xxx` 中的 `modules` 一致
        # 都是用于导入所有子模块。
        imports = [
          ./hosts/server-aliyun.nix
        ];
      };
    };
  };
}
