{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      aws-sso-creds
      awscli2
      borgbackup
      caddy
      envsubst
      fastmod
      fd
      gh
      # gnupg
      jq
      maturin
      micro
      mkcert
      nil
      nixfmt-rfc-style
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
      # flox.packages.${pkgs.system}.default
    ]
    ++ (
      if !pkgs.stdenv.isAarch64 || pkgs.stdenv.isDarwin then
        [
          aws-vault
          just
          poetry
          python313
          # rustup
          kubectl
          kubectx
          pinentry.curses
        ]
      else
        [ ]
    );

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

  # services.gpg-agent = {
  #   enable = true;
  #   pinentryFlavor = "curses";
  # };

  programs.gitui.enable = true;
}
