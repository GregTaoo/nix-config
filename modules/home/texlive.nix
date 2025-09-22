{ config, pkgs, ... }:
let
  tex = (pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-medium
      exam;
  });
in
{
  home.packages = with pkgs; [
    tex
  ];
}