{ pkgs, config, ... }:
{
  virtualisation.oci-containers = {
    containers.homeassistant = {
      volumes = [ "home-assistant:/config" ];
      image = "ghcr.io/home-assistant/home-assistant:latest";

      extraOptions = [
        "--pull=always"
        "--network=host"
      ];

      environment = {
        TZ = "America/Montreal";
      };
    };
  };
}
