{ pkgs, config, libs, ... }:

{
  # package
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;  

  # Enable OpenGL
  hardware.graphics.enable = true;
  
  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];
  
  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;
    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement.enable = true;
    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;
    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;
    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    prime = { 
      sync.enable = true;

      # Make sure to use the correct Bus ID values for your system!
      intelBusId = "PCI:0:2:0"; # Swap with "intelBusId" if using Intel
      nvidiaBusId = "PCI:1:0:0";
    };
    
  };

  boot.initrd.kernelModules = [ "nvidia" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];

  boot.kernelParams = [ "modprobe.blacklist=nouveau" "nvidia-drm.modeset=1" ];

  #Screen Tearing Issues
   hardware.nvidia.forceFullCompositionPipeline = true;


}
