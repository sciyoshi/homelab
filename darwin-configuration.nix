{ pkgs, ... }: {
  nixpkgs.config.permittedInsecurePackages = [
    "nodejs-16.20.0"
  ];

  environment.systemPackages = [
    pkgs.nixpkgs-fmt
    pkgs.python311
    pkgs.mysql80
    pkgs.minio
    pkgs.apacheKafka
    pkgs.python311Packages.supervisor
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
  nix.package = pkgs.nixUnstable;
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
}
