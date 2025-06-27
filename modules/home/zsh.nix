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

    shellAliases = {
      osgc = ''
        sudo nix-collect-garbage --delete-older-than ${settings.cleanGarbageOlderThan}
        nix-collect-garbage --delete-older-than ${settings.cleanGarbageOlderThan}
      '';

      dirshell = ''
        default_content=$(cat <<'EOF'
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
name = "DirEnv";
buildInputs = with pkgs; [

];
shellHook = "";
}
EOF
        )
      
        if [ ! -f shell.nix ]; then
            echo "$default_content" > shell.nix
            nvim shell.nix
        fi

        if [ ! -f shell.nix ]; then
            echo "shell.nix not found."
            return 1
        fi

        if diff -q <(echo "$default_content") shell.nix > /dev/null; then
            echo "shell.nix not modified."
            rm shell.nix
            return 1
        fi

        echo "Enabling direnv..."
        echo 'use nix' > .envrc
        direnv allow
      '';
    };
  };

  home.file = {
    ".p10k.zsh" = {
      source = ./configs/.p10k.zsh;
      executable = true;
    };
  };
}