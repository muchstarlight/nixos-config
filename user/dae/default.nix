{ config, pkgs, ... }:

{
  services.dae = {
    enable = true;

    openFirewall = {
      enable = true;
      port = 7897;
    };
  };

}
