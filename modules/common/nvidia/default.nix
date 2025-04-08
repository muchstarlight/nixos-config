{ config, pkgs, ...}:

{
  # nvidia
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    # version
    package = config.boot.kernelPackages.nvidiaPackages.production;
    open = false;
    prime = {
      offload = {
			  enable = true;
			  enableOffloadCmd = true;
		  };

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
