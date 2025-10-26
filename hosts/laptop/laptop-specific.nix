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
      extraEntries = ''
        menuentry "Windows" {
          search --file --no-floppy --set=root /EFI/Microsoft/Boot/bootmgfw.efi
          chainloader (''${root})/EFI/Microsoft/Boot/bootmgfw.efi
          }
      '';
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  # network
  networking = {
    hostName = "laptop";
    networkmanager.enable = true;
  };
  
}