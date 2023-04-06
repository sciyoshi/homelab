{ pkgs, config, lib, ... }: {
  services.caddy = {
    enable = true;
    virtualHosts."beta.sciyoshi.com".extraConfig = ''
      reverse_proxy http://127.0.0.1:20001
    '';
  };

  services.xray.enable = true;
  services.xray.settings = {
    inbounds = [{
      port = 20001;
      listen = "127.0.0.1";
      protocol = "http";
      settings = {
        clients = [{
          id = "58372395-ece7-482f-8f95-ae7db4b1f91b";
          level = 0;
          email = "sciyoshi@gmail.com";
        }];
        decryption = "none";
        fallbacks = [{
          dest = 80;
        }];
      };
    }];
    outbounds = [{
      protocol = "freedom";
    }];
  };
}
