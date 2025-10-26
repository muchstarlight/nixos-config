{ config, ... }:

{
  # User
  users.users.muchstarlight = {
    isNormalUser = true;
    home = "/home/muchstarlight";
    extraGroups = [ "wheel" "networkmanager" ];
  };
}