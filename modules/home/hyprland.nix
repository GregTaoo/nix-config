{ config, pkgs, ... }:

let
  mkDotfiles = { prefix, baseDir, paths }:
    builtins.listToAttrs (map (path: {
      name = "${prefix}/${path}";
      value = {
        source = baseDir + "/${path}";
      };
    }) paths);
in
{
  # home.file = mkDotFiles {
  #   prefix = ".config";
  #   baseDir = ../../dotfiles;
  #   paths = [
  #     "waybar/config.jsonc"
  #     "waybar/style.css"
  #   ];
  # };
  home.file.".config/waybar" = {
    source = ../../dotfiles/waybar;
  };
  home.file.".config/hypr" = {
    source = ../../dotfiles/hypr;
  };
  home.file.".config/rofi" = {
    source = ../../dotfiles/rofi;
  };
}