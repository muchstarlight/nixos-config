{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  i18n.defaultLocale = "zh_CN.UTF-8";
  i18n.supportedLocales = [
    "zh_CN.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
  ];
  networking.networkmanager.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  security.polkit.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    btop
    fastfetch
    ripgrep
    pciutils
    usbutils
    libva-utils
    vulkan-tools
  ];
}
