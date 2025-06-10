{ config, pkgs, ... }:

{
  imports = [
    ./home/nvim.nix
    ./home/vscode.nix
    ./home/zsh.nix
  ];
}