{ self, deploy-rs, nixpkgs, ... }: {
  autoRollback = false;
  magicRollback = true;
  user = "root";
  nodes = {
    alpha = {
      hostname = "alpha.sciyoshi.com";
      sshUser = "root";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.alpha;
      };
    };
    beta = {
      hostname = "beta.sciyoshi.com";
      sshUser = "root";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.beta;
      };
    };
    scilo = {
      hostname = "scilo";
      sshUser = "root";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.scilo;
      };
    };
    # scipi3 = {
    #   hostname = "192.168.50.147";
    #   sshUser = "root";
    #   profiles.system = {
    #     user = "root";
    #     path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.scipi3;
    #   };
    # };
  };
}
