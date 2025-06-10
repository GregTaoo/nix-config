{ config, pkgs, ... }:

{
  imports = [
    ./os/grub.nix
    ./os/nvidia.nix
    ./os/fcitx5.nix
    ./os/font.nix
    ./os/i18n.nix
    ./os/docker.nix
    ./os/video.nix
  ];
}