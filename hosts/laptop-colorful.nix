{ config, lib, pkgs, ... }:
{
  imports = [
    ./../modules/hardware/laptop-colorful
    ./../modules/common/dae
    ./../modules/common/fcitx5
    ./../modules/common/fhs
    ./../modules/common/niri
  ];
}

