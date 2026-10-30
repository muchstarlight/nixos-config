{ ... }:
{
  security.sudo.extraRules = [
    {
      users = [ "muchstarlight" ];
      runAs = "root";
      commands =
        map
          (action: {
            command = "/run/current-system/sw/bin/nixos-rebuild ${action} --flake /etc/nixos";
            options = [
              "NOPASSWD"
              "NOSETENV"
            ];
          })
          [
            "switch"
            "dry-activate"
            "test"
          ];
    }
  ];

  system.activationScripts.nixos-config-link = {
    deps = [ "etc" ];
    text = ''
      config_link=/etc/nixos
      config_target=/home/muchstarlight/nixos-config
      config_backup=/etc/nixos.before-symlink-20261030
      if [ -L "$config_link" ]; then
        if [ "$(readlink "$config_link")" != "$config_target" ]; then
          echo '已有不同的 /etc/nixos 符号链接，停止自动修改。' >&2
          exit 1
        fi
      elif [ -d "$config_link" ]; then
        if [ -e "$config_backup" ] || [ -L "$config_backup" ]; then
          echo '/etc/nixos 的备份位置已存在，停止以免覆盖。' >&2
          exit 1
        fi
        mv "$config_link" "$config_backup"
        ln -s "$config_target" "$config_link"
      elif [ -e "$config_link" ]; then
        echo '/etc/nixos 不是目录或符号链接，停止自动修改。' >&2
        exit 1
      else
        ln -s "$config_target" "$config_link"
      fi
    '';
  };
}
