{ lib, ... }:
let
  systemDevice = "/dev/disk/by-uuid/b0b747b2-41dd-4504-aeb3-f2c5de97318d";
in
{
  fileSystems."/" = {
    device = systemDevice;
    fsType = "btrfs";
    options = [
      "subvol=@nixos"
      "compress=zstd:1"
      "noatime"
    ];
  };
  fileSystems."/home" = {
    device = systemDevice;
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd:1"
      "noatime"
    ];
  };
  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/E14E-0423";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  # 内核和 initrd 留在 Btrfs 根，避免占满 EFI 分区。
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi = {
    efiSysMountPoint = "/boot/efi";
    canTouchEfiVariables = true;
  };
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = false;
    useOSProber = false;
    configurationLimit = 10;
    mirroredBoots = lib.mkForce [
      {
        path = "/boot";
        devices = [ "nodev" ];
        efiSysMountPoint = "/boot/efi";
        efiBootloaderId = "NixOS";
      }
    ];
    extraEntries = ''
      menuentry 'Arch Linux（迁移回退）' {
        insmod btrfs
        search --no-floppy --fs-uuid --set=archroot b0b747b2-41dd-4504-aeb3-f2c5de97318d
        configfile ($archroot)/@/boot/grub/grub.cfg
      }
    '';
  };
  boot.loader.timeout = 5;
}
