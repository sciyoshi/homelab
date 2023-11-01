{ pkgs, lib, config, modulesPath, ... }: {
  boot.initrd.supportedFilesystems = lib.mkForce [ "vfat" "btrfs" ];
  boot.supportedFilesystems = lib.mkForce [ "vfat" "btrfs" ];

  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.grub.enable = false;

  boot.tmp.cleanOnBoot = true;
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;

  zramSwap.enable = true;

  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nixpkgs.hostPlatform = "aarch64-linux";
  nixpkgs.buildPlatform = "x86_64-linux";

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "btrfs";
    };
  };

  system.stateVersion = "23.11";
  services.sshd.enable = true;
  networking.wireless.enable = true;
  networking.wireless.networks.sci24.psk = "";
  networking.interfaces.wlan0.useDHCP = true;
  networking.interfaces.end0.useDHCP = true;
  users.users.root.initialHashedPassword = "$6$8n5a7Wv2pSxRbnlC$wUaKV9g05iT9USwuBssSG3/CBxNIjgNUw/HqWGcXntKBsVafADCUf8Wv4n0nAvhwUOx0ruPZ/YJKy1rpveERk.";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHza4EH8WS4lwVWhoLBPqAXv8u3rqGibpPRX5KCxoOwE samuel@cormier-iijima.com"
  ];

  networking = {
    hostName = "scipi5";
  };
}
