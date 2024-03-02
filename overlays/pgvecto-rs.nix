let
  pgvecto-rs = { lib, stdenv, fetchurl, dpkg, postgresql }:
    let
      versionHashes = {
        "16" = "sha256-aJ1wLNZVdsZAvQeE26YVnJBr8lAm6i6/3eio5H44d7s=";
      };
      major = "16";
    in
    stdenv.mkDerivation rec {
      pname = "pgvecto-rs";
      version = "0.2.0";

      buildInputs = [ dpkg ];

      src = fetchurl {
        url =
          "https://github.com/tensorchord/pgvecto.rs/releases/download/v${version}/vectors-pg${major}_${version}_amd64.deb";
        hash = versionHashes."${major}";
      };

      dontUnpack = true;
      dontBuild = true;
      dontStrip = true;

      installPhase = ''
        mkdir -p $out
        dpkg -x $src $out
        install -D -t $out/lib $out/usr/lib/postgresql/${major}/lib/*.so
        install -D -t $out/share/postgresql/extension $out/usr/share/postgresql/${major}/extension/*.sql
        install -D -t $out/share/postgresql/extension $out/usr/share/postgresql/${major}/extension/*.control
        rm -rf $out/usr
      '';

      meta = with lib; {
        description =
          "pgvecto.rs extension for PostgreSQL: Scalable Vector database plugin for Postgres, written in Rust, specifically designed for LLM";
        homepage = "https://github.com/tensorchord/pgvecto.rs";
      };
    };
in
final: prev: {
  pgvecto-rs = prev.callPackage pgvecto-rs { };
}

