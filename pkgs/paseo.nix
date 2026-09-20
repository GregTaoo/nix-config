{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "paseo";
  version = "0.5.2";
  src = fetchurl {
    url = "https://github.com/getpaseo/paseo/releases/download/v${version}/Paseo-x86_64.AppImage";
    hash = "sha256-DKoko07+6+oKfEimlBnPP8SszuUkurjCEqPgfk6BPfw=";
  };
  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/Paseo.desktop $out/share/applications/paseo.desktop
    install -Dm444 ${appimageContents}/Paseo.png $out/share/icons/hicolor/512x512/apps/paseo.png
    sed -i \
      -e 's|^Exec=.*|Exec=paseo %U|' \
      -e 's|^Icon=.*|Icon=paseo|' \
      $out/share/applications/paseo.desktop
  '';

  meta = {
    description = "A desktop client for managing API requests";
    homepage = "https://github.com/getpaseo/paseo";
    license = lib.licenses.mit;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
