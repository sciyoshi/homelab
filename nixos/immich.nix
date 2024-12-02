{ pkgs, config, ... }:
let
  photosLocation = "/media/data/immich";
  environment = {
    DB_HOSTNAME = "host.docker.internal";
    DB_USERNAME = "immich";
    DB_DATABASE_NAME = "immich";
    DB_PASSWORD = "immich";
    IMMICH_SERVER_URL = "http://immich_server:2283";
    IMMICH_MACHINE_LEARNING_URL = "http://immich_machine_learning:3003";
    REDIS_HOSTNAME = "host.docker.internal";
  };
in
{
  virtualisation.oci-containers.containers = {
    immich_server = {
      image = "ghcr.io/immich-app/immich-server:release";
      extraOptions = [ "--network=immich-bridge" "--add-host=host.docker.internal:host-gateway" "--pull=always" ];

      volumes = [
        "${photosLocation}:/usr/src/app/upload"
      ];

      environmentFiles = [ "${config.sops.templates.immich_env.path}" ];
      environment = environment;

      ports = [ "2283:2283" ];

      autoStart = true;
    };

    immich_machine_learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:release";
      extraOptions = [ "--network=immich-bridge" "--add-host=host.docker.internal:host-gateway" "--pull=always" ];

      environmentFiles = [ "${config.sops.templates.immich_env.path}" ];
      environment = environment;

      volumes = [
        "${photosLocation}:/usr/src/app/upload"
        "model-cache:/cache"
      ];

      autoStart = true;
    };
  };

  systemd.services.init-immich-network = {
    description = "Create the network bridge for immich.";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      # Put a true at the end to prevent getting non-zero return code, which will
      # crash the whole service.
      check=$(${pkgs.podman}/bin/podman network ls | grep "immich-bridge" || true)
      if [ -z "$check" ];
        then ${pkgs.podman}/bin/podman network create immich-bridge
        else echo "immich-bridge already exists in podman"
      fi
    '';
  };

  services.nginx.virtualHosts."immich.sciyoshi.com" = {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;
    locations."/" = {
      proxyPass = "http://localhost:2283";
      extraConfig = ''
        client_max_body_size 0;
        proxy_max_temp_file_size 96384m;
      '';
    };
  };
}
