final: prev: {
  home-assistant-custom-components = prev.home-assistant-custom-components.extend (
    _: _: {
      eufy_security = final.buildHomeAssistantComponent {
        owner = "fuatakgun";
        domain = "eufy_security";
        version = "8.2.4";
        src = final.fetchFromGitHub {
          owner = "fuatakgun";
          repo = "eufy_security";
          tag = "v8.2.4";
          hash = "sha256-Pn+ci4h016EX7dbJ7eh1lF0L0wkzw3g/AEWKN0QZpww=";
        };
        # Eufy Auto streaming can select H.265; expose H.264 for HA browsers.
        patches = [ ./eufy-security-h264.patch ];
        dependencies = with final.home-assistant.python3Packages; [
          aiortsp
          websocket-client
        ];
        # Use nixpkgs' compatible websocket-client 1.9 instead of the upstream 1.8 pin.
        ignoreVersionRequirement = [ "websocket-client" ];
        meta = {
          description = "Eufy Security integration for Home Assistant";
          homepage = "https://github.com/fuatakgun/eufy_security";
          license = final.lib.licenses.mit;
        };
      };
    }
  );

  eufy-security-ws = final.buildNpmPackage {
    pname = "eufy-security-ws";
    version = "3.1.0";
    src = final.fetchFromGitHub {
      owner = "bropat";
      repo = "eufy-security-ws";
      tag = "3.1.0";
      hash = "sha256-xHsq497V0aOpEulAJBeZ+05cH0FhJPAein04TY0DT2o=";
    };
    nodejs = final.nodejs_24;
    npmDepsHash = "sha256-YLsKQRkNxKjNYo+Il0GrRJ6DB1bgodKlNC4u7Qa0diQ=";
    meta = {
      description = "WebSocket bridge for Eufy Security devices";
      homepage = "https://github.com/bropat/eufy-security-ws";
      license = final.lib.licenses.mit;
      mainProgram = "eufy-security-server";
    };
  };
}
