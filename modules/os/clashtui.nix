{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.clashtui;

  mihomoAutostart = cfg.enableMihomo && cfg.defaultCore == "mihomo";
  singboxAutostart = cfg.enableSingbox && cfg.defaultCore == "sing-box";

  defaultConfigs = "${cfg.package}/share/clashtui/default_configs";
  mihomoConfigDir = "${cfg.stateDir}/mihomo/config";
  singboxConfigDir = "${cfg.stateDir}/sing-box/config";

  installIfMissing = {
    target,
    source,
    user,
    group,
    mode,
  }: ''
    if [ ! -e ${lib.escapeShellArg target} ]; then
      ${pkgs.coreutils}/bin/install -D -m ${mode} -o ${lib.escapeShellArg user} -g ${lib.escapeShellArg group} \
        ${lib.escapeShellArg source} ${lib.escapeShellArg target}
    fi
  '';

  ensureMihomoConfig = ''
    ${pkgs.coreutils}/bin/install -d -m 0755 -o ${lib.escapeShellArg cfg.mihomoUser} -g ${lib.escapeShellArg cfg.mihomoGroup} \
      ${lib.escapeShellArg mihomoConfigDir}
    ${installIfMissing {
      target = "${mihomoConfigDir}/config.yaml";
      source = "${defaultConfigs}/mihomo/core_override_config.yaml";
      user = cfg.mihomoUser;
      group = cfg.mihomoGroup;
      mode = "0640";
    }}
  '';

  ensureSingboxConfig = ''
    ${pkgs.coreutils}/bin/install -d -m 0755 -o ${lib.escapeShellArg cfg.singboxUser} -g ${lib.escapeShellArg cfg.singboxGroup} \
      ${lib.escapeShellArg singboxConfigDir}
    ${installIfMissing {
      target = "${singboxConfigDir}/config.json";
      source = "${defaultConfigs}/sing-box/core_override_config.json";
      user = cfg.singboxUser;
      group = cfg.singboxGroup;
      mode = "0640";
    }}
  '';

  initializeScript = ''
    ${lib.optionalString cfg.enableMihomo ensureMihomoConfig}
    ${lib.optionalString cfg.enableSingbox ensureSingboxConfig}
  '';
in
{
  options.services.clashtui = {
    enable = lib.mkEnableOption "clashtui system core services";

    package = lib.mkPackageOption pkgs "clashtui" { };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/clashtui";
      example = "/opt/clashtui";
      description = ''
        System core state directory, corresponding to upstream's system-mode
        `INSTALL_DIR`. Mihomo uses `''${stateDir}/mihomo/config`; sing-box uses
        `''${stateDir}/sing-box/config`.
      '';
    };

    initializeCoreConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to create missing core configuration files from upstream
        defaults in `stateDir`. Existing files are never overwritten.
      '';
    };

    enableMihomo = lib.mkEnableOption "the Mihomo core managed by clashtui";

    defaultCore = lib.mkOption {
      type = lib.types.enum [ "mihomo" "sing-box" "none" ];
      default = "mihomo";
      description = "Core service to start automatically at boot.";
    };

    enableSingbox = lib.mkEnableOption "the sing-box core managed by clashtui";

    mihomoPackage = lib.mkPackageOption pkgs "mihomo" { };

    singboxPackage = lib.mkPackageOption pkgs "sing-box" { };

    mihomoUser = lib.mkOption {
      type = lib.types.str;
      default = "mihomo";
      description = "User account under which the Mihomo core service runs.";
    };

    mihomoGroup = lib.mkOption {
      type = lib.types.str;
      default = "mihomo";
      description = "Group account under which the Mihomo core service runs.";
    };

    singboxUser = lib.mkOption {
      type = lib.types.str;
      default = "sing-box";
      description = "User account under which the sing-box core service runs.";
    };

    singboxGroup = lib.mkOption {
      type = lib.types.str;
      default = "sing-box";
      description = "Group account under which the sing-box core service runs.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      [ cfg.package ]
      ++ lib.optional cfg.enableMihomo cfg.mihomoPackage
      ++ lib.optional cfg.enableSingbox cfg.singboxPackage;

    users.groups = lib.mkMerge [
      (lib.mkIf cfg.enableMihomo { ${cfg.mihomoGroup} = { }; })
      (lib.mkIf cfg.enableSingbox { ${cfg.singboxGroup} = { }; })
    ];

    users.users = lib.mkMerge [
      (lib.mkIf cfg.enableMihomo {
        ${cfg.mihomoUser} = {
          isSystemUser = true;
          group = cfg.mihomoGroup;
        };
      })
      (lib.mkIf cfg.enableSingbox {
        ${cfg.singboxUser} = {
          isSystemUser = true;
          group = cfg.singboxGroup;
        };
      })
    ];

    systemd.tmpfiles.rules =
      [
        "d ${cfg.stateDir} 0755 root root -"
      ]
      ++ lib.optionals cfg.enableMihomo [
        "d ${cfg.stateDir}/mihomo 0755 ${cfg.mihomoUser} ${cfg.mihomoGroup} -"
        "d ${mihomoConfigDir} 0755 ${cfg.mihomoUser} ${cfg.mihomoGroup} -"
      ]
      ++ lib.optionals cfg.enableSingbox [
        "d ${cfg.stateDir}/sing-box 0755 ${cfg.singboxUser} ${cfg.singboxGroup} -"
        "d ${singboxConfigDir} 0755 ${cfg.singboxUser} ${cfg.singboxGroup} -"
      ];

    systemd.services = lib.mkMerge [
      (lib.mkIf cfg.initializeCoreConfig {
        clashtui-init = {
          description = "Initialize clashtui core configuration";
          wantedBy = lib.optionals (mihomoAutostart || singboxAutostart) [ "multi-user.target" ];
          before =
            lib.optional cfg.enableMihomo "clashtui_mihomo.service"
            ++ lib.optional cfg.enableSingbox "clashtui_singbox.service";
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "clashtui-init" initializeScript;
          };
        };
      })
      (lib.mkIf cfg.enableMihomo {
        clashtui_mihomo = {
          description = "Mihomo core for clashtui";
          documentation = [ "https://github.com/JohanChane/clashtui" ];
          wantedBy = lib.optionals mihomoAutostart [ "multi-user.target" ];
          after = [
            "network.target"
            "NetworkManager.service"
            "systemd-networkd.service"
            "iwd.service"
          ];
          requires = lib.optional cfg.initializeCoreConfig "clashtui-init.service";

          serviceConfig = {
            Type = "simple";
            User = cfg.mihomoUser;
            Group = cfg.mihomoGroup;
            ExecStartPre = "${pkgs.coreutils}/bin/sleep 1s";
            ExecStart = lib.escapeShellArgs [
              (lib.getExe cfg.mihomoPackage)
              "-d"
              mihomoConfigDir
            ];
            ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
            Restart = "always";
            LimitNPROC = 500;
            LimitNOFILE = 1000000;
            AmbientCapabilities = [
              "CAP_NET_ADMIN"
              "CAP_NET_RAW"
              "CAP_NET_BIND_SERVICE"
              "CAP_SYS_TIME"
              "CAP_SYS_PTRACE"
              "CAP_DAC_READ_SEARCH"
              "CAP_DAC_OVERRIDE"
            ];
            CapabilityBoundingSet = [
              "CAP_NET_ADMIN"
              "CAP_NET_RAW"
              "CAP_NET_BIND_SERVICE"
              "CAP_SYS_TIME"
              "CAP_SYS_PTRACE"
              "CAP_DAC_READ_SEARCH"
              "CAP_DAC_OVERRIDE"
            ];
          };
        };
      })

      (lib.mkIf cfg.enableSingbox {
        clashtui_singbox = {
          description = "sing-box core for clashtui";
          documentation = [ "https://github.com/JohanChane/clashtui" ];
          wantedBy = lib.optionals singboxAutostart [ "multi-user.target" ];
          after = [
            "network.target"
            "NetworkManager.service"
            "systemd-networkd.service"
            "iwd.service"
          ];
          requires = lib.optional cfg.initializeCoreConfig "clashtui-init.service";

          serviceConfig = {
            Type = "simple";
            User = cfg.singboxUser;
            Group = cfg.singboxGroup;
            StateDirectory = "sing-box";
            ExecStartPre = "${pkgs.coreutils}/bin/sleep 1s";
            ExecStart = lib.escapeShellArgs [
              (lib.getExe cfg.singboxPackage)
              "-D"
              singboxConfigDir
              "-c"
              "${singboxConfigDir}/config.json"
              "run"
            ];
            ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
            Restart = "on-failure";
            RestartSec = "10s";
            LimitNOFILE = "infinity";
            AmbientCapabilities = [
              "CAP_NET_ADMIN"
              "CAP_NET_RAW"
              "CAP_NET_BIND_SERVICE"
              "CAP_SYS_PTRACE"
              "CAP_DAC_READ_SEARCH"
            ];
            CapabilityBoundingSet = [
              "CAP_NET_ADMIN"
              "CAP_NET_RAW"
              "CAP_NET_BIND_SERVICE"
              "CAP_SYS_PTRACE"
              "CAP_DAC_READ_SEARCH"
            ];
          };
        };
      })
    ];
  };
}
