{ config, pkgs, ... }:

{
  services.dae = {
    enable = true;

    openFirewall = {
      enable = true;
      port = 7897;
    };
    package = inputs.daeuniverse.packages.x86_64-linux.dae;
    disableTxChecksumIpGeneric = false;
    configFile = "./config.dae";
    assets = with pkgs; [ v2ray-geoip v2ray-domain-list-community ];
  };
  services.daed = {
      enable = true;

      openFirewall = {
        enable = true;
        port = 12345;
      };
      package = inputs.daeuniverse.packages.x86_64-linux.daed;
      configDir = "/etc/daed";
      listen = "127.0.0.1:2023";
  };

}
