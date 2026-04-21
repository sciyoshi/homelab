{ pkgs, ... }:
pkgs.mkShell {
  NIX_CONFIG = "experimental-features = nix-command flakes";

  nativeBuildInputs = with pkgs; [
    home-manager
    git
    nixfmt
    deploy-rs
    sops
    gnupg
    age
  ];
}
