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

      # No newer rumqttd release exists yet. The rumqttc-0.25.1 repository tag
      # still contains rumqttd 0.20.0, but with a Cargo.lock that builds on
      # newer Rust toolchains.
      srcTag = "rumqttc-0.25.1";

      src = fetchFromGitHub {
        owner = "bytebeamio";
        repo = "rumqtt";
        rev = srcTag;
        hash = "sha256-D/MzUu3WzmPADW4ntmECvT4ZM4ecbs761gXNNvS2UD4=";
      };

      cargoHash = "sha256-b44xU7dhjfYNaEYHEbaDRhW31Z98fEJ7/W6B1ff1Y/s=";
      buildAndTestSubdir = "rumqttd";

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
