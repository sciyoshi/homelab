{ pkgs, ... }: {
  home.packages = with pkgs; [
    ripgrep
    nodejs
    kubectl
    awscli2
    kubectx
    caddy
    tig
    rustup
    fastmod
    poetry
    mkcert
    nssTools
    sops
    gnupg
    pinentry.curses
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
