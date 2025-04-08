{ config, lib, pkgs, ... }:
{
  imports = [
    ./../modules/hardware
    ./../modules/common/dae
    ./../modules/common/fcitx5
    ./../modules/common/fhs
    ./../modules/common/niri
  ];
}

