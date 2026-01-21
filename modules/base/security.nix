{ config, pkgs, ... }:

{
  # Basic security settings
  services.openssh.enable = false;
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ ];
  networking.firewall.allowedUDPPorts = [ ];
}