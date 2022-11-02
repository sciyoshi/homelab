{ darwin, home-manager, ... }: {
  "fellow-sam-2" = darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [
      ../darwin-configuration.nix
      home-manager.darwinModules.home-manager
    ];
  };
}
