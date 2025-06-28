{ config, lib, pkgs, ... }:
{
  imports = [
    ./../modules/laptop/hardware
    ./../modules/common/dae
    ./../modules/common/fcitx5
    ./../modules/common/fhs
  ];
}

