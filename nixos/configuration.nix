{ pkgs, config, ... }@inputs:
{
  imports = [
    ./hardware/ovh.nix
    ./common.nix
    ./tailscale.nix
    ./openssh.nix
    ./users.nix
    ./borgbackup.nix
    ./secrets.nix
  ];

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

  system.stateVersion = "23.11";
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;

  # systemd.enableUnifiedCgroupHierarchy = true;

  security.sudo.enable = false;
  security.sudo-rs.enable = true;

  security.sudo.wheelNeedsPassword = false;
  security.sudo-rs.wheelNeedsPassword = false;

  networking.firewall.allowPing = true;
  networking.firewall.checkReversePath = "loose";

  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets.tailscale_key.path;
    extraSetFlags = [
      "--advertise-exit-node"
    ];
  };

  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  nixpkgs.config.allowUnfree = true;

  networking.nameservers = [
    "1.1.1.1#one.one.one.one"
    "1.0.0.1#one.one.one.one"
  ];

  networking.nat.enable = true;
  networking.nat.externalInterface = "ens3";
  networking.nat.internalInterfaces = [ "wg0" ];
  networking.firewall = {
    allowedTCPPorts = [
      80
      443
      6443
      9443
      9080
    ];
    allowedUDPPorts = [ 51820 ];
  };

  services.resolved = {
    enable = true;
    dnssec = "true";
    fallbackDns = [
      "1.1.1.1#one.one.one.one"
      "1.0.0.1#one.one.one.one"
    ];
    dnsovertls = "true";
  };

  services.k3s = {
    enable = true;
    role = "agent";
    tokenFile = config.sops.secrets.k3s_token.path;
    environmentFile = pkgs.writeText "k3s.env" "PATH=${pkgs.tailscale}/bin:/bin";
    extraFlags = "--vpn-auth-file=${config.sops.secrets.k3s_vpn_auth.path}";
    serverAddr = "https://100.114.10.116:6443";
  };
}
