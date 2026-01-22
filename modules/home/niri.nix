{ config, pkgs, lib, ... }:

{
  programs.niri = {
    enable = true;
    
    # 引用您的配置文件
    config = builtins.readFile ./niri/config.kdl;
  };

  # 确保安装了必要的包
  home.packages = with pkgs; [
    xwayland-satellite # XWayland 支持
    swaybg # 壁纸
    swaylock # 锁屏
    wl-clipboard # 剪贴板
  ];

  # 可以在这里添加环境变量
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Electron 应用使用 Wayland
  };
}
