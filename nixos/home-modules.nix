{ config, pkgs, ... }:

{
  imports = [
    ../modules/home/nvim.nix
    ../modules/home/vscode.nix
    ../modules/home/zsh.nix
    ../modules/home/zsh-nixos.nix
    ../modules/home/direnv.nix
  ];
}