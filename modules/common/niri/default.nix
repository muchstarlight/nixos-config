{ config, lib, pkgs, ... }:

{
  programs.niri.enable = true;
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