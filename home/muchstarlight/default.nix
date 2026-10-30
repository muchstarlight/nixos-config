{ inputs, pkgs, ... }:
let
  piAgent = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.pi-coding-agent;
in
{
  home.username = "muchstarlight";
  home.homeDirectory = "/home/muchstarlight";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;
  programs.fish.enable = true;
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    enableFishIntegration = true;
    pinentry.package = pkgs.pinentry-qt;
  };

  home.packages = with pkgs; [
    piAgent
    nodejs_24
    obsidian
    siyuan
    yazi
    eza
    tmux
    starship
    uv
    dbus
  ];
}
