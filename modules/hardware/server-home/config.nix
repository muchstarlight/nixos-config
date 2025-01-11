{ config, lib, pkgs, ... }:
{
  # boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # network
  networking.hostName = "server";
  networking.networkmanager.enable = true;

  # local
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";

  # pkgs
  environment.systemPackages = with pkgs; [
    wget
    vim
  ];

  # services
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC4gq0lc/+Qowcjp/oiGvo3/VZ9Pgp41SJ/RdlvYhyLuQQVJE00rNN+qI/TBJ5yccN0K3eURx3fYVnyx2aBcjGgh3XDr+1ICj4WVudbZViXQMNeEV1QWH6d1aV1+lsmlcQWecUp7RtS11CKGGC3NdiPwuUz0XzIpYFMAj9QxSUFWr+N0FD371A5zGWHqlSbBg9KueJWcYlLSaGUqSw7gWc7w3V3PCZlswy2VFXAHJVcRetiQJnljXAI+BSvTa4WK+6QVjPY2tMGAfvSccDZGxQCj+oS29zso8EYg7GtS9RCNbYetVTD19CCfs2DodMieGfEK789SKlg6WRz+y6N8+1wFWDjxqvumuufTUA6XNCWJ5ovMs4v8ubXNAIf9Sq7WO6ftFrn84KfATd1K6/O6LapUBcg+qe88zGUxL7Uh6DAEGQQYCh0Mit5TRv6ROS5VUREUwn9blDr3+9WRUafHrXbqKIcaUS0t/zXPFDw335A4CQOv41uS6DO472vwSf6N2HqbaqgnhsQLmpGAZt3Z7hGhQeJoaMKq+9w+xyGL91WO6IclQRQ3pRwY+ARfQBhgU4Ang8Lt6DAFVRM6uHrGQE+LMndUlx7sIF4bv3/1/VMb7hPZIAICQd87+rkqNzmMq0wZGkqoRt13iL4NY+2HQMaobRlHA6b06JYc4pqgEkSoQ== muchstarlight@163.com"
    ];

  # version
  system.stateVersion = "25.04";
}