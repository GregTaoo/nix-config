# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, settings, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  networking.hostName = settings.laptopHostName; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  networking.extraHosts = ''
    127.0.0.1   my.local
  '';

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable zsh.
  programs.zsh.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${settings.username} = {
    isNormalUser = true;
    description = settings.usernameUpper;
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDnhuRDmXAdKy9x0vDrDD5rc26GLax2tHg2T8c/fBwdm gregtaoo@outlook.com"
    ];
  };

  programs.nix-ld.enable = true;  

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = ["nix-command" "flakes"];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    ntfs3g

    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    fastfetch
    git
    firefox

    gcc
    p7zip
  ];

  environment.variables = {
    http_proxy  = "http://127.0.0.1:7890";
    https_proxy = "http://127.0.0.1:7890"; 
    all_proxy   = "socks5://127.0.0.1:7890";
    
    HTTP_PROXY  = "http://127.0.0.1:7890";
    HTTPS_PROXY = "http://127.0.0.1:7890";
    ALL_PROXY   = "socks5://127.0.0.1:7890";

    no_proxy    = "localhost,127.0.0.1,.shanghaitech.edu.cn,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12";
    NO_PROXY    = "localhost,127.0.0.1,.shanghaitech.edu.cn,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12";
  };
  
  hardware.bluetooth.enable = true; # 开启蓝牙硬件支持
  hardware.bluetooth.powerOnBoot = true; # 开机自动启动蓝牙
  services.timesyncd.enable = true;
  
  #  services.mihomo = {
  #    enable = true;
  #    configFile = "/home/${settings.username}/proxy/main.yaml";
  #  };

  services.clashtui = {
    enable = true;
    package = pkgs.callPackage ../pkgs/clashtui.nix { };
    enableMihomo = true;
    enableSingbox = true;
    users = [ settings.username ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  services.openssh = {
    enable = true;
    ports = [ 2222 ];

    settings = {
      PasswordAuthentication = false;   # 禁用密码（推荐）
      PermitRootLogin = "no";
      PubkeyAuthentication = true;           # 禁止 root 登录（推荐）
    };
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
