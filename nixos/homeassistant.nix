{ pkgs, config, ... }:
{
  virtualisation.oci-containers = {
    containers.homeassistant = {
      volumes = [
        "/var/lib/home-assistant:/config"
        "/run/dbus:/run/dbus:ro"
      ];
      image = "ghcr.io/home-assistant/home-assistant:latest";

      extraOptions = [
        "--pull=always"
        "--network=host"
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
      ];

      environment = {
        TZ = "America/Montreal";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 8123 ];
}
