{
  stdenvNoCC,
  stdenv,
  lib,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  openssl,
  udev,
  libglvnd,
  libx11,
  libxcursor,
  libxi,
  libxrandr,
  libxfixes,
  libpulseaudio,
  libva,
  ffmpeg_7,
  libpng,
  libjpeg8,
  curl,
  vulkan-loader,
  zenity,
}:

stdenvNoCC.mkDerivation {
  pname = "parsec";
  version = "150-97c";

  src = ./parsec-linux.deb;

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc
    libglvnd
    libx11
  ];

  runtimeDependenciesPath = lib.makeLibraryPath [
    stdenv.cc.cc
    libglvnd
    openssl
    udev
    alsa-lib
    libpulseaudio
    libva
    ffmpeg_7
    libpng
    libjpeg8
    curl
    libx11
    libxcursor
    libxi
    libxrandr
    libxfixes
    vulkan-loader
  ];

  binPath = lib.makeBinPath [
    zenity
  ];

  prepareParsec = ''
    if [[ ! -e "$HOME/.parsec/appdata.json" ]]; then
      mkdir -p "$HOME/.parsec"
      cp --no-preserve=mode,ownership,timestamps ${placeholder "out"}/share/parsec/skel/* "$HOME/.parsec/"
    fi
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    mv usr/* $out

    wrapProgram $out/bin/parsecd \
      --prefix PATH : "$binPath" \
      --prefix LD_LIBRARY_PATH : "$runtimeDependenciesPath" \
      --set-default VK_DRIVER_FILES /run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json \
      --run "$prepareParsec"

    substituteInPlace $out/share/applications/parsecd.desktop \
      --replace "/usr/bin/parsecd" "parsecd" \
      --replace "/usr/share/icons" "${placeholder "out"}/share/icons"

    runHook postInstall
  '';

  dontAutoPatchelf = true;

  fixupPhase = ''
    runHook preFixup

    autoPatchelf $out/bin

    runHook postFixup
  '';

  meta = {
    homepage = "https://parsec.app/";
    changelog = "https://parsec.app/changelog";
    description = "Remote streaming service client";
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
    mainProgram = "parsecd";
  };
}
