{ config, lib, pkgs, ... }:
{
  imports = [
    ./laptop-specific.nix
    ./hardware-configuration.nix
    ./../../modules/hardware/laptop
    ./../../modules/common/dae
    ./../../modules/common/fcitx5
    ./../../modules/common/fhs
    ./../../modules/common/ChineseSoftware
    ./../../modules/common/fcitx5
  ];
}

