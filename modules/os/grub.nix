{ config, pkgs, ... }:

{
  # Bootloader.
  # boot.loader.systemd-boot.enable = true;
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
    gfxmodeEfi = "1600x900";
  };
  boot.loader.efi.canTouchEfiVariables = true;
}