{ pkgs, ... }: {
  nixpkgs.config.permittedInsecurePackages = [
    "nodejs-16.20.0"
  ];

  environment.systemPackages = [
    pkgs.cachix
    pkgs.nixpkgs-fmt
    pkgs.python311
    pkgs.mysql80
    pkgs.minio
    pkgs.apacheKafka
    pkgs.python311Packages.supervisor
    pkgs.ffmpeg
    pkgs.bun
    pkgs.just
    pkgs.process-compose
  ];

  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      fira-code
      fira-code-symbols
      noto-fonts
      victor-mono
      (nerdfonts.override { fonts = [ "VictorMono" "FiraCode" ]; })
    ];
  };

  services.nix-daemon.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "sciyoshi" ];
  nix.package = pkgs.nixUnstable;
  nix.linux-builder.enable = true;
  # home-manager.useUserPackages = true;
  home-manager.users.sciyoshi = import ./home;
  programs.zsh.enable = true;

  system.defaults = {
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      dashboard-in-overlay = true;
      wvous-br-corner = 1;
      wvous-bl-corner = 1;
      wvous-tr-corner = 1;
      wvous-tl-corner = 1;
    };
    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "Nlsv";
      QuitMenuItem = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true;
    };
    LaunchServices = {
      LSQuarantine = false;
    };
    NSGlobalDomain = {
      NSDisableAutomaticTermination = true;
      NSNavPanelExpandedStateForSaveMode = true;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      "com.apple.swipescrolldirection" = false;
    };
  };

  homebrew.enable = true;
  homebrew.global.brewfile = true;
  homebrew.onActivation.autoUpdate = true;
  homebrew.casks = [
    "visual-studio-code"
    "firefox"
    "google-chrome"
    "spotify"
    "rectangle"
    "alacritty"
    "kitty"
    "figma"
    "discord"
    "vlc"
    "signal"
    "linear-linear"
    "docker"
    "transmission-remote-gui"
    "adobe-acrobat-reader"
  ];

  homebrew.masApps = {
    Slack = 803453959;
    Tailscale = 1475387142;
  };

  users.users.sciyoshi = {
    name = "sciyoshi";
    home = "/Users/sciyoshi";
  };

  services.redis.enable = true;

  services.dnsmasq.enable = true;
  services.dnsmasq.addresses = {
    "localhost" = "127.0.0.1";
    ".dev" = "127.0.0.1";
  };

  launchd.user.agents.mysql =
    {
      path = [ pkgs.mysql80 ];
      command = "${pkgs.mysql80}/bin/mysqld";

      serviceConfig.KeepAlive = true;
      serviceConfig.RunAtLoad = true;
    };

  launchd.user.agents.minio =
    {
      path = [ pkgs.minio ];
      command = "${pkgs.minio}/bin/minio server /var/lib/minio";

      serviceConfig.KeepAlive = true;
      serviceConfig.RunAtLoad = true;
    };

  launchd.user.agents.kafka =
    {
      path = [ pkgs.apacheKafka ];
      command = "${pkgs.apacheKafka}/bin/kafka-server-start.sh ${pkgs.apacheKafka}/config/kraft/server.properties";

      serviceConfig.KeepAlive = true;
      serviceConfig.RunAtLoad = true;
    };

  launchd.user.agents.connect =
    let
      connectConfigBase = builtins.readFile "${pkgs.apacheKafka}/config/connect-standalone.properties";
      connectConfig = builtins.toFile "connect-standalone.properties" "
        ${connectConfigBase}
        plugin.path=/opt/debezium/
      ";
    in
    {
      path = [ pkgs.apacheKafka ];
      command = "${pkgs.apacheKafka}/bin/connect-standalone.sh ${connectConfig}";

      serviceConfig.KeepAlive = true;
      serviceConfig.RunAtLoad = true;
    };

  launchd.user.agents.elasticsearch =
    {
      command = "/opt/elasticsearch/bin/elasticsearch";

      serviceConfig.KeepAlive = true;
      serviceConfig.RunAtLoad = true;
    };

  launchd.user.agents.kibana =
    {
      command = "/opt/kibana/bin/kibana";

      serviceConfig.KeepAlive = true;
      serviceConfig.RunAtLoad = true;
    };
}
