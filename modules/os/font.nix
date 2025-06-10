{ config, pkgs, ... }:

{
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      source-code-pro
      hack-font
      nerd-fonts.jetbrains-mono
    ];

    # fontconfig = {
    #   defaultFonts = {
    #     emoji = [ "Noto Color Emoji" ];
    #     monospace = [
    #       "Noto Sans Mono CJK SC"
    #       "Sarasa Mono SC"
    #       "DejaVu Sans Mono"
    #     ];
    #     sansSerif = [
    #       "Noto Sans CJK SC"
    #       "Source Han Sans SC"
    #       "DejaVu Sans"
    #     ];
    #     serif = [
    #       "Noto Serif CJK SC"
    #       "Source Han Serif SC"
    #       "DejaVu Serif"
    #     ];
    #   };
    # };
  };
}
