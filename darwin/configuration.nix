{ config, pkgs, settings, ... }:

{
  # Enable zsh.
  programs.zsh.enable = true;

  users.users."${settings.username}" = {
    home = "/Users/${settings.username}";
    uid = 501;
    shell = pkgs.zsh;
  };

  users.knownUsers = [ settings.username ];
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = with pkgs; [
    
  ];

  system.stateVersion = 6;
}