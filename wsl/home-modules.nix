{ config, pkgs, ... }:

{
  imports = [
    ../modules/home/nvim.nix
    ../modules/home/zsh.nix
    ../modules/home/zsh-wsl.nix
    ../modules/home/direnv.nix
  ];
}