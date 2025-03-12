{ pkgs, config, ... }:
{
  services.openssh.enable = true;
  services.openssh.extraConfig = ''
    AcceptEnv ZELLIJ
  '';
}
