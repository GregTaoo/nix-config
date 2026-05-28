{ config, pkgs, ... }:

{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-gtk
      qt6Packages.fcitx5-chinese-addons
      fcitx5-nord
      fcitx5-mozc
    ];
  };

  environment.systemPackages = with pkgs; [
    fcitx5-mellow-themes
  ];
}
