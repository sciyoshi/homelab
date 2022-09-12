{ pkgs, ... }: {
  environment.systemPackages = [
    pkgs.nixpkgs-fmt
    pkgs.python39
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
  home-manager.users.sciyoshi = import ./home.nix;
  programs.zsh.enable = true;

  system.defaults = {
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      dashboard-in-overlay = true;
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
  ];

  homebrew.masApps = {
    Slack = 803453959;
    Tailscale = 1475387142;
  };

  users.users.sciyoshi = {
    name = "sciyoshi";
    home = "/Users/sciyoshi";
  };
}
