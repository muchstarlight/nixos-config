{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  privateDirectory = "/var/lib/nixos-private";
  switchConfig = "${privateDirectory}/home-network-switch.json";
  controller = pkgs.writeShellApplication {
    name = "home-network-switch";
    runtimeInputs = with pkgs; [
      iproute2
      networkmanager
      wireguard-tools
      iputils
      getent
    ];
    text = ''
      exec ${pkgs.python3}/bin/python3 ${../../files/network/home-network-switch.py} "$@" --config ${switchConfig}
    '';
  };
  switchService = {
    after = [
      "NetworkManager.service"
      "wg-quick-Home.service"
    ];
    unitConfig.ConditionPathExists = "/etc/home-network-switch/enabled";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${controller}/bin/home-network-switch apply";
      TimeoutStartSec = 60;
      UMask = "0077";
    };
  };
in
{
  services.dae = {
    enable = true;
    package = inputs.nixpkgs-network.legacyPackages.${pkgs.stdenv.hostPlatform.system}.dae;
    configFile = "${privateDirectory}/dae/config.dae";
    openFirewall.enable = false;
  };

  networking.wg-quick.interfaces.Home = {
    configFile = "${privateDirectory}/wireguard/Home.conf";
    autostart = true;
  };
  networking.networkmanager.unmanaged = [ "interface-name:Home" ];
  systemd.services.wg-quick-Home = {
    # 首次 DNS 未就绪时由 systemd 重试，避免阻塞在无限解析循环中。
    environment.WG_ENDPOINT_RESOLUTION_RETRIES = "3";
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10s";
      TimeoutStartSec = "45s";
    };
  };
  networking.firewall = {
    enable = true;
    # WireGuard 与透明代理可能产生非对称返回路径。
    checkReversePath = "loose";
  };

  boot.kernelModules = [
    "tun"
    "wireguard"
    "sch_ingress"
    "cls_bpf"
  ];
  environment.systemPackages = [ controller ];
  system.build.networkController = controller;
  systemd.tmpfiles.rules = [
    "d ${privateDirectory} 0700 root root -"
    "d ${privateDirectory}/dae 0700 root root -"
    "d ${privateDirectory}/wireguard 0700 root root -"
    "d /etc/home-network-switch 0700 root root -"
    "d /run/home-network-switch 0700 root root -"
  ];

  systemd.services.home-network-switch = switchService // {
    description = "按物理网络更新家中 WireGuard 分流";
  };
  systemd.services.home-network-switch-boot = lib.recursiveUpdate switchService {
    description = "启动 dae 前初始化家中 WireGuard 分流";
    wants = [
      "network-online.target"
      "wg-quick-Home.service"
      "home-network-switch.service"
    ];
    after = [
      "network-online.target"
      "NetworkManager.service"
      "wg-quick-Home.service"
      "home-network-switch.service"
    ];
    # 实际切换由上面的依赖作业完成；不再执行控制器，避免竞争非阻塞锁后提前放行 dae。
    serviceConfig.ExecStart = "${pkgs.coreutils}/bin/true";
    before = [ "dae.service" ];
  };
  systemd.timers.home-network-switch = {
    description = "定期维护家中 WireGuard Endpoint 和路由";
    wantedBy = [ "timers.target" ];
    unitConfig.ConditionPathExists = "/etc/home-network-switch/enabled";
    timerConfig = {
      OnBootSec = "30s";
      OnUnitInactiveSec = "30s";
      AccuracySec = "3s";
      Unit = "home-network-switch.service";
    };
  };

  networking.networkmanager.dispatcherScripts = [
    {
      type = "basic";
      source = pkgs.writeShellScript "home-network-switch-dispatcher" ''
        case "''${2:-}" in
          up|down|dhcp4-change|dhcp6-change|connectivity-change|dns-change|reapply)
            if [[ -f /etc/home-network-switch/enabled ]]; then
              ${pkgs.systemd}/bin/systemctl --no-block start home-network-switch.service
            fi
            ;;
        esac
      '';
    }
  ];

  systemd.services.dae = {
    wants = [ "home-network-switch-boot.service" ];
    after = [ "home-network-switch-boot.service" ];
    unitConfig.RequiresMountsFor = [ privateDirectory ];
  };
  systemd.services.nix-daemon = {
    wants = [ "dae.service" ];
    after = [ "dae.service" ];
  };
}
