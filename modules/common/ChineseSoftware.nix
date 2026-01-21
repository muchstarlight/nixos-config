{ config, lib, pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.qq
	  pkgs.wechat
  ];
}