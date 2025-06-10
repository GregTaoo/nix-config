{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    vscode
  ];

  programs.vscode = {
    enable = true;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
    ];
  };
}
