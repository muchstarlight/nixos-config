{ config, lib, pkgs, ... }:

{
  # Enable the niri service.
  programs.niri = {
    enable = true;
    package = pkgs.niri-stable;
  };

  environment.systemPackages = with pkgs; [
    fuzzel
    mako
    waybar
    xdg-desktop-portal-gtk
    xdg-desktop-portal-gnome
    swaybg
    swayidle
    swaylock
  ];
  
  services.xserver.displayManager.gdm.enable = true;

}