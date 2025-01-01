{ config, pkgs, ... }:

{
  # network
  networking = {
    hostName = "laptop";
    networkmanager.enable = true;
  };

  # time
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";

  # program
  environment.systemPackages = with pkgs; [
    wget
    git
    vim
  ];

  # flake
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

}
