{ lib
, fetchFromGitHub
, rustPlatform
, cmake
, llvmPackages
, openssl
, pkg-config
, stdenv
, systemd
, darwin
}:

rustPlatform.buildRustPackage rec {
  pname = "openethereum";
  version = "3.2.6";

  src = fetchFromGitHub {
    owner = "openethereum";
    repo = "openethereum";
    rev = "1a95648cabf5bf6452c7b596a57a3bf5cf1a81c7";
    sha256 = "sha256-Iv4lI+uB0qLUvZm37anEk27o9KYeav1D49EUk4PSd9M=";
  };

  cargoSha256 = "sha256-v3vMo/EXCzmD6yedJm5YAYkgnnkxyYBGIoY4rvTYrKg=";

  nativeBuildInputs = [ cmake pkg-config ];

  buildInputs = [ openssl ]
    ++ lib.optionals stdenv.isLinux [ systemd ]
    ++ lib.optionals stdenv.isDarwin [ darwin.Security ];

  buildFeatures = [ "final" ];

  # Fix tests by preventing them from writing to /homeless-shelter.
  preCheck = ''
    export HOME=$(mktemp -d)
  '';

  # Exclude some tests that don't work in the sandbox
  # - Nat test requires network access
  checkFlags = "--skip configuration::tests::should_resolve_external_nat_hosts";

  meta = with lib; {
    description = "Fast, light, robust Ethereum implementation";
    homepage = "http://parity.io/ethereum";
    license = licenses.gpl3;
    maintainers = with maintainers; [ akru ];
    platforms = lib.platforms.unix;
  };
}
