{ pkgs, config, ... }: {
  environment.systemPackages = with pkgs; [
    borgbackup
    docker
    exa
    fzf
    git
    k3s
    ripgrep
    rustup
    starship
    tailscale
    unzip
    wget
    wireguard-tools
  ];

  environment.shellAliases = {
    l = "exa -l";
    ll = "exa -l";
    la = "exa -la";
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
