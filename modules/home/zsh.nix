{ config, pkgs, settings, ... }:

{
  home.packages = with pkgs; [
    zsh-powerlevel10k
  ];

  programs.zsh = {
    enable = true;

    initContent = ''
      source ~/.p10k.zsh
    '';

    localVariables = {
      POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD = true;
    };

    enableCompletion = true;
    syntaxHighlighting.enable = true;
    history.ignoreAllDups = true;

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    shellAliases = {
      osupd = ''
        sudo find /etc/nixos/ -mindepth 1 -depth \( ! -name "*.lock" ! -name "hardware-configuration.nix" \) -delete
        sudo rsync -av --exclude '.git' /home/${settings.username}/NixConfig/* /etc/nixos/
        sudo nixos-rebuild switch
      '';
      osgc = ''
        sudo nix-collect-garbage --delete-older-than ${settings.cleanGarbageOlderThan}
        nix-collect-garbage --delete-older-than ${settings.cleanGarbageOlderThan}
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
      lolcat = "lolcat 2> /dev/null";
    };
  };

  home.file = {
    ".p10k.zsh" = {
      source = ./configs/.p10k.zsh;
      executable = true;
    };
  };
}