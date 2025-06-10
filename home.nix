{ config, pkgs, inputs, outputs, ... }:

{
  home.username = "gregtao";
  home.homeDirectory = "/home/gregtao";
  
  imports = [
    ./modules/home-manager.nix
  ];

  home.packages = with pkgs; [
    cowsay
    lolcat

    kdePackages.kate
    pandoc
    thunderbird

    obsidian
    jetbrains.clion
    jetbrains.webstorm
    jetbrains.idea-ultimate

    qq
  ];
  
  programs.git = {
    enable = true;
    userName = "GregTao";
    userEmail = "gregtaoo@outlook.com";
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
