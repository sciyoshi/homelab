{
  description = "Homelab";

  nixConfig = {
    extra-substituters = [
      "https://cache.flox.dev"
      "https://cache.numtide.com"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    impermanence.url = "github:nix-community/impermanence";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
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
    flox = {
      url = "github:flox/flox";
    };
    nix-ai-tools = {
      url = "github:numtide/llm-agents.nix";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      sops-nix,
      impermanence,
      flake-utils,
      home-manager,
      deploy-rs,
      darwin,
      nixos-hardware,
      flox,
      nix-ai-tools,
      ...
    }@inputs:
    rec {
      darwinConfigurations = import ./nix/darwin.nix inputs;

      nixosConfigurations = import ./nix/nixos.nix inputs;

      homeConfigurations = import ./nix/home-manager.nix inputs;

      deploy = import ./nix/deploy.nix inputs;

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    }
    // flake-utils.lib.eachSystem [ "aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux" ] (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        packages.default = home-manager.packages.${system}.default;

        devShells.default = import ./nix/shell.nix { inherit pkgs; };
      }
    );
}
