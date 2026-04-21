{ pkgs, specialArgs, ... }:
{
  home.packages =
    with pkgs;
    [
      awscli2
      borgbackup
      bun
      caddy
      envsubst
      fastmod
      fd
      fresh-editor
      gh
      gnupg
      jq
      maturin
      micro
      mkcert
      ngrok
      nil
      nixfmt
      nodejs_24
      postgresql
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
      specialArgs.inputs.flox.packages.${pkgs.stdenv.hostPlatform.system}.default
      specialArgs.inputs.nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system}.crush
      specialArgs.inputs.nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
      specialArgs.inputs.nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system}.codex
    ]
    ++ (
      if !pkgs.stdenv.isAarch64 || pkgs.stdenv.isDarwin then
        [
          aws-vault
          just
          kubectl
          kubectx
          pinentry-curses
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

  programs.ssh.enable = true;
  programs.ssh.enableDefaultConfig = false;
  programs.ssh.matchBlocks."*" = {
    forwardAgent = true;
    sendEnv = [ "ZELLIJ" ];
    identityAgent = if pkgs.stdenv.isDarwin then "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"" else null;

    #extraConfig = ''
    #  SendEnv ZELLIJ
    #  ${pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
    #    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    #  ''}
    #'';
  };

  # services.gpg-agent = {
  #   enable = true;
  #   pinentryFlavor = "curses";
  # };

  # programs.gitui.enable = true;
}
