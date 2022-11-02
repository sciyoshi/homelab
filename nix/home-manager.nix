{ home-manager, ... }: {
  "sciyoshi" = home-manager.lib.homeManagerConfiguration {
    modules = [ ../home.nix ];
  };
}
