{ config, lib, pkgs, ... }:
{
  imports =
    [ 
      ./../modules/hardware/server-aliyun
      ./../modules/common/vaultwarden
    ];
}


