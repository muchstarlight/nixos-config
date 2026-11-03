{ lib, pkgs, ... }:
let
  systemDevice = "/dev/disk/by-uuid/b0b747b2-41dd-4504-aeb3-f2c5de97318d";
  efiUuid = "E14E-0423";
  efiMountPoint = "/boot/efi";
  selectionEnvPath = "/EFI/NixOS/selection.env";
  saveSelection = ''
    function savedefault {
      if [ -z "$boot_once" -a -n "$selection_esp" ]; then
        if [ "$chosen" = nixos -o "$chosen" = windows ]; then
          if [ -s "$selection_env" ]; then
            set saved_entry="$chosen"
            save_env --file="$selection_env" saved_entry
          fi
        fi
      fi
    }
  '';
in
{
  fileSystems."/" = {
    device = systemDevice;
    fsType = "btrfs";
    options = [
      "subvol=@nixos"
      "compress=zstd:1"
      "noatime"
    ];
  };
  fileSystems."/home" = {
    device = systemDevice;
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd:1"
      "noatime"
    ];
  };
  fileSystems.${efiMountPoint} = {
    device = "/dev/disk/by-uuid/${efiUuid}";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  # 内核和 initrd 留在 Btrfs 根，避免占满 EFI 分区。
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi = {
    efiSysMountPoint = efiMountPoint;
    canTouchEfiVariables = true;
  };
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = false;
    useOSProber = false;
    configurationLimit = 10;
    default = "saved";
    entryOptions = "--class nixos --unrestricted --id nixos";
    # Btrfs 不支持 GRUB 写入环境块，将选择记录放在 FAT ESP。
    extraConfig = ''
      insmod part_gpt
      insmod fat
      set selection_esp=
      search --no-floppy --fs-uuid --set=selection_esp ${efiUuid}
      set selection_env="($selection_esp)${selectionEnvPath}"
      set saved_entry=nixos
      if [ -n "$selection_esp" ]; then
        if [ -s "$selection_env" ]; then
          load_env --file="$selection_env" saved_entry
        fi
      fi
      if [ -z "$boot_once" ]; then
        if [ "$saved_entry" = windows ]; then
          set default=windows
        else
          set default=nixos
        fi
      fi
      ${saveSelection}
    '';
    extraInstallCommands = ''
      selection_env=${lib.escapeShellArg "${efiMountPoint}${selectionEnvPath}"}
      if [ "$(${pkgs.util-linux}/bin/findmnt --noheadings --output UUID --mountpoint ${lib.escapeShellArg efiMountPoint})" != ${lib.escapeShellArg efiUuid} ]; then
        echo "Refusing to write GRUB selection: expected ESP is not mounted at ${efiMountPoint}" >&2
        exit 1
      fi
      mkdir -p "$(dirname "$selection_env")"
      if [ -e "$selection_env" ]; then
        ${pkgs.grub2_efi}/bin/grub-editenv "$selection_env" list > /dev/null
      else
        ${pkgs.grub2_efi}/bin/grub-editenv "$selection_env" create
      fi
    '';
    mirroredBoots = lib.mkForce [
      {
        path = "/boot";
        devices = [ "nodev" ];
        efiSysMountPoint = efiMountPoint;
        efiBootloaderId = "NixOS";
      }
    ];
    extraEntries = ''
      menuentry 'Windows Boot Manager' --class windows --id windows {
        savedefault
        insmod part_gpt
        insmod fat
        insmod chain
        # GRUB 2.12 从 root 获取传给 EFI 程序的设备句柄。
        search --no-floppy --fs-uuid --set=root 4BA0-87E9
        chainloader /EFI/Microsoft/Boot/bootmgfw.efi
      }
      menuentry 'Arch Linux（迁移回退）' {
        insmod btrfs
        search --no-floppy --fs-uuid --set=archroot b0b747b2-41dd-4504-aeb3-f2c5de97318d
        configfile ($archroot)/@/boot/grub/grub.cfg
        # 菜单项内不能直接定义函数，用 eval 恢复被其他配置覆盖的保存逻辑。
        eval '${saveSelection}'
      }
    '';
  };
  boot.loader.timeout = 5;
}
