{ config, ... }: {
  imports = [
    ../nixos/configuration.nix
  ];

  boot = {
    loader.grub.device = "/dev/vda";
  };

  fileSystems = {
    "/" = {
      device = "/dev/vda1";
      fsType = "ext4";
    };
  };

  networking = {
    hostName = "beta";
  };
}
