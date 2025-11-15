{ config, ... }:

{
  # unfree
  nixpkgs.config.allowUnfree = true;

   # desktop
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  programs.firefox.enable = true;

  # CUPS
  services.printing.enable = true;

  # touchpad
  services.libinput.enable = true;
  
  # bootloader (from nixos cn)
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  # network
  networking = {
    hostName = "desktop";
    networkmanager.enable = true;
  };
  
}
