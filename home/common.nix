{ pkgs, specialArgs, ... }:
{
  home.packages =
    with pkgs;
    [
      awscli2
      borgbackup
      caddy
      envsubst
      fastmod
      fd
      gh
      gnupg
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
      uv
      python313
      xh
      yq-go
      zstd
      rustup
      specialArgs.inputs.flox.packages.${pkgs.system}.default
    ]
    ++ (
      if !pkgs.stdenv.isAarch64 || pkgs.stdenv.isDarwin then
        [
          aws-vault
          just
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

  programs.ssh.matchBlocks."*" = {
    forwardAgent = true;
    extraConfig = ''
      SendEnv ZELLIJ
      ${pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
        IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      ''}
    '';
  };

  # services.gpg-agent = {
  #   enable = true;
  #   pinentryFlavor = "curses";
  # };

  # programs.gitui.enable = true;
}
