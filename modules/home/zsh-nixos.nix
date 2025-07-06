{ config, pkgs, settings, ... }:

{
  programs.zsh.shellAliases = {
    osupd = ''
      sudo nixos-rebuild switch --flake ~/NixConfig#${settings.hostName}
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