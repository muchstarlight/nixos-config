{ config, lib, pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.qq
	  pkgs.wechat
  ];

  # 中文字体配置
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      sarasa-gothic  # 更纱黑体
      source-code-pro
      hack-font
      jetbrains-mono
    ];

    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif CJK SC" "Source Han Serif SC" ];
        sansSerif = [ "Noto Sans CJK SC" "Source Han Sans SC" ];
        monospace = [ "JetBrains Mono" "Noto Sans Mono CJK SC" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}