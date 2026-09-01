{
  pkgs,
  lib,
  specialArgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  codexAcp = specialArgs.inputs.nix-ai-tools.packages.${system}.codex-acp;
in
{
  home.packages = [
    codexAcp
    pkgs.zed-editor
  ];

  xdg.configFile."wofi/config" = {
    force = true;
    text = ''
      width=540
      height=420
      location=center
      prompt=Search applications…
      insensitive=true
      allow_images=true
      image_size=28
      columns=1
      lines=8
      matching=fuzzy
      no_actions=true
    '';
  };

  xdg.configFile."wofi/style.css" = {
    force = true;
    text = ''
      /* Catppuccin Mocha - Wofi */
      * {
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size: 18px;
      }
      window {
        background-color: #1e1e2e; /* Base */
        border: 2px solid #b4befe; /* Accent */
      }

      scrollbar,
      scrollbar trough,
      undershoot.top,
      undershoot.bottom {
        min-width: 5px;
        min-height: 5px;
        background: none;
      }
      scrollbar slider {
        background-color: #b4befe;
      }

      #input image {
        color: #b4befe; /* Accent */
        -gtk-icon-effect: none;
      }
      #input {
        background-color: #313244; /* Surface0 */
        color: #cdd6f4; /* Text */
        border: 1px solid #45475a; /* Surface1 */
        padding: 8px 12px;
        margin: 10px;
        border-radius: 35px;
        outline: 1px solid #585b70;
      }
      #input:focus {
        border-color: #b4befe; /* Accent */
      }
      #input placeholder {
        color: #6c7086; /* Overlay0 */
      }
      #scroll {
        margin: 0 8px 8px 8px;
      }
      #inner-box {
        background-color: transparent;
      }
      #outer-box {
        padding: 4px;
        background-color: #1e1e2e;
        padding: 10px;
        border: 2px solid #b4befe;
      }
      #entry {
        background-color: #1e1e2e;
        color: #cdd6f4;
      }
      #entry #entry:selected {
        background-color: #313244;
        color: #b4befe;
      }
      #entry:selected {
        background-color: #313244;
        color: #b4befe;
      }
      #entry:hover {
        background-color: #45475a; /* Surface1 */
      }
      #text {
        color: #cdd6f4; /* Text */
      }
      #text:selected {
        color: #b4befe; /* Accent */
      }
      #img {
        margin-right: 8px;
      }
    '';
  };

  services.wpaperd = {
    enable = true;
    settings.any = {
      path = "/srv/data/Content/Wallpapers";
      duration = "30m";
      sorting = "random";
      mode = "center";
    };
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 34;
      spacing = 8;

      modules-left = [
        "niri/workspaces"
        "niri/window"
      ];
      modules-right = [
        "pulseaudio"
        "network"
        "cpu"
        "memory"
        "tray"
        "clock"
      ];

      "niri/workspaces" = {
        format = "{icon}";
        format-icons = {
          active = "●";
          default = "○";
        };
      };

      "niri/window" = {
        format = "{}";
        max-length = 60;
      };

      pulseaudio = {
        format = "VOL {volume}%";
        format-muted = "VOL muted";
        on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        on-scroll-up = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
        on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      };

      network = {
        format-wifi = "{essid}  {signalStrength}%";
        format-ethernet = "Ethernet";
        format-disconnected = "Offline";
        tooltip-format = "{ifname}: {ipaddr}/{cidr}";
      };

      cpu = {
        format = "CPU {usage}%";
        interval = 5;
      };

      memory = {
        format = "MEM {percentage}%";
        interval = 5;
      };

      tray.spacing = 8;

      clock = {
        format = "{:%a %b %d  %H:%M}";
        tooltip-format = "<big>{:%Y-%m-%d}</big>\n<tt>{calendar}</tt>";
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "FiraCode Nerd Font";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: rgba(24, 24, 32, 0.94);
        color: #e6e1e5;
      }

      #workspaces button {
        padding: 0 7px;
        color: #817f8a;
      }

      #workspaces button.active {
        color: #c4b5fd;
      }

      #workspaces button:hover {
        background: #353442;
        color: #ffffff;
      }

      #window {
        color: #b8b4c0;
      }

      #pulseaudio,
      #network,
      #cpu,
      #memory,
      #tray,
      #clock {
        padding: 0 7px;
      }

      #clock {
        margin-right: 6px;
        color: #ffffff;
        font-weight: bold;
      }

      #network.disconnected,
      #pulseaudio.muted {
        color: #f2a7a7;
      }
    '';
  };

  home.activation.linkCodexAcpForZed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    codex_acp="${codexAcp}/bin/codex-acp"

    for agent_root in "$HOME/.local/share/zed/external_agents/codex" "$HOME/.local/share/zed-preview/external_agents/codex"; do
      if [ -d "$agent_root" ]; then
        for version_dir in "$agent_root"/*; do
          if [ -d "$version_dir" ]; then
            $DRY_RUN_CMD ln -sfn "$codex_acp" "$version_dir/codex-acp"
          fi
        done
      fi
    done
  '';
}
