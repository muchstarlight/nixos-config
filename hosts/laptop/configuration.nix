{
  migrationPreview ? true,
  lib,
  ...
}:
{
  imports = [
    ./hardware-common.nix
    (if migrationPreview then ./hardware-preview.nix else ./hardware-install.nix)
    ../../modules/nixos/base.nix
    ../../modules/hardware/nvidia.nix
    ../../modules/nixos/desktop.nix
    ./network.nix
    ./users.nix
    ./maintenance.nix
  ];

  hardware.i2c.enable = true;
  networking.hostName = "laptop";
  time.timeZone = "Asia/Shanghai";

  system.stateVersion = "26.05";

  system.activationScripts."00-migration-preview-guard" = lib.mkIf migrationPreview {
    text = ''
      echo 'laptop-preview 使用占位根设备，禁止激活。' >&2
      exit 1
    '';
  };

  warnings = lib.optional migrationPreview (
    "laptop-preview 使用占位根文件系统，不能直接运行 nixos-install 或 nixos-rebuild switch。"
  );
}
