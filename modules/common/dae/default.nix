{ config, pkgs, ... }: {
  # Enable the dae service.
  services.dae = {
    enable = true;

    openFirewall = {
      enable = true;
      port = 12345;
    };
    disableTxChecksumIpGeneric = false;
    configFile = "/etc/dae/config.dae";
    assets = with pkgs; [ v2ray-geoip v2ray-domain-list-community ];
  };
}
