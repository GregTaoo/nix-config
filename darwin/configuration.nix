{ config, pkgs, settings, ... }:

{
  # Enable zsh.
  programs.zsh.enable = true;
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = 6;
}