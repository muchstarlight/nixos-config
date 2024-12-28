{ pkgs, config, libs, ... }:

{
  # boot
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

  boot.kernelParams = [
    "loglevel=7"
    # Optional: To ignore the log level setting and always print all messages
    "ignore_loglevel"
    "modeset=1"
  ];

}
