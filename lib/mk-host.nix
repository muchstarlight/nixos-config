{ inputs }:
{
  system,
  hostModule,
  homeUsers ? { },
  specialArgs ? { },
  backupFileExtension ? null,
  chrootGuard ? false,
}:
let
  lib = inputs.nixpkgs.lib;
  base = lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs;
    }
    // specialArgs;
    modules = [
      hostModule
    ]
    ++ lib.optionals (homeUsers != { }) [
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = backupFileExtension;
        home-manager.extraSpecialArgs = { inherit inputs; };
        home-manager.users = homeUsers;
      }
    ];
  };
in
if chrootGuard then import ./with-chroot-guard.nix { inherit lib base; } else base
