{ nixpkgs, home-manager, ... }@inputs:
{
  "sciyoshi" = home-manager.lib.homeManagerConfiguration {
    pkgs = nixpkgs.legacyPackages."x86_64-linux";

    modules = [
      ../home
      ../home/linux.nix
    ];

    extraSpecialArgs = inputs;
  };
}
