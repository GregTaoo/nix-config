{ config, pkgs, settings, ... }:

{
  wsl.enable = true;
  wsl.defaultUser = settings.username;
  networking.hostName = settings.wslHostName;
  
  nixpkgs.config.allowUnfree = true;
  programs.zsh.enable = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = with pkgs; [
    vim
    wget
    neofetch
    git
    tmux
  ];

  users.users.${settings.username} = {
    isNormalUser = true;
    description = settings.usernameUpper;
    shell = pkgs.zsh;
  };

  system.stateVersion = "24.05";
}