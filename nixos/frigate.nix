{
  virtualisation.oci-containers.containers = {
    frigate = {
      image = "ghcr.io/blakeblackshear/frigate:stable";
      extraOptions = [
        "--network=immich-bridge"
        "--pull=always"
        "--shm-size=256m"
        "--device=/dev/bus/usb:/dev/bus/usb"
        # "--device=nvidia.com/gpu=all"
        "--mount=type=tmpfs,target=/tmp/cache,tmpfs-size=1000000000"
        "--privileged"
      ];

      volumes = [
        "/media/local/frigate:/media/frigate"
        "/home/sciyoshi/frigate-config:/config"
        "/etc/localtime:/etc/localtime:ro"
      ];

      environment = {
        FRIGATE_RTSP_PASSWORD = "password";
      };

      ports = [ "5000:5000" "8554:8554" "8555:8555/tcp" "8555:8555/udp" ];

      autoStart = true;
    };
  };
}
