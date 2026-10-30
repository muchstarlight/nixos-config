{
  inputs,
  system,
  laptop,
  installedLaptop,
  mkHost,
}:
let
  pkgs = inputs.nixpkgs.legacyPackages.${system};
  unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
  zen = inputs.zen-browser.packages.${system}.beta;
  noctalia = inputs.noctalia.packages.${system}.default;
  cfgController = laptop.config.system.build.networkController;
  isolatedHost = mkHost {
    inherit system;
    hostModule = { ... }: {
      imports = [ ../modules/nixos/base.nix ];
      boot.isContainer = true;
      system.stateVersion = "26.05";
    };
  };
  isolatedWithHome = mkHost {
    inherit system;
    hostModule = { ... }: {
      imports = [ ../modules/nixos/base.nix ];
      boot.isContainer = true;
      system.stateVersion = "26.05";
      users.users.muchstarlight.isNormalUser = true;
    };
    homeUsers.muchstarlight = import ../home/muchstarlight;
  };
  noLaptopPolicy =
    cfg:
    !cfg.services.dae.enable
    && !cfg.programs.localsend.enable
    && cfg.networking.wg-quick.interfaces == { }
    && cfg.fileSystems == { }
    && !builtins.hasAttr "nixos-config-link" cfg.system.activationScripts
    && !builtins.hasAttr "home-network-switch" cfg.systemd.services
    && !(builtins.elem "nvidia" cfg.services.xserver.videoDrivers)
    && builtins.all (rule: !(builtins.elem "muchstarlight" rule.users)) cfg.security.sudo.extraRules;
in
{
  host-isolation =
    let
      cfg = isolatedHost.config;
      withHome = isolatedWithHome.config;
      homeCfg = withHome.home-manager.users.muchstarlight;
    in
    assert noLaptopPolicy cfg;
    assert noLaptopPolicy withHome;
    assert !builtins.hasAttr "muchstarlight" cfg.users.users;
    assert !builtins.hasAttr "home-manager" cfg;
    assert !builtins.hasAttr "niri" homeCfg.xdg.configFile;
    assert !builtins.hasAttr "niri-output-policy" homeCfg.systemd.user.services;
    assert !builtins.hasAttr "rebuild" homeCfg.programs.fish.shellAliases;
    pkgs.runCommand "host-isolation-check" { } ''
      touch "$out"
    '';

  maintenance =
    let
      cfg = installedLaptop.config;
      command = "/run/current-system/sw/bin/nixos-rebuild switch --flake /etc/nixos";
      rules = builtins.filter (
        rule: builtins.elem "muchstarlight" rule.users
      ) cfg.security.sudo.extraRules;
      script = pkgs.writeText "nixos-config-link.sh" cfg.system.activationScripts.nixos-config-link.text;
    in
    assert cfg.security.sudo.wheelNeedsPassword;
    assert builtins.length rules == 1;
    assert (builtins.head rules).runAs == "root";
    assert
      (builtins.head rules).commands == map
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
    assert cfg.home-manager.users.muchstarlight.programs.fish.shellAliases.rebuild == "sudo ${command}";
    pkgs.runCommand "nixos-maintenance-check" { nativeBuildInputs = [ pkgs.python3 ]; } ''
      export PYTHONDONTWRITEBYTECODE=1
      bash -n ${script}
      python3 ${../tests/maintenance.py} ${script}
      touch "$out"
    '';

  install-layout =
    let
      cfg = installedLaptop.config;
    in
    assert cfg.fileSystems."/".device == "/dev/disk/by-uuid/b0b747b2-41dd-4504-aeb3-f2c5de97318d";
    assert builtins.elem "subvol=@nixos" cfg.fileSystems."/".options;
    assert builtins.elem "subvol=@home" cfg.fileSystems."/home".options;
    assert cfg.fileSystems."/boot/efi".device == "/dev/disk/by-uuid/E14E-0423";
    assert !cfg.fileSystems."/".autoFormat;
    assert !cfg.fileSystems."/boot/efi".autoFormat;
    assert !builtins.hasAttr "00-migration-preview-guard" cfg.system.activationScripts;
    assert cfg.boot.loader.grub.enable;
    assert builtins.any (entry: entry.efiBootloaderId == "NixOS") cfg.boot.loader.grub.mirroredBoots;
    pkgs.runCommand "nixos-install-layout-check" { } ''
      touch "$out"
    '';

  default-editor =
    let
      cfg = installedLaptop.config;
    in
    assert cfg.programs.vim.enable;
    assert cfg.programs.vim.defaultEditor;
    assert cfg.environment.sessionVariables.EDITOR == "vim";
    assert cfg.environment.sessionVariables.VISUAL == "vim";
    pkgs.runCommand "default-editor-check" { } ''
      test -x ${cfg.programs.vim.package}/bin/vim
      touch "$out"
    '';

  grub-entries =
    let
      cfg = installedLaptop.config;
      entries = cfg.boot.loader.grub.extraEntries;
      entriesFile = pkgs.writeText "grub-extra-entries.cfg" entries;
    in
    assert !cfg.boot.loader.grub.useOSProber;
    assert pkgs.lib.hasInfix "--fs-uuid --set=windowsesp 4BA0-87E9" entries;
    assert pkgs.lib.hasInfix "chainloader ($windowsesp)/EFI/Microsoft/Boot/bootmgfw.efi" entries;
    assert pkgs.lib.hasInfix "configfile ($archroot)/@/boot/grub/grub.cfg" entries;
    assert !laptop.config.boot.loader.grub.enable;
    assert laptop.config.boot.loader.grub.extraEntries == "";
    pkgs.runCommand "grub-entries-check" { nativeBuildInputs = [ pkgs.grub2_efi ]; } ''
      grub-script-check ${entriesFile}
      touch "$out"
    '';

  gpg-config =
    let
      homeCfg = installedLaptop.config.home-manager.users.muchstarlight;
      agent = homeCfg.services.gpg-agent;
      agentConfig =
        pkgs.writeText "gpg-agent.conf"
          homeCfg.home.file."${homeCfg.programs.gpg.homedir}/gpg-agent.conf".text;
    in
    assert homeCfg.programs.gpg.enable;
    assert agent.enable;
    assert agent.enableFishIntegration;
    assert !agent.enableSshSupport;
    assert builtins.hasAttr "gpg-agent" homeCfg.systemd.user.sockets;
    assert pkgs.lib.hasInfix "set -gx GPG_TTY (tty)" homeCfg.programs.fish.interactiveShellInit;
    pkgs.runCommand "gpg-config-check" { } ''
      test -x ${homeCfg.programs.gpg.package}/bin/gpg
      test -x ${agent.pinentry.package}/bin/${agent.pinentry.program}
      grep -Fx 'pinentry-program ${agent.pinentry.package}/bin/${agent.pinentry.program}' ${agentConfig}
      touch "$out"
    '';

  session-config =
    let
      cfg = laptop.config;
    in
    assert cfg.programs.niri.enable;
    assert !cfg.services.xserver.enable;
    assert !cfg.services.displayManager.sddm.enable;
    assert !cfg.services.greetd.enable;
    assert cfg.services.getty.autologinUser == null;
    assert builtins.elem "vmd" cfg.boot.initrd.availableKernelModules;
    assert builtins.all (name: builtins.elem name cfg.boot.kernelModules) [
      "nvidia"
      "nvidia_modeset"
      "nvidia_drm"
    ];
    pkgs.runCommand "tty-niri-session-check" { } ''
      test -x ${pkgs.niri}/bin/niri-session
      test -f ${pkgs.niri}/lib/systemd/user/niri.service
      test -f ${cfg.i18n.inputMethod.package}/etc/xdg/autostart/org.fcitx.Fcitx5.desktop
      if grep -q '^Hidden=true' ${cfg.i18n.inputMethod.package}/etc/xdg/autostart/org.fcitx.Fcitx5.desktop; then
        exit 1
      fi
      touch "$out"
    '';

  network-config =
    let
      units = laptop.config.systemd.services;
    in
    assert units.wg-quick-Home.serviceConfig.Restart == "on-failure";
    assert units.wg-quick-Home.environment.WG_ENDPOINT_RESOLUTION_RETRIES == "3";
    assert builtins.elem "home-network-switch.service" units.home-network-switch-boot.wants;
    assert builtins.elem "home-network-switch.service" units.home-network-switch-boot.after;
    assert
      units.home-network-switch-boot.serviceConfig.ExecStart
      != units.home-network-switch.serviceConfig.ExecStart;
    pkgs.runCommand "network-config-check" { nativeBuildInputs = [ pkgs.python3 ]; } ''
      export PYTHONDONTWRITEBYTECODE=1
      python3 ${../tests/network-switch.py} ${../files/network/home-network-switch.py}
      python3 ${../tests/network-provision.py} ${../scripts/provision-network-secrets.py}
      python3 ${../tests/network-runtime.py} ${cfgController}/bin/home-network-switch
      python3 ${../scripts/provision-network-secrets.py} --help > /dev/null
      touch "$out"
    '';

  application-sources =
    let
      cfg = installedLaptop.config;
      homePackages = map toString cfg.home-manager.users.muchstarlight.home.packages;
    in
    assert cfg.services.dae.package.drvPath == unstable.dae.drvPath;
    assert cfg.programs.localsend.enable;
    assert cfg.programs.localsend.openFirewall;
    assert cfg.programs.localsend.package.drvPath == unstable.localsend.drvPath;
    assert builtins.elem 53317 cfg.networking.firewall.allowedTCPPorts;
    assert builtins.elem 53317 cfg.networking.firewall.allowedUDPPorts;
    assert builtins.all (package: builtins.elem (toString package) homePackages) [
      unstable.pi-coding-agent
      unstable.vscodium
      zen
    ];
    pkgs.runCommand "application-sources-check" { } ''
      test -x ${unstable.vscodium}/bin/codium
      test -x ${cfg.programs.localsend.package}/bin/localsend_app
      test -x ${zen}/bin/zen-beta
      touch "$out"
    '';

  desktop-config =
    let
      homeCfg = installedLaptop.config.home-manager.users.muchstarlight;
      managedNiri = homeCfg.xdg.configFile.niri.source;
      managedNoctalia = homeCfg.xdg.configFile."noctalia/config.toml".source;
    in
    pkgs.runCommand "desktop-config-check"
      {
        nativeBuildInputs = [
          pkgs.niri
          pkgs.python3
          noctalia
        ];
      }
      ''
        export HOME="$TMPDIR/home"
        export XDG_CONFIG_HOME="$HOME/.config"
        export XDG_STATE_HOME="$HOME/.local/state"
        export PYTHONDONTWRITEBYTECODE=1
        mkdir -p "$XDG_CONFIG_HOME" "$XDG_STATE_HOME"
        niri validate -c ${managedNiri}/config.kdl
        noctalia config validate ${managedNoctalia}
        python3 ${../tests/output-policy.py} ${../files/niri/scripts/output-policy.py}
        touch "$out"
      '';
}
