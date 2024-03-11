{ pkgs, ... }: pkgs.mkShell {
  NIX_CONFIG = "experimental-features = nix-command flakes";

  nativeBuildInputs = with pkgs; [
    nix
    home-manager
    git
    nixpkgs-fmt
    deploy-rs
    sops
    gnupg
    age
  ];
}
