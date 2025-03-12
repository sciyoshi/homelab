final: prev: {
  filebot = prev.filebot.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./filebot-license.patch ];

    postPatch =
      let
        lanterna_3_1_1 = builtins.fetchurl {
          url = "https://search.maven.org/remotecontent?filepath=com/googlecode/lanterna/lanterna/3.1.1/lanterna-3.1.1.jar";
          sha256 = "sha256-7zxCeXYW5v9ritnvkwRpPKdgSptCmkT3HJOaNgQHUmQ=";
        };
      in
      ''
        cp ${lanterna_3_1_1} jar/lanterna.jar
      '';

    installPhase =
      old.installPhase
      + ''
        substituteInPlace $out/opt/.filebot.sh-wrapped \
          --replace '-jar "$FILEBOT_HOME/jar/filebot.jar"' '-Dcom.googlecode.lanterna.terminal.UnixTerminal.sttyCommand=${final.coreutils}/bin/stty  -cp "$FILEBOT_HOME/jar/filebot-license.jar:$FILEBOT_HOME/jar/filebot.jar" "net.filebot.Main"'
      '';
  });
}
