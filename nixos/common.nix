{ pkgs, config, ... }: {
  environment.systemPackages = with pkgs; [
    borgbackup
    docker
    eza
    fzf
    git
    k3s
    openiscsi
    ripgrep
    # rustup
    starship
    tailscale
    unzip
    wget
    wireguard-tools
  ];

  environment.shellAliases = {
    l = "eza -l";
    ll = "eza -l";
    la = "eza -la";
  };

  programs.bash.promptInit = "eval \"$(starship init bash)\"";
  programs.zsh.promptInit = "eval \"$(starship init zsh)\"";
  programs.zsh.enable = true;
  programs.zsh.shellInit = ''
    bindkey "^[[1;5C" forward-word
    bindkey "^[[1;5D" backward-word
  '';

  time.timeZone = "America/Montreal";
}
