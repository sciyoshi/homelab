{ pkgs, config, ... }:
{
  virtualisation.oci-containers.containers = {
    pihole = {
      image = "pihole/pihole:latest";
      extraOptions = [ "--pull=always" ];

      volumes = [
        "/var/lib/pihole/etc-pihole:/etc/pihole"
        "/var/lib/pihole/etc-dnsmasq.d:/etc/dnsmasq.d"
      ];

      environment = {
        TZ = "America/Montreal";
      };

      ports = [
        "53:53/tcp"
        "53:53/udp"
        "80:80/tcp"
      ];

      autoStart = true;
    };
  };
}
