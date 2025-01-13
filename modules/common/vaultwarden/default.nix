{ config, pkgs, ... }:
{
  services.vaultwarden = {
    enable = true;
    extraConfig = ''
      DATABASE_URL=sqlite:./data/db.sqlite3
      ROCKET_PORT=8000
      ROCKET_LOG=info
      '';  
    };  
}