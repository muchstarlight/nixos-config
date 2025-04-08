{ config, lib, pkgs, ... }:

{
  programs.niri.enable = true;
  programs.niri.packages = with pkgs; [
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