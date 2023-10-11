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
    poetry
    pre-commit
    ripgrep
    rustup
    sops
    stern
    tig
    vim
    xh
  ] ++ (if !pkgs.stdenv.isAarch64 then [
    awscli2
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

  #services.gpg-agent = {
  #  enable = true;
  #  pinentryFlavor = "curses";
  #};

  programs.gitui.enable = true;
}
