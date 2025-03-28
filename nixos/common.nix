{ pkgs, config, ... }:
{
  environment.systemPackages =
    with pkgs;
    [
      bcache-tools
      borgbackup
      btrfs-progs
      docker
      eza
      fio
      flashbench
      fzf
      git
      k3s
      netcat-gnu
      openiscsi
      parted
      ripgrep
      starship
      tailscale
      unzip
      wget
      wireguard-tools
    ]
    ++ (
      if !pkgs.stdenv.isAarch64 then
        [
          smartmontools
          nvme-cli
        ]
      else
        [ ]
    );

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
