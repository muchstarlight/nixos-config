{ config, lib, pkgs, ...}:
{
  # import hardware configuration
  imports = [ ./hardware-configuration.nix ];

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

  # network
  networking = {
    hostName = "laptop";
    networkmanager.enable = true;
  };

  # local 
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";

  # user
  users.users.muchstarlight = {
    isNormalUser = true; # 确保只设置其中一个
    home = "/home/muchstarlight";
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # pkgs
  environment.systemPackages = with pkgs; [
    wget
    vim
  ];

  # flake
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # sysrq
  boot.kernel.sysctl = { "kernel.sysrq" = 1; };

  # unfree
  nixpkgs.config.allowUnfree = true;

  # version
  system.stateVersion = "25.05";

}