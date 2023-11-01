{ pkgs, config, ... }: {
  sops.defaultSopsFile = ../secrets.yaml;

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  sops.secrets.acme_credentials = { };
  sops.secrets.borg_passphrase = { };
  sops.secrets.borg_private_key = { };
  sops.secrets.tailscale_key = { };
  sops.secrets.k3s_token = { };
  sops.secrets.k3s_vpn_auth = { };
  sops.secrets.wireless_env = { };
  sops.secrets.redis_password = { };

  sops.templates.immich_env.content = ''
    REDIS_PASSWORD=${config.sops.placeholder.redis_password}
  '';
}
