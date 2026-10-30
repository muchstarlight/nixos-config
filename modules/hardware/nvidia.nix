{ config, pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = [ pkgs.intel-media-driver ];
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  # 未启用 Xorg 时 NixOS 不会自动加载这些模块，TTY 会话仍需 DRM 节点。
  boot.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_drm"
  ];

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    # 使用目标内核的构建函数，避免驱动与内核不匹配。
    # 精确散列来源：nixpkgs 31ecbaca1bdefa45dffc409f0250bd8039ea0010。
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "615.78.08";
      sha256_64bit = "sha256-Pj9t3cLudnoIGFMAr3vjyyhuznZpjS3eNSRZl4LQf/4=";
      sha256_aarch64 = "sha256-UHYBE1AYHoGgMfD9AS/jX+S+N8eCDWUft6qolK9Eejc=";
      openSha256 = "sha256-HBINiOjL0ZJLIAJeNIBYHBnwgUXtNwPPtnFpAI1YwF4=";
      settingsSha256 = "sha256-inDRpG02sdDgHmlqgu/DsgK8OFdOt1fZIYyXdhlGC/c=";
      persistencedSha256 = "sha256-RzeR6Ldct6MUxjnXRyThdh5Y3jjMehTVg85MtwuWNX4=";
    };

    # 615 open 使用内核通知路径，不与旧睡眠服务混用。
    powerManagement.enable = false;
    powerManagement.kernelSuspendNotifier = true;
    moduleParams.nvidia = {
      NVreg_UseKernelSuspendNotifiers = 1;
      NVreg_PreserveVideoMemoryAllocations = 2;
      NVreg_TemporaryFilePath = "/var/tmp";
    };
  };
}
