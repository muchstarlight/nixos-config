{ lib, pkgs, ... }:
{
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    # 两块 NVMe 均位于 Intel VMD 控制器后，必须在早期启动阶段提供驱动。
    "vmd"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.sof-firmware ];
  boot.kernelPackages = pkgs.linuxPackages_zen;

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
