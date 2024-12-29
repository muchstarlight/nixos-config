{ config, lib, pkgs, inputs,... }:

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

  # sddm
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;

  # kde
  services.desktopManager.plasma6.enable = true;  

  # hyprland
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
    clash-verge-rev
    inputs.nixvim.packages."${pkgs.system}".nixvim
  ]; 

  programs.clash-verge.enable = true;

  # 开启非自由软件包
  nixpkgs.config.allowUnfree = true;

  # 系统版本
  system.stateVersion = "25.05";
}

