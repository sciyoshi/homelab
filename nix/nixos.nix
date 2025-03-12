{
  nixpkgs,
  home-manager,
  sops-nix,
  impermanence,
  nixos-hardware,
  ...
}@inputs:
let
  makeSystem =
    hostModules:
    nixpkgs.lib.nixosSystem {
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
  "gamma" = makeSystem [ ../hosts/gamma.nix ];
  "scilo" = makeSystem [ ../hosts/scilo.nix ];
  "sci" = makeSystem [ ../sci/configuration.nix ];
  "scipi4" = nixpkgs.lib.nixosSystem {
    # system = "aarch64-linux";
    # pkgs = nixpkgs.legacyPackages."aarch64-linux";
    modules = [
      (import "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
      nixos-hardware.nixosModules.raspberry-pi-4
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
      impermanence.nixosModules.impermanence
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs; };
        home-manager.users.sciyoshi = import ../home;
      }
      ../hosts/scipi4.nix
    ];
  };

  "misaki" = nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit nixpkgs;
    };
    modules = [
      ./sd-utils/sd-aarch64.nix
      nixos-hardware.nixosModules.raspberry-pi-4
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
      impermanence.nixosModules.impermanence
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs; };
        home-manager.users.sciyoshi = import ../home;
      }
      ../hosts/misaki.nix
    ];
  };
}
