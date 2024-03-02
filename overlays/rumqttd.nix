let
  rumqttd = { lib, stdenv, fetchFromGitHub, rustPlatform, cmake }:
    rustPlatform.buildRustPackage rec {
      pname = "rumqtt";
      version = "0.19.0";

      src = fetchFromGitHub {
        owner = "bytebeamio";
        repo = "rumqtt";
        rev = "rumqttd-${version}";
        hash = "sha256-3rDnJ1VsyGBDhjOq0Rd55WI1EbIo+17tcFZCoeJB3Kc=";
      };

      cargoHash = "sha256-a6HVcaL6OKIK0h3yuUFDlPASNRciOdW09uXoewld4F8=";

      nativeBuildInputs = [ cmake ];

      meta = with lib; {
        description = "The MQTT ecosystem in rust";
        homepage = "https://github.com/bytebeamio/rumqtt";
        license = licenses.asl20;
      };
    };
in
final: prev: {
  rumqttd = prev.callPackage rumqttd { };
}

