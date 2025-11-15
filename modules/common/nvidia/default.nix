{ config, pkgs, ...}:

{
  # nvidia
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    # version
    package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
    open = false;
  };
}
