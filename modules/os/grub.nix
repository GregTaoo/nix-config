{ config, pkgs, ... }:

let
  yoimiya-grub-theme = pkgs.fetchFromGitHub {
    owner = "GregTaoo";
    repo = "Yoimiya-Grub-Theme";
    rev = "main9ceddf1a0e95090ee4392b3fc909566331851eaa";
    sha256 = "sha256-pAxrcFnl2LKBum0l5nHio84zb5/8h5LMkxrEaBhmIC4=";
    # sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
in
{
  # Bootloader.
  # boot.loader.systemd-boot.enable = true;
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
    gfxmodeEfi = "2560x1600";

    theme = yoimiya-grub-theme;
    # theme = "/home/gregtao/develop/Yoimiya-Grub-Theme";
  };

  boot.loader.efi.canTouchEfiVariables = true;
}