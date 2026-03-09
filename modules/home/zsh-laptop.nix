{ config, pkgs, settings, ... }:

{
  programs.zsh.shellAliases = {
    osupd = ''
      sudo nixos-rebuild switch --flake ~/nix-config#${settings.laptopHostName}
    '';
    osshut = "systemctl poweroff";
    osre = "systemctl reboot";
    docker-close-all = "docker stop $(docker ps -q)";

    lolcat = "lolcat 2> /dev/null";
  };
}