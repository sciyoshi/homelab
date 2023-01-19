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
    nodejs
    nssTools
    pinentry.curses
    poetry
    ripgrep
    rustup
    sops
    tig
    stern
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

  home.file.".aws/config".text = ''
    [default]
    region = ca-central-1
  '';

  programs.gitui.enable = true;
}
