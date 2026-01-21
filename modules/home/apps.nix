{ config, pkgs, ... }:

{
  # GUI applications
  home.packages = with pkgs; [
    # productivity
    hugo # static site generator
    go
    glow # markdown previewer in terminal

    # fonts
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-serif
    source-code-pro
    hack-font
    fira-mono
  ];

  # vscode 相关配置
  programs.vscode.enable = true;

  programs.alacritty = {
    enable = true;
    # 自定义配置
    settings = {
      env.TERM = "xterm-256color";
      font = {
        size = 12;
        draw_bold_text_with_bright_colors = true;
      };
      scrolling.multiplier = 5;
      selection.save_to_clipboard = true;
    };
  };
}