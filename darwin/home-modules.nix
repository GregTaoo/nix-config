{ config, pkgs, ... }:

{
  imports = [
    ../modules/home/zsh.nix
    ../modules/home/zsh-darwin.nix
    ../modules/home/direnv.nix
    ../modules/home/nvim.nix
    ../modules/home/vscode.nix
  ];
}