nix-ai-tools: final: prev: {
  # Follow upstream's package, adding only the macOS Finder bundle.
  herdr-app = nix-ai-tools.packages.${prev.stdenv.hostPlatform.system}.herdr-app.overrideAttrs (
    finalAttrs: prevAttrs: {
      # Upstream installs the executable on macOS but omits the Finder bundle.
      # Reuse the bundle metadata and icon from its own installer.
      postInstall =
        (prevAttrs.postInstall or "")
        + prev.lib.optionalString prev.stdenv.hostPlatform.isDarwin ''
          app="$out/Applications/Herdr.app"
          mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
          cp assets/icons/Herdr.icns "$app/Contents/Resources/Herdr.icns"
          sed -n '/^<?xml/,/^PLIST/{ /^PLIST/d; p; }' scripts/install-macos > "$app/Contents/Info.plist"
          substituteInPlace "$app/Contents/Info.plist" \
            --replace-fail '<string>0.0.1</string>' '<string>${finalAttrs.version}</string>'
          makeWrapper "$out/bin/herdr-app" "$app/Contents/MacOS/Herdr"
        '';
    }
  );
}
