{ nixpkgs, home-manager, ... }@inputs:
{
  "sciyoshi" = home-manager.lib.homeManagerConfiguration {
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };

    modules = [
      ../home
      ../home/linux.nix
    ];

    extraSpecialArgs = inputs;
  };
}
