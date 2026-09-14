{ config, pkgs, ... }:
let
  tex = pkgs.texliveSmall.withPackages (ps: with ps; [
    scheme-medium
    tikz-qtree
    forest
    subfigure
    exam
  ]);
in
{
  home.packages = with pkgs; [
    tex
  ];
}
