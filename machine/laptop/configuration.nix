{ config, lib, pkgs,  ... }:

{ 
  imports = [ 
    ./hardware-configuration.nix
    ./../modules
    ./nvidia.nix
    ];

  services.displayManager.sddm.enable = true;

  # boot
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      extraEntries = ''
        menuentry "Windows" {
          search --file --no-floppy --set=root /EFI/Microsoft/Boot/bootmgfw.efi
          chainloader (''${root})/EFI/Microsoft/Boot/bootmgfw.efi
          }
        '';
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

  # network
  networking = {
      hostName = "laptop";
      networkmanager.enable = true;
  };

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


  # 启用 sysrq 快捷键
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
  };

  # 软件
  environment.systemPackages = with pkgs; [
    # 代理
    clash-meta
    
    # 浏览器
    firefox
  ]; 

  programs.clash-verge.enable = true;
 
  # services.dae.enable = true; 

  # 开启非自由软件包
  nixpkgs.config.allowUnfree = true;

  # 系统版本
  system.stateVersion = "25.05";
}

