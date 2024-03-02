{ pkgs, config, ... }: {
  systemd.services.rumqttd = {
    description = "rumqttd";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "exec";
      ExecStart = ''${pkgs.rumqttd}/bin/rumqttd'';
    };
  };
}
