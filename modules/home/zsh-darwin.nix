{ config, pkgs, settings, ... }:

{
  programs.zsh.shellAliases = {
    osupd = ''
      sudo darwin-rebuild switch
    '';
  };
}