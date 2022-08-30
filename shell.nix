{ pkgs }: pkgs.mkShell {
  NIX_CONFIG = "experimental-features = nix-command flakes";

  nativeBuildInputs = with pkgs; [
    nix
    home-manager
    git
    deploy-rs
    sops
    gnupg
    age
  ];
}
