{ lib, pkgs, config, ... }: {
  services.redis.servers = {
    immich = {
      enable = true;
      openFirewall = true;
      port = 6379;
      bind = null;
      requirePassFile = "${config.sops.secrets.redis_password.path}";
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    enableTCPIP = true;
    authentication = lib.mkForce ''
      local all  all           peer
      host  all  all 0.0.0.0/0 scram-sha-256
    '';
  };

  networking.firewall.allowedTCPPorts = [ 5432 6379 ];
}
