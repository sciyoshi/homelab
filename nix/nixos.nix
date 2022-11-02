{ nixpkgs, home-manager, sops-nix, ... }: {
  "alpha" = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
      ../hosts/alpha.nix
    ];
  };
  "beta" = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ../hosts/beta.nix
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];
  };
  "scilo" = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ../scilo/configuration.nix
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];
  };
}
