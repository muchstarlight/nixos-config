# 从未包装的 base 提取片段，避免通过 config 回读自己而递归。
{ lib, base }:
base.extendModules {
  modules = [
    {
      system.activationScripts = builtins.listToAttrs (
        map
          (
            name:
            let
              original = base.config.system.activationScripts.${name};
              entry = if builtins.isString original then { text = original; } else original;
            in
            {
              inherit name;
              value = lib.mkForce (
                entry
                // {
                  text = ''
                    if [ "''${IN_NIXOS_ENTER:-}" = 1 ]; then
                      ${if name == "specialfs" then "mkdir -p /run" else ":"}
                    else
                      ${entry.text}
                    fi
                  '';
                }
              );
            }
          )
          [
            "specialfs"
            "modprobe"
            "udevd"
          ]
      );
    }
  ];
}
