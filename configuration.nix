{ config, lib, pkgs, ... }:

{ 
  imports = [ ./hardware-configuration.nix ];

  # network
  networking = {
      hostName = "nixos";
      networkmanager.enable = true;
  };

  # time
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";
  
  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.displayManager.sddm.wayland.enable = true;

  services.desktopManager.plasma6.enable = true;  

    programs.hyprland.enable = true;

  # 用户和组配置
  users.users.muchstarlight = {
    isNormalUser = true; # 确保只设置其中一个
    home = "/home/muchstarlight";
    group = "muchstarlight"; # 指定用户组
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # 创建用户组
  users.groups.muchstarlight = {};
  
  # 镜像地址  
  nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];

  # 预装工具
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    kitty
  ];

  nixpkgs.config.allowUnfree = true;

  # 系统版本
  system.stateVersion = "24.11";
}

