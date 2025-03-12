{
  self,
  deploy-rs,
  nixpkgs,
  ...
}:
{
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
    gamma = {
      hostname = "gamma.sciyoshi.com";
      sshUser = "root";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.gamma;
      };
    };
    scilo = {
      hostname = "100.114.10.116";
      sshUser = "root";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.scilo;
      };
    };
    scipi4 = {
      hostname = "100.69.198.147";
      sshUser = "root";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.scipi4;
      };
    };
    misaki = {
      hostname = "100.119.209.24";
      sshUser = "root";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.misaki;
      };
    };
  };
}
