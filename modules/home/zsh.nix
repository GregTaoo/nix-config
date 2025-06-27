{ config, pkgs, settings, ... }:

{
  home.packages = with pkgs; [
    zsh-powerlevel10k
    zsh-autosuggestions
  ];

  programs.zsh = {
    enable = true;

    initContent = ''
      source ~/.p10k.zsh
      eval "$(direnv hook zsh)"
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
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
    ];
  };

  home.file = {
    ".p10k.zsh" = {
      source = ./configs/.p10k.zsh;
      executable = true;
    };
  };
}