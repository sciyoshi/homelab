{ pkgs, specialArgs, ... }:
{
  nixpkgs.config.permittedInsecurePackages = [
    "nodejs-16.20.0"
  ];

  system.stateVersion = 5;

  # nixpkgs.overlays = [
  #   (import ./overlays/mysql80.nix)
  # ];

  environment.systemPackages = [
    pkgs.cachix
    pkgs.nixfmt-rfc-style
    pkgs.nil
    pkgs.python313
    pkgs.podman
    pkgs.podman-compose
    specialArgs.inputs.flox.packages.${pkgs.system}.default
    # pkgs.mysql80
    pkgs.minio
    pkgs.apacheKafka
    pkgs.python311Packages.supervisor
    pkgs.ffmpeg
    pkgs.bun
    pkgs.just
    pkgs.process-compose
    pkgs.less
  ];

  fonts = {
    packages = with pkgs; [
      fira-code
      fira-code-symbols
      noto-fonts
      victor-mono
      nerd-fonts.victor-mono
      nerd-fonts.fira-code
    ];
  };

  ids.gids.nixbld = 30000;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.trusted-users = [
    "root"
    "sciyoshi"
  ];
  nix.settings = {
    substituters = [
      "https://cache.flox.dev"
    ];
    trusted-public-keys = [
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
    ];
  };

  nix.package = pkgs.nixVersions.latest;
  nix.linux-builder.enable = true;
  nix.linux-builder.systems = [ "aarch64-linux" ];

  # Debug output for specialArgs
  # _debug = builtins.trace "specialArgs: ${builtins.toJSON specialArgs}" null;
  # home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = {
    flox = specialArgs.inputs.flox;
  };

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

  services.dnsmasq.enable = true;

  launchd.daemons.dnsmasq.serviceConfig.ProgramArguments = [
    "--address=/sci.fellow.dev/127.0.0.1"
    "--address=/sci.fellow.dev/::1"
  ];
}
