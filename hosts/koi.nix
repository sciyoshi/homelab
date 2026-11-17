{
  config,
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}:
let
  mountOptions = [
    "compress=zstd"
    "noatime"
  ];
in
{
  imports = [
    inputs.comin.nixosModules.comin
    (modulesPath + "/profiles/qemu-guest.nix")
    ../nixos/common.nix
    ../nixos/openssh.nix
    ../nixos/users.nix
  ];

  networking.hostName = "koi";
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "26.11";
  nixpkgs.config.allowUnfree = true;

  # SSH forwards Ghostty's TERM; shells and TUIs need its terminal definition.
  environment.systemPackages = [ pkgs.ghostty.terminfo ];

  # OVH boots this VPS in BIOS mode. Keep an ESP for recovery via UEFI.
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    efiSupport = true;
    efiInstallAsRemovable = true;
    configurationLimit = 5;
  };
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
  ];
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200n8"
  ];
  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  services.qemuGuest.enable = true;

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        bios = {
          size = "1M";
          type = "EF02";
          priority = 1;
        };
        ESP = {
          size = "1G";
          type = "EF00";
          priority = 2;
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        system = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [
              "-L"
              "koi-btrfs"
            ];
            subvolumes = {
              root = {
                mountpoint = "/";
                inherit mountOptions;
              };
              home = {
                mountpoint = "/home";
                inherit mountOptions;
              };
              nix = {
                mountpoint = "/nix";
                inherit mountOptions;
              };
              persist = {
                mountpoint = "/persist";
                inherit mountOptions;
              };
            };
            # Run before installation populates root; never snapshot a live root.
            postCreateHook = ''
              (
                top=$(mktemp -d)
                mount -t btrfs -o subvolid=5 /dev/disk/by-label/koi-btrfs "$top"
                trap 'umount "$top"; rmdir "$top"' EXIT
                if [ ! -e "$top/blank" ]; then
                  btrfs subvolume snapshot -r "$top/root" "$top/blank"
                fi
              )
            '';
          };
        };
      };
    };
  };
  fileSystems."/persist".neededForBoot = true;
  fileSystems."/home".neededForBoot = true;

  # Same blank-root restore as sci, with SSH identity as the recovery guard.
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

      test ! -L "$top/blank"
      btrfs subvolume show "$top/blank" >/dev/null
      test "$(btrfs property get -ts "$top/blank" ro)" = "ro=true"
      test -s "$top/persist/etc/ssh/ssh_host_ed25519_key"

      test ! -L "$top/root"
      if [ -e "$top/root" ]; then
        btrfs subvolume show "$top/root" >/dev/null
        btrfs subvolume delete --recursive "$top/root"
      fi
      btrfs subvolume snapshot "$top/blank" "$top/root"
    '';
  };
  specialisation.no-rollback.configuration.boot.kernelParams = [ "impermanence.disable=1" ];

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      {
        directory = "/root";
        mode = "0700";
      }
      "/var/lib/nixos"
      {
        directory = "/var/lib/comin";
        mode = "0700";
      }
      "/var/lib/systemd"
      "/var/lib/tailscale"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "ens3";
    networkConfig = {
      DHCP = "ipv4";
      IPv6AcceptRA = false;
      LinkLocalAddressing = "ipv6";
    };
    address = [ "2607:5300:205:200::b755/128" ];
    routes = [
      {
        Gateway = "2607:5300:205:200::1";
        GatewayOnLink = true;
      }
    ];
    dhcpV4Config.UseMTU = true;
    linkConfig.RequiredForOnline = "routable";
  };
  services.resolved.enable = true;
  networking.firewall = {
    allowPing = true;
    checkReversePath = "loose";
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
  services.tailscale.enable = true;

  # Trial only: follow this branch until Comin is promoted to main.
  # Local testing-koi commits override it while based on its latest commit.
  services.comin = {
    enable = true;
    machineId = "899a8a78015347778dea717fad5ad49f";
    exporter.listen_address = "127.0.0.1";
    remotes = [
      {
        name = "local";
        url = "/home/sciyoshi/.setup";
        poller.period = 5;
        branches.main.name = "feat/koi-comin";
        branches.testing.name = "testing-koi";
      }
      {
        name = "origin";
        url = "https://github.com/sciyoshi/homelab.git";
        poller.period = 300;
        branches.main.name = "feat/koi-comin";
        branches.testing.name = "";
      }
    ];
  };
  systemd.services.comin = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    unitConfig.RequiresMountsFor = [
      "/home/sciyoshi/.setup"
      "/var/lib/comin"
    ];
    serviceConfig = {
      StateDirectory = "comin";
      StateDirectoryMode = "0700";
    };
  };

  # Authenticate Tailscale once after installation; its identity is persisted.
  # This base server does not need the retired cluster's SOPS credentials.
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "prohibit-password";
  };
  users.users.root.initialHashedPassword = lib.mkForce null;
  users.users.root.hashedPassword = "!";
  users.users.sciyoshi.initialHashedPassword = lib.mkForce null;
  users.users.sciyoshi.hashedPassword = "!";
  security.sudo.enable = false;
  security.sudo-rs = {
    enable = true;
    wheelNeedsPassword = false;
  };

  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
