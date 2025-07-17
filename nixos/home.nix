{ config, pkgs, inputs, outputs, settings, ... }:

{
  home.username = settings.username;
  home.homeDirectory = "/home/${settings.username}";
  
  imports = [ ./home-modules.nix ];

  home.packages = with pkgs; [
    cowsay
    lolcat

    parsec-bin
    sunshine

    kdePackages.kate
    pandoc
    thunderbird
    kdePackages.kolourpaint

    obsidian
    jetbrains.clion
    jetbrains.webstorm
    jetbrains.idea-ultimate
    jetbrains.datagrip
    wpsoffice

    qq
    wechat-uos
    feishu

    microsoft-edge
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
