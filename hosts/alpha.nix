{ config, ... }: {
  imports = [
    ../nixos/configuration.nix
  ];

  boot = {
    loader.grub.device = "/dev/sda";
  };

  fileSystems = {
    "/" = {
      device = "/dev/sda1";
      fsType = "ext4";
    };
  };

  networking = {
    hostName = "alpha";
  };

  users.mutableUsers = false;
}
