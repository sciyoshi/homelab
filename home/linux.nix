{ pkgs, ... }: {
  home.username = "sciyoshi";
  home.homeDirectory = "/home/sciyoshi";

  targets.genericLinux.enable = true;
}
