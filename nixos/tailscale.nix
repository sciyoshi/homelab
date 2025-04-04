{
  pkgs,
  config,
  lib,
  ...
}:
{
  options.services.tailscale.autoconnect = {
    enable = lib.mkEnableOption "Tailscale autoconnect service";

    params = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    authKeyCommand = lib.mkOption {
      type = lib.types.str;
    };
  };

  config.systemd.services.tailscale-autoconnect =
    lib.mkIf config.services.tailscale.autoconnect.enable
      {
        description = "Automatic connection to Tailscale";

        # make sure tailscale is running before trying to connect to tailscale
        after = [
          "network-pre.target"
          "tailscale.service"
        ];
        wants = [
          "network-pre.target"
          "tailscale.service"
        ];
        wantedBy = [ "multi-user.target" ];

        # set this service as a oneshot job
        serviceConfig.Type = "oneshot";

        # have the job run this shell script
        script = with pkgs; ''
          # wait for tailscaled to settle
          sleep 5

          # check if we are already authenticated to tailscale
          status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
          if [ $status = "Running" ]; then # if so, then do nothing
            exit 0
          fi

          # otherwise authenticate with tailscale
          ${tailscale}/bin/tailscale up --auth-key=$(${config.services.tailscale.autoconnect.authKeyCommand}) ${builtins.concatStringsSep " " config.services.tailscale.autoconnect.params}
        '';
      };
}
