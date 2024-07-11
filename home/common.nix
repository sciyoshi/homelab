{ pkgs, ... }: {
  home.packages = with pkgs; [
    aws-sso-creds
    borgbackup
    cachix
    caddy
    envsubst
    fastmod
    gnupg
    jq
    just
    maturin
    micro
    mkcert
    nixpkgs-fmt
    nodejs_20
    nssTools
    pre-commit
    process-compose
    ripgrep
    sops
    stern
    tig
    vim
    xh
    yq-go
    zstd
  ] ++ (if !pkgs.stdenv.isAarch64 || pkgs.stdenv.isDarwin then [
    aws-vault
    awscli2
    poetry
    python312
    rustup
    kubectl
    kubectx
    pinentry.curses
  ] else [ ]);

  xdg.enable = true;

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

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
