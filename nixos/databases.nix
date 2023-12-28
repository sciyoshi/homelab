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
    extraPlugins = [ pkgs.pgvecto-rs ];
    authentication = lib.mkForce ''
      local all  all           peer
      host  all  all 0.0.0.0/0 scram-sha-256
    '';
  };

  services.postgresqlBackup = {
    enable = true;
    location = "/media/local/backup/postgresql";
    compression = "none";
  };

  services.borgbackup.jobs.postgresql = {
    paths = "/media/local/backup/postgresql";
    encryption.mode = "repokey";
    encryption.passCommand = "cat ${config.sops.secrets.borg_passphrase.path}";
    environment.BORG_RSH = "ssh -o 'StrictHostKeyChecking=no' -i ${config.sops.secrets.borg_private_key.path}";
    repo = "borg@100.119.209.24:.";
    compression = "auto,zstd";
    startAt = "daily";
    prune.keep = {
      daily = 7;
      weekly = 4;
      monthly = -1;
    };
  };

  networking.firewall.allowedTCPPorts = [ 5432 6379 ];
}
