{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ffmpeg_6-full
  ];
}