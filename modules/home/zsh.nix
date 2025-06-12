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