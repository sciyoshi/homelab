{ pkgs, config, ... }:
let
  config = pkgs.writeText "rumqttd.toml" ''
    id = 0

    # A commitlog read will pull full segment. Make sure that a segment isn't
    # too big as async tcp writes readiness of one connection might affect tail
    # latencies of other connection. Not a problem with preempting runtimes
    [router]
    id = 0
    max_connections = 10010
    max_outgoing_packet_count = 200
    max_segment_size = 104857600
    max_segment_count = 10

    # Configuration of server and connections that it accepts
    [v4.1]
    name = "v4-1"
    listen = "0.0.0.0:1883"
    next_connection_delay_ms = 1
        [v4.1.connections]
        connection_timeout_ms = 60000
        max_payload_size = 20480
        max_inflight_count = 100
        dynamic_filters = true

    [v5.1]
    name = "v5-1"
    listen = "0.0.0.0:1884"
    next_connection_delay_ms = 1
        [v5.1.connections]
        connection_timeout_ms = 60000
        max_payload_size = 56480
        max_inflight_count = 100

    [prometheus]
    listen = "127.0.0.1:9042"
    interval = 1

    [ws.1]
    name = "ws-1"
    listen = "0.0.0.0:8083"
    next_connection_delay_ms = 1
        [ws.1.connections]
        connection_timeout_ms = 60000
        max_client_id_len = 256
        throttle_delay_ms = 0
        max_payload_size = 20480
        max_inflight_count = 500
        max_inflight_size = 1024

    [console]
    listen = "0.0.0.0:3030"
  '';
in
{
  systemd.services.rumqttd = {
    description = "rumqttd";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "exec";
      ExecStart = ''${pkgs.rumqttd}/bin/rumqttd -c ${config}'';
    };
  };
}
