{ config, lib, pkgs, niri, ... }:
{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.nvidia.acceptLicense = true;
  imports = [
    ./desktop-specific.nix
    ./hardware-configuration.nix
    ./../../modules/common/dae
    ./../../modules/common/fcitx5
    ./../../modules/common/fhs
    ./../../modules/base/system.nix
    ./../../modules/base/users.nix
    # ./../../modules/common/nvidia
  ];
}

