{ config, pkgs, ... }:

{
  # Time and language
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "zh_CN.UTF-8";

  # pkgs
  environment.systemPackages = with pkgs; [
    wget
    vim
  ];

  # flake
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Nix Store 优化
  nix.settings.auto-optimise-store = true; # 每次构建后自动去重
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # sysrq
  boot.kernel.sysctl = { "kernel.sysrq" = 1; };

  # version
  system.stateVersion = "25.05";

}