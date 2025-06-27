{ config, pkgs, ... }:

{
  imports = [
    ../modules/os/grub.nix
    ../modules/os/nvidia.nix
    ../modules/os/fcitx5.nix
    ../modules/os/font.nix
    ../modules/os/i18n.nix
    ../modules/os/docker.nix
    ../modules/os/video.nix
  ];
}