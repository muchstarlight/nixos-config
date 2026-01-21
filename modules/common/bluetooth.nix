{ config, pkgs, ... }:

{
  # Bluetooth configuration
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
}