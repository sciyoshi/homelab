{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../nixos/common.nix
    ../nixos/openssh.nix
    ../nixos/tailscale.nix
    ../nixos/databases.nix
    ../nixos/immich.nix
    ../nixos/secrets.nix
    ../nixos/frigate.nix
    ../nixos/homeassistant.nix
    ../nixos/rumqttd.nix
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (import ../overlays/filebot)
    (import ../overlays/pgvecto-rs.nix)
    (import ../overlays/rumqttd.nix)
  ];

  console = {
    packages = with pkgs; [ terminus_font ];
    font = "ter-v32n";
  };

  boot.initrd.postDeviceCommands = pkgs.lib.mkBefore ''
    mkdir -p /mnt
    mount -o subvol=/ UUID=e5fb150b-0925-44d3-a2c1-aa9cf33f850d /mnt
    btrfs subvolume list -o /mnt/root | cut -f9 -d' ' | while read subvolume; do
      btrfs subvolume delete "/mnt/$subvolume"
    done
    btrfs subvolume delete /mnt/root
    btrfs subvolume snapshot /mnt/blank /mnt/root
    umount /mnt
  '';

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/nixos"
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/tailscale"
      "/var/lib/transmission"
      "/var/lib/samba"
      "/var/lib/bitwarden_rs"
      "/var/lib/NetworkManager"
      "/var/lib/jellyfin"
      "/var/lib/rancher"
      "/var/lib/docker"
      "/var/lib/containers"
      "/var/lib/cni"
      "/var/lib/kubelet"
      "/var/lib/postgresql"
      "/var/lib/mysql"
      "/var/lib/zigbee2mqtt"
      "/var/lib/home-assistant"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.useOSProber = true;
  boot.loader.systemd-boot.configurationLimit = 3;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = [ "btrfs" ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.hostName = "scilo"; # Define your hostname.
  networking.hostId = "a7619247";

  networking.useDHCP = false;
  networking.interfaces.enp5s0.useDHCP = true;

  networking.networkmanager.enable = true;

  programs.nix-ld.enable = true;

  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

  services.tailscale = {
    enable = true;
    autoconnect = {
      enable = true;
      authKeyCommand = ''cat "${config.sops.secrets.tailscale_key.path}"'';
    };
  };

  hardware.graphics = {
    enable = true;
    # driSupport = true;
    enable32Bit = true;
    # setLdLibraryPath = true;
  };

  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  hardware.nvidia.nvidiaSettings = true;
  hardware.nvidia.powerManagement.enable = false;
  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.open = false;

  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  # systemd.enableUnifiedCgroupHierarchy = false;

  virtualisation.podman.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  virtualisation.oci-containers.backend = "podman";

  # zigbee2mqtt - update device path after plugging in the Zigbee dongle
  # Run: ls /dev/serial/by-id/ to find the correct device
  virtualisation.oci-containers.containers.zigbee2mqtt = {
    image = "koenkk/zigbee2mqtt:latest";
    extraOptions = [
      "--pull=always"
      # TODO: Update this device path after plugging in the Zigbee dongle
      "--device=/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_9a9e953ad1dbed11bfcbe92d62c613ac-if00-port0"
    ];
    volumes = [
      "/run/udev:/run/udev:ro"
      "/var/lib/zigbee2mqtt:/app/data"
    ];
    environment = {
      TZ = "America/Montreal";
    };
    ports = [ "8080:8080/tcp" ];
    autoStart = true;
  };

  security.sudo.wheelNeedsPassword = false;

  fileSystems."/media/data" = {
    device = "/dev/disk/by-uuid/d68f4e11-f9ea-4bd4-86e4-afcbacbe705c";
    fsType = "btrfs";
    options = [ "subvol=/data" ];
  };

  fileSystems."/media/local" = {
    device = "/dev/disk/by-uuid/b7fc7d7e-aff8-47cc-8514-331a440e0acf";
    fsType = "ext4";
    options = [ "defaults" ];
  };

  users.users.root.initialHashedPassword = "$6$8n5a7Wv2pSxRbnlC$wUaKV9g05iT9USwuBssSG3/CBxNIjgNUw/HqWGcXntKBsVafADCUf8Wv4n0nAvhwUOx0ruPZ/YJKy1rpveERk.";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHza4EH8WS4lwVWhoLBPqAXv8u3rqGibpPRX5KCxoOwE samuel@cormier-iijima.com"
  ];

  users.mutableUsers = false;

  users.groups.media.members = [ "sciyoshi" ];
  users.groups.sciyoshi = {
    gid = 1000;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sciyoshi = {
    isNormalUser = true;
    group = "sciyoshi";
    extraGroups = [
      "wheel"
      "media"
    ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
    initialHashedPassword = "$6$8n5a7Wv2pSxRbnlC$wUaKV9g05iT9USwuBssSG3/CBxNIjgNUw/HqWGcXntKBsVafADCUf8Wv4n0nAvhwUOx0ruPZ/YJKy1rpveERk.";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHza4EH8WS4lwVWhoLBPqAXv8u3rqGibpPRX5KCxoOwE samuel@cormier-iijima.com"
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    bcache-tools
    btrfs-progs
    filebot
    fio
    firefox
    flashbench
    netcat-gnu
    nvme-cli
    openrgb
    parted
    smartmontools
    openiscsi
    temurin-bin
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    30303
    8000
    80
    443
    6443
    9443
    9080
  ];
  networking.firewall.allowedUDPPorts = [
    30303
    8000
    6443
  ];
  networking.firewall.checkReversePath = "loose";
  networking.firewall.interfaces.podman1.allowedUDPPorts = [ 53 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  security.acme.acceptTerms = true;
  security.acme.defaults = {
    email = "samuel@cormier-iijima.com";
    dnsProvider = "cloudflare";
    credentialsFile = "${config.sops.secrets.acme_credentials.path}";
  };

  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    user = "sciyoshi";
    group = "media";
    openRPCPort = true;
    settings.download-dir = "/media/data";
    settings.incomplete-dir-enabled = false;
    settings.rpc-bind-address = "0.0.0.0";
    settings.rpc-whitelist-enabled = false;
    settings.rpc-host-whitelist-enabled = false;
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global.security = "user";
      Data = {
        path = "/media/data";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "sciyoshi";
        "veto files" = "/._*/.DS_Store/";
        "delete veto files" = "yes";
      };
    };
  };

  services.vaultwarden = {
    enable = true;
    config.rocketPort = 19317;
    backupDir = "/media/local/backup/vaultwarden";
  };

  services.borgbackup.jobs.vaultwarden = {
    paths = "/media/local/backup/vaultwarden";
    encryption.mode = "repokey";
    encryption.passCommand = "cat ${config.sops.secrets.borg_passphrase.path}";
    environment.BORG_RSH = "ssh -o 'StrictHostKeyChecking=no' -i ${config.sops.secrets.borg_private_key.path}";
    repo = "borg@alpha.sciyoshi.com:.";
    compression = "auto,zstd";
    startAt = "daily";
    prune.keep = {
      daily = 7;
      weekly = 4;
      monthly = -1;
    };
  };

  services.borgbackup.jobs.immich = {
    paths = "/media/data/immich";
    encryption.mode = "repokey";
    encryption.passCommand = "cat ${config.sops.secrets.borg_passphrase.path}";
    environment.BORG_RSH = "ssh -o 'StrictHostKeyChecking=no' -i ${config.sops.secrets.borg_private_key.path}";
    repo = "borg@100.119.209.24:.";
    compression = "auto,zstd";
    startAt = "*-*-* 00:10:00";
    exclude = [
      "encoded-video"
      "thumbs"
    ];
    prune.keep = {
      daily = 7;
      weekly = 4;
      monthly = -1;
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts = {
      "vaultwarden.sciyoshi.com" = {
        forceSSL = true;
        enableACME = true;
        acmeRoot = null;
        locations."/" = {
          proxyPass = "http://localhost:19317";
        };
      };
    };
  };

  # Remove once https://github.com/NixOS/nixpkgs/issues/360592
  nixpkgs.config.permittedInsecurePackages = [
    "aspnetcore-runtime-6.0.36"
    "aspnetcore-runtime-wrapped-6.0.36"
    "dotnet-sdk-6.0.428"
    "dotnet-sdk-wrapped-6.0.428"
  ];

  services.sonarr = {
    enable = true;
    user = "sciyoshi";
    group = "media";
    openFirewall = true;
  };

  services.jackett = {
    enable = true;
    user = "sciyoshi";
    group = "media";
    openFirewall = true;
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "sciyoshi";
    group = "media";
  };

  # services.k3s = {
  #   enable = true;
  #   role = "server";
  #   tokenFile = config.sops.secrets.k3s_token.path;
  #   environmentFile = pkgs.writeText "k3s.env" "PATH=${pkgs.tailscale}/bin:/bin";
  #   extraFlags = "--vpn-auth-file=${config.sops.secrets.k3s_vpn_auth.path}";
  # };
}
