{ pkgs, ... }: {
  home.packages = with pkgs; [
    aws-sso-creds
    borgbackup
    caddy
    envsubst
    fastmod
    # gnupg
    jq
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
    xh
    yq-go
    zstd
  ] ++ (if !pkgs.stdenv.isAarch64 || pkgs.stdenv.isDarwin then [
    aws-vault
    just
    poetry
    python312
    rustup
    kubectl
    kubectx
    pinentry.curses
  ] else [ ]);

  # xdg.enable = true;

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
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
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
