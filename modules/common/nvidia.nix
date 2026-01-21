{ config, pkgs, ...}:

{
  # NVIDIA显卡配置 (适用于Intel + NVIDIA Optimus笔记本)
  # 注意：请根据您的PCI总线ID修改prime配置

  # 启用NVIDIA专有驱动
  services.xserver.videoDrivers = ["nvidia"];

  # 禁止开源驱动nouveau
  boot.blacklistedKernelModules = [ "nouveau" ];

  hardware.nvidia = {
    # 使用最新稳定驱动 (适配RTX 4050 Laptop GPU)
    # 可选: nvidiaPackages.beta (测试版), nvidiaPackages.production (稳定版)
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # 使用专有驱动，非开源驱动
    open = false;

    # 启用DRM内核模式设置 (改善启动画面和Wayland兼容性)
    modesetting.enable = true;

    # 启用电源管理 (笔记本节能)
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    # 启用NVIDIA设置工具
    nvidiaSettings = true;

    # Optimus配置 (Intel核显 + NVIDIA独显)
    prime = {
      # 启用同步显示 (独显通过核显输出) - 适用于Xorg
      sync.enable = true;

      # 启用GPU卸载模式 - 允许程序选择使用哪张显卡
      offload.enable = true;
      offload.enableOffloadCmd = true;

      # Intel集成显卡 (核显) - 负责显示输出
      # 使用以下命令获取PCI总线ID：
      #   lspci | grep -E "VGA|Display" | grep Intel
      # 输出示例：00:02.0 VGA compatible controller: Intel Corporation ...
      # 将 "00:02.0" 转换为 "PCI:0:2:0" 格式 (去掉点，冒号改为冒号)
      intelBusId = "PCI:0:2:0";  # 示例，请根据实际修改

      # NVIDIA独立显卡 - 负责渲染
      # 使用以下命令获取PCI总线ID：
      #   lspci | grep -E "VGA|3D|Display" | grep NVIDIA
      # 输出示例：01:00.0 VGA compatible controller: NVIDIA Corporation ...
      # 将 "01:00.0" 转换为 "PCI:1:0:0" 格式
      nvidiaBusId = "PCI:1:0:0";  # 示例，请根据实际修改
    };
  };

  # 环境变量 (可选，改善兼容性)
  environment.variables = {
    # 使用NVIDIA作为主要渲染器
    "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";
    # 强制使用NVIDIA显卡 (某些应用)
    "GBM_BACKEND" = "nvidia-drm";
    # Wayland相关
    "WLR_NO_HARDWARE_CURSORS" = "1";
    # 避免某些应用黑屏
    "LIBVA_DRIVER_NAME" = "nvidia";
  };

  # 内核参数 (改善兼容性)
  boot.kernelParams = [
    # 禁用Nouveau驱动
    "modprobe.blacklist=nouveau"
    # 启用NVIDIA DRM
    "nvidia-drm.modeset=1"
  ];

  # 服务配置
  services.xserver.displayManager.sessionCommands = ''
    # 设置NVIDIA为默认渲染器
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
  '';
}
