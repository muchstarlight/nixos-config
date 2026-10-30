{
  inputs,
  osConfig,
  pkgs,
  ...
}:
let
  noctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  imports = [ ../../home/muchstarlight ];

  programs.fish.shellAliases.rebuild = "sudo /run/current-system/sw/bin/nixos-rebuild switch --flake /etc/nixos";
  home.packages = [ noctalia ];

  xdg.configFile."niri" = {
    source = ../../files/niri;
    recursive = true;
  };
  xdg.configFile."noctalia/config.toml".source = ../../files/noctalia/config.toml;
  xdg.configFile."fcitx5/profile".source = ../../files/fcitx5/profile;
  # 覆盖旧 home 中的 Hidden=true 项，避免系统 Fcitx5 自启动被屏蔽。
  xdg.configFile."autostart/org.fcitx.Fcitx5.desktop".source =
    "${osConfig.i18n.inputMethod.package}/etc/xdg/autostart/org.fcitx.Fcitx5.desktop";

  systemd.user.services.niri-output-policy = {
    Unit = {
      Description = "Niri 外屏优先与内屏自动恢复";
      After = [ "niri.service" ];
      PartOf = [ "niri.service" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.python3}/bin/python3 ${../../files/niri/scripts/output-policy.py}";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "niri.service" ];
  };
}
