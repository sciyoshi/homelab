{ pkgs, ... }: {
  home.packages = with pkgs; [
    borgbackup
    caddy
    fastmod
    gnupg
    mkcert
    nixpkgs-fmt
    nodejs_20
    nssTools
    pre-commit
    ripgrep
    sops
    stern
    tig
    vim
    xh
    zstd
  ] ++ (if !pkgs.stdenv.isAarch64 || pkgs.stdenv.isDarwin then [
    awscli2
    poetry
    rustup
    kubectl
    kubectx
    pinentry.curses
  ] else [ ]);

  programs.ssh = {
    enable = true;
    forwardAgent = true;
    extraConfig = ''
      SendEnv ZELLIJ
    '';
  };

  programs.keychain = {
    enable = true;
    keys = [ "id_ed25519" ];
  };

  # services.gpg-agent = {
  #   enable = true;
  #   pinentryFlavor = "curses";
  # };

  programs.gitui.enable = true;
}
