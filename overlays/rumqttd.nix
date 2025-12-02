let
  rumqttd =
    {
      lib,
      stdenv,
      fetchFromGitHub,
      rustPlatform,
      cmake,
    }:
    rustPlatform.buildRustPackage rec {
      pname = "rumqttd";
      version = "0.20.0";

      src = fetchFromGitHub {
        owner = "bytebeamio";
        repo = "rumqtt";
        rev = "rumqttd-${version}";
        hash = "sha256-WFhVSFAp5ZIqranLpU86L7keQaReEUXxxGhvikF+TBw=";
      };

      cargoHash = "sha256-UP1uhG+Ow/jN/B8i//vujP7vpoQ5PjYGCrXs0b1bym4=";

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
