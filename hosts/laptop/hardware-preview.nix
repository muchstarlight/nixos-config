{ ... }:
{
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS-PREPARATION-ONLY";
    fsType = "btrfs";
    options = [
      "compress=zstd:1"
      "noatime"
    ];
  };
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;
}
