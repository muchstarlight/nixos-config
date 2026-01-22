{ config, pkgs, ... }:

{
  # Bluetooth configuration
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true; # 开机自动开启蓝牙
  };
  services.blueman.enable = true;
}