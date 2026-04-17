inputs@{ darwin, home-manager, ... }:
{
  "fellow-sci" = darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [
      inputs.determinate.darwinModules.default
      ../darwin-configuration.nix
      home-manager.darwinModules.home-manager
    ];
    specialArgs = { inherit inputs; };
  };
}
