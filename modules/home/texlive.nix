{ config, pkgs, ... }:
let
  tex = (pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-medium
      tikz-qtree
      forest
      subfigure
      exam;
  });
in
{
  home.packages = with pkgs; [
    tex
  ];
}