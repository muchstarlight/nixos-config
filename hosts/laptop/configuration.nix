{ config, lib, pkgs, niri, ... }:
{
  imports = [
    ./laptop-specific.nix
    ./hardware-configuration.nix
    ./../../modules/common/dae.nix
    ./../../modules/common/fcitx5.nix
    ./../../modules/common/fhs.nix
    ./../../modules/common/ChineseSoftware.nix
    ./../../modules/common/audio.nix
    ./../../modules/common/bluetooth.nix
    ./../../modules/common/nvidia.nix    # NVIDIA显卡配置
    ./../../modules/base/system.nix
    ./../../modules/base/users.nix
    ./../../modules/base/security.nix
  ];
}

