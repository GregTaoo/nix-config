{ config, pkgs, settings, ... }:

{
  services.nix-daemon.enable = true;
  
  # Enable zsh.
  programs.zsh.enable = true;
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = ["nix-command" "flakes"];
}