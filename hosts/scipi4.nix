{ pkgs, lib, config, modulesPath, ... }: {
  imports = [
    ../nixos/configuration.nix
  ];

  boot.initrd.supportedFilesystems = lib.mkForce [ "vfat" ];
  boot.supportedFilesystems = lib.mkForce [ "vfat" ];

  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.grub.enable = false;

  nixpkgs.hostPlatform = "aarch64-linux";
  nixpkgs.buildPlatform = "x86_64-linux";


  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };

  system.stateVersion = "23.11";
  services.sshd.enable = true;
  networking.wireless.enable = true;
  networking.wireless.environmentFile = config.sops.secrets.wireless_env.path;
  networking.wireless.networks.sci24.psk = "@PSK_HOME@";
  networking.interfaces.wlan0.useDHCP = true;
  networking.interfaces.end0.useDHCP = true;
  users.users.root.initialHashedPassword = "$6$8n5a7Wv2pSxRbnlC$wUaKV9g05iT9USwuBssSG3/CBxNIjgNUw/HqWGcXntKBsVafADCUf8Wv4n0nAvhwUOx0ruPZ/YJKy1rpveERk.";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHza4EH8WS4lwVWhoLBPqAXv8u3rqGibpPRX5KCxoOwE samuel@cormier-iijima.com"
  ];

  disabledModules = [ "profiles/base.nix" ];

  networking = {
    hostName = "scipi4";
  };
}
