{ config, lib, pkgs, niri, ... }:
{
  imports = [
    ./laptop-specific.nix
    ./hardware-configuration.nix
    ./../../modules/common/dae
    ./../../modules/common/fcitx5
    ./../../modules/common/fhs
    ./../../modules/common/ChineseSoftware
    ./../../modules/base/system.nix
    ./../../modules/base/users.nix
  ];
}

