{ config, pkgs, settings, ... }:

{
  programs.zsh.shellAliases = {
    osupd = ''
      sudo nixos-rebuild switch --flake ~/NixConfig#${settings.wslHostName}
    '';
  };
}