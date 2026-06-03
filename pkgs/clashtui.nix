{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
  dbus,
  coreutils,
  mihomo,
  sing-box,
}:

rustPlatform.buildRustPackage rec {
  pname = "clashtui";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "JohanChane";
    repo = "clashtui";
    tag = "v${version}";
    hash = "sha256-roP252d0lO7eN2KCHiuPPI5o8QqtPWJvmeex8sAmKww=";
  };

  cargoHash = "sha256-7y31iZoSJ98XDiC+Akahgfp/lI5haaek6UpFtaCtGW8=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    dbus
    openssl
  ];

  postInstall = ''
    mkdir -p $out/share/clashtui
    cp -r contrib $out/share/clashtui/contrib
  '';

  meta = {
    description = "TUI proxy manager for Mihomo and sing-box";
    homepage = "https://github.com/JohanChane/clashtui";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "clashtui";
    platforms = lib.platforms.linux;
  };
}
