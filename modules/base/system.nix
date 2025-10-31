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

  # sysrq
  boot.kernel.sysctl = { "kernel.sysrq" = 1; };

  # version
  system.stateVersion = "25.05";

}