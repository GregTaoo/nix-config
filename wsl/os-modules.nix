{ config, pkgs, ... }:

{
  imports = [
    ../modules/os/docker.nix
  ];
}