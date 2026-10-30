{ pkgs, ... }:
let
  accountFile = "/var/lib/nixos-private/accounts/muchstarlight.hash";
in
{
  users.mutableUsers = true;
  users.groups.muchstarlight.gid = 1000;
  users.users.muchstarlight = {
    isNormalUser = true;
    uid = 1000;
    group = "muchstarlight";
    hashedPasswordFile = accountFile;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "render"
      "i2c"
    ];
    shell = pkgs.fish;
  };
}
