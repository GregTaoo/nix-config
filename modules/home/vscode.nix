{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    vscode
  ];

  programs.vscode = {
    enable = true;
    # 不能有大写字母
    profiles.default.extensions = with pkgs.vscode-extensions; [
      james-yu.latex-workshop
      bbenoist.nix
      ocamllabs.ocaml-platform
      mkhl.direnv
    ];
  };
}
