{ pkgs, config, ... }@inputs: {
  imports = [
    (./hardware/ovh.nix)
  ];

  boot.cleanTmpDir = true;

  system.stateVersion = "22.11";

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  zramSwap.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.secrets.tailscale_key = { };

  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;

  security.sudo.wheelNeedsPassword = false;

  networking.firewall.allowPing = true;
  networking.firewall.checkReversePath = "loose";

  virtualisation.docker.enable = true;

  nixpkgs.config.allowUnfree = true;

  networking.nat.enable = true;
  networking.nat.externalInterface = "ens3";
  networking.nat.internalInterfaces = [ "wg0" ];
  networking.firewall = {
    allowedTCPPorts = [ 6443 ];
    allowedUDPPorts = [ 51820 ];
  };

  services.resolved.enable = true;
  services.openssh.enable = true;
  services.tailscale.enable = true;

  # services.k3s.enable = true;
  # services.k3s.role = "server";
  # services.k3s.extraFlags = toString [
  #   "--write-kubeconfig-mode=644"
  #   "--flannel-iface=tailscale0"
  # ];

  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      ${tailscale}/bin/tailscale up --auth-key=$(cat "${config.sops.secrets.tailscale_key.path} --advertise-exit-node")
    '';
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHza4EH8WS4lwVWhoLBPqAXv8u3rqGibpPRX5KCxoOwE samuel@cormier-iijima.com"
  ];

  users.users.sciyoshi = {
    isNormalUser = true;
    extraGroups = [ "sudo" "wheel" ];
    shell = pkgs.zsh;
    initialHashedPassword = "$6$8n5a7Wv2pSxRbnlC$wUaKV9g05iT9USwuBssSG3/CBxNIjgNUw/HqWGcXntKBsVafADCUf8Wv4n0nAvhwUOx0ruPZ/YJKy1rpveERk.";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHza4EH8WS4lwVWhoLBPqAXv8u3rqGibpPRX5KCxoOwE samuel@cormier-iijima.com"
    ];
  };

  environment.systemPackages = [
    pkgs.docker
    pkgs.exa
    pkgs.fzf
    pkgs.rustup
    pkgs.ripgrep
    pkgs.starship
    pkgs.tailscale
    pkgs.k3s
  ];

  environment.shellAliases = {
    l = "exa -l";
    ll = "exa -l";
    la = "exa -la";
  };

  programs.bash.promptInit = "eval \"$(starship init bash)\"";
  programs.zsh.promptInit = "eval \"$(starship init zsh)\"";
  programs.zsh.enable = true;
  programs.zsh.shellInit = ''
    bindkey "^[[1;5C" forward-word
    bindkey "^[[1;5D" backward-word
  '';

  time.timeZone = "America/Montreal";

  home-manager.users.sciyoshi = import ../home.nix inputs;
}
