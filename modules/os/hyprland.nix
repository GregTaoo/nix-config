{ config, pkgs, settings, ... }:

{
  environment.systemPackages = with pkgs; [
    hyprland
    xwayland
    libsForQt5.qt5.qtwayland
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
    rofi-wayland
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
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}