{
  description = "Homelab";

  nixConfig.extra-experimental-features = "nix-command flakes";

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

  outputs =
    { self
    , nixpkgs
    , sops-nix
    , flake-utils
    , home-manager
    , deploy-rs
    , darwin
    , ...
    }@inputs: {
      darwinConfigurations = import ./nix/darwin.nix inputs;

      nixosConfigurations = import ./nix/nixos.nix inputs;

      homeConfigurations = import ./nix/home-manager.nix inputs;

      deploy = import ./deploy.nix inputs;

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    } // flake-utils.lib.eachSystem [ "aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux" ] (system:
    let pkgs = nixpkgs.legacyPackages.${system}; in rec {
      packages.default = home-manager.defaultPackage.${system};

      devShells.default = import ./shell.nix { inherit pkgs; };
    });
}
