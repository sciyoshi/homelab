{ pkgs, config, ... }@inputs: {
  imports = [
    ./hardware/ovh.nix
    ./common.nix
    ./tailscale.nix
    ./openssh.nix
    ./users.nix
    ./borgbackup.nix
    ./xray.nix
  ];

  boot.tmp.cleanOnBoot = true;
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;

  zramSwap.enable = true;

  sops.defaultSopsFile = ../secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.secrets.tailscale_key = { };
  sops.secrets.k3s_token = { };
  sops.secrets.k3s_vpn_auth = { };
  sops.secrets.wireless_env = { };

  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.stateVersion = "23.11";
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;

  security.sudo.wheelNeedsPassword = false;

  networking.firewall.allowPing = true;
  networking.firewall.checkReversePath = "loose";

  services.tailscale = {
    enable = true;
    autoconnect = {
      enable = true;
      params = [ "--advertise-exit-node" ];
      authKeyCommand = ''cat "${config.sops.secrets.tailscale_key.path}"'';
    };
  };

  virtualisation.docker.enable = true;

  nixpkgs.config.allowUnfree = true;

  networking.nat.enable = true;
  networking.nat.externalInterface = "ens3";
  networking.nat.internalInterfaces = [ "wg0" ];
  networking.firewall = {
    allowedTCPPorts = [ 80 443 6443 9443 9080 ];
    allowedUDPPorts = [ 51820 ];
  };

  services.resolved.enable = true;

  services.k3s = {
    enable = true;
    role = "agent";
    tokenFile = config.sops.secrets.k3s_token.path;
    environmentFile = pkgs.writeText "k3s.env" "PATH=${pkgs.tailscale}/bin:/bin";
    extraFlags = "--vpn-auth-file=${config.sops.secrets.k3s_vpn_auth.path}";
    serverAddr = "https://100.114.10.116:6443";
  };
}
