{ config, lib, pkgs, ... }:

{
  # NVIDIA显卡配置 (适用于Intel + NVIDIA Optimus笔记本)

  # 启用NVIDIA专有驱动
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # 使用最新稳定驱动
    # 既然在Arch下官方run文件有效，这里使用production或stable通常是最安全的
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # 必须使用专有驱动 (open = false)，否则RTX 40系列在某些移动端可能出现固件加载问题
    open = false;

    # 启用DRM内核模式设置
    modesetting.enable = true;

    # 启用电源管理
    # 注意：finegrained设置为true曾导致卡死，因此改为false以提高稳定性
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    # 启用NVIDIA设置工具
    nvidiaSettings = true;

    # Optimus配置
    prime = {
      # ！！！重要：Sync和Offload模式互斥，不能同时开启！！！
      
      # 模式1: Offload (默认推荐) - 平时使用核显，按需调用独显，省电。
      # 运行需要独显的程序时使用: nvidia-offload <command>
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      # 模式2: Sync - 独显一直工作，性能最好但耗电。
      # 如果需要切换到此模式，请将 offload.enable 改为 false，并取消下面 sync.enable 的注释
      # sync.enable = true;

      # Bus ID 配置 (请务必核对 `lspci` 输出)
      # Intel核显通常是 00:02.0 -> PCI:0:2:0
      intelBusId = "PCI:0:2:0"; 

      # NVIDIA独显通常是 01:00.0 -> PCI:1:0:0
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # 仅保留必要的环境变量，移除强制全局使用NVIDIA的设置
  environment.variables = {
    # 避免某些应用在Wayland下黑屏
    "LIBVA_DRIVER_NAME" = "nvidia";
    # 尝试修复Firefox/Electron应用的闪烁问题
    "NIXOS_OZONE_WL" = "1";
  };
  
  # 添加一个方便的脚本别名来运行独显程序 (如果 prime.offload.enableOffloadCmd 未自动生效)
  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "nvidia-offload" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export VK_DRIVER_FILES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json
      exec "$@"
    '')
  ];
}
