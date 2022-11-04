{ nixpkgs
, home-manager
, sops-nix
, impermanence
, ...
}@inputs: {
  "alpha" = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ../hosts/alpha.nix
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs; };
        home-manager.users.sciyoshi = import ../home;
      }
      sops-nix.nixosModules.sops
    ];
  };
  "beta" = nixpkgs.lib.nixosSystem
    {
      system = "x86_64-linux";
      modules = [
        ../hosts/beta.nix
        impermanence.nixosModules.impermanence
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.sciyoshi = import ../home;
        }
        sops-nix.nixosModules.sops
      ];
    };
  # "scilo" = nixpkgs.lib.nixosSystem
  #   {
  #     system = "x86_64-linux";
  #     modules = [
  #       ../scilo/configuration.nix
  #       home-manager.nixosModules.home-manager
  #       sops-nix.nixosModules.sops
  #     ];
  #   };
}
