{ config, pkgs, inputs, outputs, settings, ... }:

{
  home.username = settings.username;
  
  imports = [ ./home-modules.nix ];

  home.packages = with pkgs; [
    cowsay
    lolcat
  ];
  
  programs.git = {
    enable = true;
    userName = settings.usernameUpper;
    userEmail = settings.email;
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";
}
