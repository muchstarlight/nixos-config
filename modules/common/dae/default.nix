{ config, pkgs, ... }: {
  # Enable the dae service.
  services.dae = {
    enable = true;

    openFirewall = {
      enable = true;
      port = 12345;
    };
  };
}
