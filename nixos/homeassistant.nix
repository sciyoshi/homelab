{ pkgs, config, ... }:
{
  virtualisation.oci-containers = {
    containers.homeassistant = {
      volumes = [ "/var/lib/home-assistant:/config" ];
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

  networking.firewall.allowedTCPPorts = [ 8123 ];
}
