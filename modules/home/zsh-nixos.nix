{ config, pkgs, settings, ... }:

{
  programs.zsh.shellAliases = {
    osupd = ''
      sudo find /etc/nixos/ -mindepth 1 -depth \( ! -name "*.lock" ! -name "hardware-configuration.nix" \) -delete
      sudo rsync -av --exclude '.git' /home/${settings.username}/NixConfig/* /etc/nixos/
      sudo nixos-rebuild switch
    '';
    osclash = ''
      if sudo tmux has-session -t "osclash" 2>/dev/null; then
          echo "Already exists."
          sudo tmux attach -t "osclash"
      else
          echo "Starting new session..."
          sudo tmux new-session -d -s "osclash" "sudo clash-verge"
          echo "Done."
      fi
    '';
    osshut = "systemctl poweroff";
    osre = "systemctl reboot";

    lolcat = "lolcat 2> /dev/null";
  };
}