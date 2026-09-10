# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../nixos/nix-cache.nix
  ];

  home-manager.users.sciyoshi.imports = [
    ../home/sci.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Put new user profiles and channel expressions in $XDG_STATE_HOME/nix
  # (profile and defexpr), instead of ~/.nix-profile and ~/.nix-defexpr.
  # Home Manager follows this setting too. No old profile/channel is imported;
  # the unused legacy link/directory can be removed after switching.
  nix.settings.use-xdg-base-directories = true;

  # Root resets at boot, so sudo cannot remember having shown its lecture.
  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 3;

  # Migration prerequisites and recovery procedure are in README.md.
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.services.rollback = {
    description = "Restore the empty Btrfs root";
    unitConfig = {
      DefaultDependencies = false;
      ConditionKernelCommandLine = "!impermanence.disable=1";
    };
    after = [
      "local-fs-pre.target"
      "initrd-root-device.target"
    ];
    before = [ "sysroot.mount" ];
    requiredBy = [ "sysroot.mount" ];
    path = [
      pkgs.btrfs-progs
      pkgs.coreutils
      pkgs.util-linux
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail
      top=/btrfs-tmp
      mkdir -p "$top"
      mount -t btrfs -o subvolid=5 ${config.fileSystems."/".device} "$top"
      trap 'umount "$top"' EXIT

      # Validate both targets before deleting anything. Never follow symlinks.
      test ! -L "$top/blank"
      btrfs subvolume show "$top/blank" >/dev/null
      test "$(btrfs property get -ts "$top/blank" ro)" = "ro=true"
      # A missing migration seed must not destroy the installed root.
      test -s "$top/persist/passwords/sciyoshi"

      test ! -L "$top/root"
      if [ -e "$top/root" ]; then
        btrfs subvolume show "$top/root" >/dev/null
        # Native recursion avoids parsing human-readable subvolume paths.
        btrfs subvolume delete --recursive "$top/root"
      fi
      btrfs subvolume snapshot "$top/blank" "$top/root"
    '';
  };

  specialisation.no-rollback.configuration.boot.kernelParams = [
    "impermanence.disable=1"
  ];

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
      "/var/lib/NetworkManager"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/tailscale"
      "/var/log"
      {
        directory = config.services.home-assistant.configDir;
        user = "hass";
        group = "hass";
        mode = "0700";
      }
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "hid_apple.fnmode=2" ];

  fonts.packages = with pkgs; [
    fira-code
    fira-code-symbols
    noto-fonts
    victor-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.victor-mono
    nerd-fonts.fira-code
  ];

  boot.supportedFilesystems = [
    "ntfs"
    "btrfs"
  ];

  # programs.xwayland.enable = true;
  # programs.sway.enable = true;
  # services.greetd.enable = true;
  # services.greetd.settings = rec {
  #   initial_session = {
  #     command = "${pkgs.sway}/bin/sway";
  #     user = "sciyoshi";
  #   };
  #   default_session = initial_session;
  # };
  # services.xserver.displayManager.gdm.wayland = true;

  networking.hostName = "sci"; # Define your hostname.
  networking.firewall.checkReversePath = "loose";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "systemd-resolved";
  networking.networkmanager.wifi.powersave = false;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  systemd.network.wait-online.enable = false;
  systemd.services."systemd-networkd-wait-online".enable = false;

  services.resolved.enable = true;

  systemd.network.enable = true;

  systemd.network.networks."30-sci-split" = {
    matchConfig.Name = "lo";
    dns = [ "127.0.0.1" ];
    domains = [ "~sci.fellow.dev" ];
    linkConfig.RequiredForOnline = "no";
  };

  services.sshd.enable = true;

  services.dnsmasq = {
    enable = true;
    settings = {
      address = [
        "/sci.fellow.dev/127.0.0.1"
        "/sci.fellow.dev/::1"
      ];
      local = "/sci.fellow.dev/";
      no-resolv = true;
      listen-address = "127.0.0.1,::1";
      bind-interfaces = true;
      txt-record = "sci.fellow.dev,SOA,ns.sci.fellow.dev. hostmaster.sci.fellow.dev. 1 3600 600 86400 60";
      host-record = "ns.sci.fellow.dev,127.0.0.1,::1";
    };
  };

  # Set your time zone.
  time.timeZone = "America/Toronto";
  time.hardwareClockInLocalTime = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  # services.displayManager.gdm.enable = true;
  # services.desktopManager.gnome.enable = true;

  services.greetd = {
    enable = true;
    settings = rec {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${config.programs.niri.package}/bin/niri-session";
        user = "greeter";
      };

      initial_session = default_session;
    };
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  # sound.enable = true;
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sciyoshi = {
    isNormalUser = true;
    description = "Samuel Cormier-Iijima";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
    hashedPasswordFile = "/persist/passwords/sciyoshi";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHza4EH8WS4lwVWhoLBPqAXv8u3rqGibpPRX5KCxoOwE samuel@cormier-iijima.com"
    ];
  };

  programs.zsh.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ (import ../overlays/chatgpt.nix) ];

  services.tailscale.enable = true;

  services.home-assistant = {
    enable = true;
    # Add integrations configured through the UI here so Nix installs their dependencies.
    extraComponents = [
      "casper_glow" # Casper Glow light, advertised over Bluetooth as Jar_0.
      "default_config"
      "esphome"
      "met"
    ];
    config = {
      default_config = { };
      homeassistant = {
        name = "Home";
        unit_system = "metric";
        time_zone = config.time.timeZone;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 8123 ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    firefox
    # Relocate ~/.cursor/extensions for both CLI and desktop launches.
    # Extensions start fresh under XDG data. Cursor may still create
    # ~/.cursor/argv.json; --extensions-dir does not relocate that file.
    (code-cursor.override {
      commandLineArgs = "--extensions-dir ${config.home-manager.users.sciyoshi.xdg.dataHome}/cursor/extensions";
    })
    chatgpt
    chromium
    ghostty
    git
    vim
    vscode
    slack
    signal-desktop
    tailscale
    wofi
    gparted
    (wineWow64Packages.full.override {
      wineRelease = "staging";
      mingwSupport = true;
    })
    winetricks
    lutris
    umu-launcher
    xwayland-satellite
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

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

  hardware.graphics = {
    enable = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    # offload.enable = true;
    # offload.enableOffloadCmd = true;
    # nvidiaBusId = "PCI:10:0:0";
    # powerManagement.finegrained = true;
    open = false;
    nvidiaSettings = true;
    # package = config.boot.kernelPackages.nvidiaPackages.legacy_535;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  programs.niri.enable = true;

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "Polkit GNOME authentication agent";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
    };
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

}
