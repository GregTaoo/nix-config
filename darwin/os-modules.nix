{ config, pkgs, ... }:

{
  imports = [
    ../modules/os/font.nix
    ../modules/os/video.nix
  ];
}