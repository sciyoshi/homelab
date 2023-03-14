{ pkgs, ... }: {
  home.packages = with pkgs; [
    awscli2
    borgbackup
    caddy
    fastmod
    gnupg
    kubectl
    kubectx
    mkcert
    nixpkgs-fmt
    nodejs
    nodejs-16_x
    nssTools
    pinentry.curses
    poetry
    pre-commit
    ripgrep
    rustup
    sops
    stern
    tig
    vim
  ];

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

  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "curses";
  };

  programs.gitui.enable = true;
}
