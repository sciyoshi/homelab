{ config, pkgs, lib, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../nixos/common.nix
    ../nixos/openssh.nix
    ../nixos/tailscale.nix
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (import ../overlays/filebot)
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
      "/var/lib/tailscale"
      "/var/lib/transmission"
      "/var/lib/samba"
      "/var/lib/bitwarden_rs"
      "/var/lib/NetworkManager"
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

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = [ "btrfs" ];

  networking.hostName = "scilo"; # Define your hostname.
  networking.hostId = "a7619247";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp5s0.useDHCP = true;

  networking.networkmanager.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  services.tailscale = {
    enable = true;
    autoconnect = {
      enable = true;
      authKeyCommand = ''cat "${config.sops.secrets.tailscale_key.path}"'';
    };
  };

  virtualisation.docker.enable = true;

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

  sops.defaultSopsFile = ../secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.secrets.tailscale_key = { };
  sops.secrets.acme_credentials = { };
  sops.secrets.borg_passphrase = { };
  sops.secrets.borg_private_key = { };

  users.users.root.initialHashedPassword = "$6$8n5a7Wv2pSxRbnlC$wUaKV9g05iT9USwuBssSG3/CBxNIjgNUw/HqWGcXntKBsVafADCUf8Wv4n0nAvhwUOx0ruPZ/YJKy1rpveERk.";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHza4EH8WS4lwVWhoLBPqAXv8u3rqGibpPRX5KCxoOwE samuel@cormier-iijima.com"
  ];

  users.mutableUsers = false;

  users.groups.media.members = [ "sciyoshi" ];
  users.groups.sciyoshi = { gid = 1000; };

  # Define a user account. Don't forget to set a password with ???passwd???.
  users.users.sciyoshi = {
    isNormalUser = true;
    group = "sciyoshi";
    extraGroups = [ "wheel" "media" ]; # Enable ???sudo??? for the user.
    shell = pkgs.zsh;
    initialHashedPassword = "$6$8n5a7Wv2pSxRbnlC$wUaKV9g05iT9USwuBssSG3/CBxNIjgNUw/HqWGcXntKBsVafADCUf8Wv4n0nAvhwUOx0ruPZ/YJKy1rpveERk.";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHza4EH8WS4lwVWhoLBPqAXv8u3rqGibpPRX5KCxoOwE samuel@cormier-iijima.com"
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    adoptopenjdk-bin
    bcache-tools
    btrfs-progs
    dmraid
    filebot
    fio
    firefox
    flashbench
    netcat-gnu
    nvme-cli
    openrgb
    parted
    smartmontools
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
  networking.firewall.allowedTCPPorts = [ 30303 8000 80 443 ];
  networking.firewall.allowedUDPPorts = [ 30303 8000 ];
  networking.firewall.checkReversePath = "loose";
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It???s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

  security.acme.acceptTerms = true;
  security.acme.defaults = {
    email = "samuel@cormier-iijima.com";
    dnsProvider = "cloudflare";
    credentialsFile = "${config.sops.secrets.acme_credentials.path}";
  };

  services.transmission = {
    enable = true;
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
    securityType = "user";
    openFirewall = true;
    shares = {
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

  services.plex = {
    enable = true;
    openFirewall = true;
    user = "sciyoshi";
    group = "media";
    dataDir = "/media/data/Plex";
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

  # services.k3s = {
  #   enable = true;
  #   role = "agent";
  #   serverAddr = "";
  # };  
}
