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
    cp -r contrib/default_configs $out/share/clashtui/default_configs

    mv $out/bin/clashtui $out/bin/clashtui-unwrapped
    cat > $out/bin/clashtui <<'EOF_WRAPPER'
@runtimeShell@
set -euo pipefail

config_dir="''${CLASHTUI_CONFIG_DIR:-''${XDG_CONFIG_HOME:-''${HOME}/.config}/clashtui}"
state_dir="''${CLASHTUI_STATE_DIR:-/var/lib/clashtui}"
default_configs="@out@/share/clashtui/default_configs"

install_if_missing() {
  local src="$1"
  local dst="$2"
  if [ ! -e "$dst" ]; then
    @install@ -D -m 0644 "$src" "$dst"
  fi
}

mkdir -p \
  "$config_dir/mihomo/profiles" \
  "$config_dir/mihomo/templates" \
  "$config_dir/sing-box/profiles" \
  "$config_dir/sing-box/templates"

install_if_missing "$default_configs/default_keymap.yaml" "$config_dir/default_keymap.yaml"
install_if_missing "$default_configs/default_theme.yaml" "$config_dir/default_theme.yaml"
install_if_missing "$default_configs/mihomo/core_override_config.yaml" "$config_dir/mihomo/core_override_config.yaml"
install_if_missing "$default_configs/sing-box/core_override_config.json" "$config_dir/sing-box/core_override_config.json"

if [ ! -e "$config_dir/mihomo/template_proxy_providers.yaml" ]; then
  cat > "$config_dir/mihomo/template_proxy_providers.yaml" <<'EOF_PROXY_PROVIDERS'
# Define proxy-provider subscription URLs here, organized by group.
# In templates use ''${PPG.<group>} to reference all providers in a group,
# or ''${PPG.<group>.<provider>} for a specific one.
#
# Format:
#   <group-name>:
#     <provider-name>: "<subscription-url>"
#
# Example:
#   pvd:
#     pvd0: "https://example.com/sub1.yaml"
EOF_PROXY_PROVIDERS
fi

if [ ! -e "$config_dir/sing-box/template_proxy_providers.yaml" ]; then
  cp "$config_dir/mihomo/template_proxy_providers.yaml" "$config_dir/sing-box/template_proxy_providers.yaml"
fi

if [ ! -e "$config_dir/config.yaml" ]; then
  cat > "$config_dir/config.yaml" <<EOF_CONFIG
mihomo:
  core:
    config_dir: $state_dir/mihomo/config
    bin_path: @mihomo@
    config_path: $state_dir/mihomo/config/config.yaml
  core_service:
    service_name: clashtui_mihomo
    is_user: false
singbox:
  core:
    bin_path: @singbox@
    config_dir: $state_dir/sing-box/config
    config_path: $state_dir/sing-box/config/config.json
  core_service:
    service_name: clashtui_singbox
    is_user: false
timeout:
extra:
  edit_cmd:
  open_dir_cmd:
EOF_CONFIG
fi

exec "@out@/bin/clashtui-unwrapped" "$@"
EOF_WRAPPER
    substituteInPlace $out/bin/clashtui \
      --replace-fail '@runtimeShell@' '#!${stdenv.shell}' \
      --replace-fail '@install@' '${coreutils}/bin/install' \
      --replace-fail '@mihomo@' '${lib.getExe mihomo}' \
      --replace-fail '@singbox@' '${lib.getExe sing-box}' \
      --replace-fail '@out@' "$out"
    chmod +x $out/bin/clashtui
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
