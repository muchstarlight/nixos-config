{ inputs, pkgs, ... }:
let
  piAgent = inputs.nixpkgs-network.legacyPackages.${pkgs.stdenv.hostPlatform.system}.pi-coding-agent;
in
{
  home.username = "muchstarlight";
  home.homeDirectory = "/home/muchstarlight";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;
  programs.fish.enable = true;

  home.packages = with pkgs; [
    piAgent
    nodejs_24
    obsidian
    yazi
    eza
    tmux
    starship
    uv
    dbus
  ];
}
