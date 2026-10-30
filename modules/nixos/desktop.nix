{ pkgs, ... }:
{
  programs.appimage = {
    enable = true;
    binfmt = true;
    # Firefox/Zen 通过系统 FFmpeg 解码 H.264/AAC，默认 AppImage 环境未包含该库。
    package = pkgs.appimage-run.override {
      extraPkgs = pkgs: [ pkgs.ffmpeg_8.lib ];
    };
  };

  programs.niri = {
    enable = true;
    useNautilus = false;
  };

  services.gnome.gnome-keyring.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  security.pam.services.login = { };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      qt6Packages.fcitx5-chinese-addons
      fcitx5-rime
      fcitx5-gtk
    ];
  };

  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    dejavu_fonts
    nerd-fonts.jetbrains-mono
  ];
  environment.systemPackages = with pkgs; [
    xwayland-satellite
    wl-clipboard
    brightnessctl
    ddcutil
    libnotify
    ghostty
    nautilus
    firefox
    adwaita-icon-theme
  ];
}
