{
  pkgs,
  lib,
  config,
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

  # libX11 writes its Compose cache here instead of ~/.compose-cache.
  # The directory must exist before X clients start; old caches are disposable.
  home.sessionVariables.XCOMPOSECACHE = "${config.xdg.cacheHome}/X11/xcompose";
  home.activation.createXcomposeCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg config.home.sessionVariables.XCOMPOSECACHE}
  '';

  # CUDA regenerates JIT kernels here instead of ~/.nv/ComputeCache.
  home.sessionVariables.CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nvidia/ComputeCache";
  home.activation.createCudaCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg config.home.sessionVariables.CUDA_CACHE_PATH}
  '';

  # Wine creates a fresh default prefix here instead of ~/.wine.
  # Launchers that explicitly choose another WINEPREFIX retain their own prefix.
  home.sessionVariables.WINEPREFIX = "${config.xdg.dataHome}/wine";

  programs.firefox = {
    enable = true;
    # Keep the NixOS package; managing only the profile also avoids Home
    # Manager creating an unused ~/.mozilla/native-messaging-hosts directory.
    package = null;
    # Override the legacy default selected by home.stateVersion = "22.11".
    # Firefox 147+ uses this XDG config directory for a fresh profile.
    # One-time cleanup after closing Firefox: rm -rf ~/.mozilla
    # An existing ~/.mozilla wins over XDG; no profile data is imported here.
    configPath = "${config.xdg.configHome}/mozilla/firefox";
    profiles.default.isDefault = true;
  };

  # Chromium 146+ defaults to ~/.local/share/pki/nssdb for its NSS database.
  # No environment override is needed with our default XDG data location.
  # After closing Chromium/Electron apps, discard the preferred legacy DB:
  #   rm -rf ~/.pki
  # Older Electron apps may still recreate ~/.pki; no certificates are copied.
  home.activation.createNssDatabaseDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -m 0700 -p ${lib.escapeShellArg "${config.xdg.dataHome}/pki/nssdb"}
  '';

  # PERF_CONFIG replaces ~/.perfconfig; buildid.dir redirects the regenerable
  # ~/.debug build-ID cache. Old cached binaries are not copied.
  home.sessionVariables.PERF_CONFIG = "${config.xdg.configHome}/perf/config";
  xdg.configFile."perf/config".text = ''
    [buildid]
      dir = ${config.xdg.cacheHome}/perf/buildid
  '';

  home.pointerCursor = {
    enable = true;
    package = pkgs.apple-cursor;
    name = "macOS";
    size = 20;
    gtk.enable = true;
    x11.enable = true;
  };

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
      * {
        all: unset;
        font-family: "FiraCode Nerd Font";
        font-size: 14px;
      }

      window {
        padding: 14px;
        border: 1px solid #353442;
        border-radius: 14px;
        background-color: rgba(24, 24, 32, 0.97);
        color: #e6e1e5;
      }

      #outer-box {
        padding: 4px;
      }

      #input image {
        margin-right: 8px;
      }

      #input {
        margin-bottom: 10px;
        padding: 12px 14px;
        border: 1px solid #353442;
        border-radius: 9px;
        background-color: #20202a;
        color: #ffffff;
      }

      #input:focus {
        border-color: #817f8a;
      }

      #scroll {
        margin: 0;
      }

      #entry {
        padding: 9px 11px;
        border-radius: 8px;
        color: #b8b4c0;
      }

      #entry:selected {
        background-color: #353442;
        color: #ffffff;
      }

      #text:selected {
        color: #c4b5fd;
      }

      #img {
        margin-right: 12px;
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
