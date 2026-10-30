{
  inputs,
  system,
  laptop,
}:
let
  pkgs = inputs.nixpkgs.legacyPackages.${system};
  unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
  assets = pkgs.symlinkJoin {
    name = "dae-assets";
    paths = laptop.config.services.dae.assets;
  };
in
{
  nvidia-open = laptop.config.hardware.nvidia.package.open;
  noctalia = inputs.noctalia.packages.${system}.default;
  inherit (pkgs) niri;
  installer-tools = pkgs.nixos-install-tools;
  dae = unstable.dae;
  pi = unstable.pi-coding-agent;
  vscodium = unstable.vscodium;
  localsend = laptop.config.programs.localsend.package;
  zen-browser = inputs.zen-browser.packages.${system}.beta;
  network-controller = laptop.config.system.build.networkController;
  network-assets = assets;
  network-bootstrap = pkgs.symlinkJoin {
    name = "nixos-network-bootstrap";
    paths = [
      unstable.dae
      laptop.config.system.build.networkController
      assets
    ]
    ++ (with pkgs; [
      wireguard-tools
      iproute2
      networkmanager
      openresolv
      curl
    ]);
  };
  network-service-units = pkgs.linkFarm "network-service-units" (
    map
      (name: {
        inherit name;
        path = laptop.config.systemd.units.${name}.unit;
      })
      [
        "dae.service"
        "wg-quick-Home.service"
        "home-network-switch-boot.service"
        "home-network-switch.service"
        "home-network-switch.timer"
      ]
  );
}
