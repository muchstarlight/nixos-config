{ config, lib, pkgs, ... }:
{
  # boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # local
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";

  # pkgs
  environment.systemPackages = with pkgs; [
    vim
    wget
  ];

  # services
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCaUiop2tOD8sJAf87lC6Fz8iVbApUcwRgfP3OlL4aaveEKzmYSlcOOxgWLrioMDDgpL20gn3HVGBsrHo1CJrlR7nQ7/Ux3C/9jPp1nOVyYlF64o88qRpdYiwbg5qyZQqmUPhRST5EIMgbNPmichDS/RupmcwZV9GVYJ5IyT9Q+Y2r1cXtpF+eF80rvhAj4iQjN6HZJ+B2G6l9hUt08ErImawFheoageWqnosVwMCYzTMRUVSn/YhSk0nncCVhb4fJ3vFQYOQ1uXKPSVBdn9aMKryMQrK4S3r7VIGjwf78Gk99ywptCC8WJSNoYipj7pgQ84D5ec1YnsD/YkvRezjWQS6uro89ad6WdVZSaF7NQTcWg+7AJ2KjAoWQlIjfAnAQL2eCGjpp9Xv6UYCtwWQZFwNDK3kTlI4sq+mG+VzYkZfZHye7/alJLYC8MfKBDAN0kRp+TyT4+GJg7VJWHGx4dju7B6o/4zX6PMb+avDTjcRFxMf617eruH+jTyCxFlWlF//rF8J/ZqVUNkexY2hSYK4i2uc7Ch54JXKc0Myydf8cx2pAG6wGjO56rIow+5j9W2hkFDbm6JtljEg4JqJskWctojlLr5IJMwMYJJogodkKTKMRJOQ2KfYS6hvlw+qTLkTlOfPRyE+BjwxjOePywE/yF3vB/xp5nE6GqGTUvAw== muchstarlight@163.com"
  ];
  
  # version
  system.stateVersion = "24.11";
}