{ nixpkgs
, home-manager
, sops-nix
, impermanence
, ...
}@inputs:
let
  makeSystem = hostModules: nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
      impermanence.nixosModules.impermanence
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs; };
        home-manager.users.sciyoshi = import ../home;
      }
    ] ++ hostModules;
  };
in
{
  "alpha" = makeSystem [ ../hosts/alpha.nix ];
  "beta" = makeSystem [ ../hosts/beta.nix ];
  "scilo" = makeSystem [ ../hosts/scilo.nix ];
  "scipi3" = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    pkgs = nixpkgs.legacyPackages."aarch64-linux";
    modules = [
      (import "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
      ../hosts/scipi3.nix
    ];
  };
}
