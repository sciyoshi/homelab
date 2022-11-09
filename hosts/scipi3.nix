{ pkgs, lib, modulesPath, ... }: {
  boot.initrd.supportedFilesystems = lib.mkForce [ "vfat" ];
  boot.supportedFilesystems = lib.mkForce [ "vfat" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  nixpkgs.crossSystem.system = "aarch64-linux";

  system.stateVersion = "21.11";

  networking.wireless.enable = true;
  networking.wireless.networks.sci24.psk = "";
  networking.interfaces.wlan0.useDHCP = true;

  disabledModules = [ "profiles/base.nix" ];

  services.sshd.enable = true;

  users.users.root.initialHashedPassword = "$6$8n5a7Wv2pSxRbnlC$wUaKV9g05iT9USwuBssSG3/CBxNIjgNUw/HqWGcXntKBsVafADCUf8Wv4n0nAvhwUOx0ruPZ/YJKy1rpveERk.";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHza4EH8WS4lwVWhoLBPqAXv8u3rqGibpPRX5KCxoOwE samuel@cormier-iijima.com"
  ];
}
