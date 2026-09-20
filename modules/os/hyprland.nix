{ config, pkgs, settings, ... }:

{
  environment.systemPackages = with pkgs; [
    hyprland
    xwayland
    qt5.qtwayland
    kdePackages.qtwayland

    wl-clipboard
    cliphist
    playerctl
    brightnessctl

    networkmanagerapplet
    proxychains
    blueman

    kitty
    waybar
    rofi
    mako
    hyprsunset
    hyprpaper
    hypridle
    hyprlock

    grim
    slurp
  ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
    config.hyprland.default = [ "hyprland" "gtk" ];
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
