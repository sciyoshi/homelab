{
  description = "Homelab";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    sops-nix.url = github:Mic92/sops-nix;

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, sops-nix, flake-utils, home-manager, deploy-rs, darwin, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      darwinConfigurations."fellow-sam-2" = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./darwin-configuration.nix
          home-manager.darwinModules.home-manager
        ];
      };

      nixosConfigurations = {
        "alpha" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/alpha.nix
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
          ];
        };
        "beta" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/beta.nix
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
          ];
        };
        "scilo" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./scilo/configuration.nix
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
          ];
        };
      };

      homeConfigurations = {
        "sciyoshi" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [ ./home.nix ];
        };
      };

      deploy = import ./deploy.nix inputs;

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    } // flake-utils.lib.eachSystem [ "aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux" ] (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in rec {
        packages.default = home-manager.defaultPackage.${system};

        devShells.default = import ./shell.nix { inherit pkgs; };

        packages.x86_64-linux.default = home-manager.defaultPackage.x86_64-linux;
      });
}
