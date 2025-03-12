{ lib, config, ... }:
{
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
      device = "/dev/disk/by-uuid/CEAC-DF7B";
      fsType = "vfat";
    };
    "/nix" = {
      device = "/dev/disk/by-uuid/421eb4e0-4229-4c9c-bc4b-6d985f866dfc";
      fsType = "btrfs";
      options = [ "subvol=nix" ];
    };
    "/persist" = {
      device = "/dev/disk/by-uuid/421eb4e0-4229-4c9c-bc4b-6d985f866dfc";
      fsType = "btrfs";
      options = [ "subvol=persist" ];
      neededForBoot = true;
    };
  };

  networking = {
    hostName = "alpha";
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
