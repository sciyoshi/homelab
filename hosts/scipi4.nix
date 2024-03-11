{ pkgs, lib, config, modulesPath, ... }: {
  imports = [
    ../nixos/configuration.nix
    ../nixos/homeassistant.nix
    ../nixos/rumqttd.nix
  ];

  boot.initrd.supportedFilesystems = lib.mkForce [ "vfat" ];
  boot.supportedFilesystems = lib.mkForce [ "vfat" ];

  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.grub.enable = false;

  nixpkgs.hostPlatform = "aarch64-linux";
  nixpkgs.buildPlatform = "x86_64-linux";

  nixpkgs.overlays = [
    (import ../overlays/rumqttd.nix)
    (import ../overlays/zigbee2mqtt.nix)
  ];

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
  networking.firewall.enable = false;
  networking.firewall = {
    allowedTCPPorts = [ 1883 1884 8123 ];
    allowedUDPPorts = [ 1883 1884 8123 ];
  };
  users.users.root.initialHashedPassword = "$6$8n5a7Wv2pSxRbnlC$wUaKV9g05iT9USwuBssSG3/CBxNIjgNUw/HqWGcXntKBsVafADCUf8Wv4n0nAvhwUOx0ruPZ/YJKy1rpveERk.";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHza4EH8WS4lwVWhoLBPqAXv8u3rqGibpPRX5KCxoOwE samuel@cormier-iijima.com"
  ];

  disabledModules = [ "profiles/base.nix" ];

  networking = {
    hostName = "scipi4";
  };

  virtualisation.oci-containers.containers = {
    zigbee2mqtt = {
      image = "koenkk/zigbee2mqtt:latest";
      extraOptions = [
        "--pull=always"
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
  };
}
