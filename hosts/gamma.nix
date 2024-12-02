{ lib, config, ... }: {
  imports = [
    ../nixos/configuration.nix
  ];

  boot = {
    loader.grub.enable = true;
    loader.grub.efiSupport = true;
    loader.grub.efiInstallAsRemovable = true;
    loader.grub.device = "/dev/sda";
    loader.grub.configurationLimit = 1;
    supportedFilesystems = [ "btrfs" ];
  };

  environment.persistence."/persist" = {
    directories = [
      "/var/log"
      "/var/lib/tailscale"
      "/var/lib/borg"
      "/var/lib/nixos"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };

  fileSystems = {
    "/" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "mode=755" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/DE6E-21AC";
      fsType = "vfat";
    };
    "/nix" = {
      device = "/dev/disk/by-uuid/1f267392-8eaf-463c-a163-14a260fb2fad";
      fsType = "btrfs";
      options = [ "subvol=nix" ];
    };
    "/persist" = {
      device = "/dev/disk/by-uuid/1f267392-8eaf-463c-a163-14a260fb2fad";
      fsType = "btrfs";
      options = [ "subvol=persist" ];
      neededForBoot = true;
    };
  };

  networking = {
    hostName = "gamma";
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
