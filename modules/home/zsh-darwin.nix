{ config, pkgs, settings, ... }:

{
  programs.zsh.shellAliases = {
    osupd = ''
      sudo darwin-rebuild switch
    '';

    dirusenix = ''
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
}