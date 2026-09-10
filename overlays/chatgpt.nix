let
  chatgpt =
    {
      lib,
      stdenvNoCC,
      stdenv,
      fetchurl,
      dpkg,
      autoPatchelfHook,
      makeWrapper,
      wrapGAppsHook3,
      alsa-lib,
      at-spi2-atk,
      at-spi2-core,
      atk,
      cairo,
      cups,
      dbus,
      expat,
      gdk-pixbuf,
      glib,
      gtk3,
      libgbm,
      libdrm,
      libxkbcommon,
      nspr,
      nss,
      pango,
      systemdLibs,
      libx11,
      libxcb,
      libxcomposite,
      libxdamage,
      libxext,
      libxfixes,
      libxrandr,
      libusb1,
      qt5,
      qt6,
      libGL,
      vulkan-loader,
      libsecret,
      libnotify,
      libpulseaudio,
      pipewire,
      coreutils,
      xdg-utils,
    }:
    stdenvNoCC.mkDerivation (finalAttrs: {
      pname = "chatgpt";
      version = "26.903.71938";
      # Pin a versioned package; /latest/ changes independently of this hash.
      # Update from linux/deb/dists/stable/main/binary-amd64/Packages on the same host.
      src = fetchurl {
        url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${finalAttrs.version}_amd64.deb";
        hash = "sha256-E/Rt9zsG324T6edQsvPImphYY3QeqCXS01b1JVn1Wr0=";
      };
      nativeBuildInputs = [
        dpkg
        autoPatchelfHook
        makeWrapper
        wrapGAppsHook3
      ];
      buildInputs = [
        stdenv.cc.cc.lib
        alsa-lib
        at-spi2-atk
        at-spi2-core
        atk
        cairo
        cups
        dbus
        expat
        gdk-pixbuf
        glib
        gtk3
        libgbm
        libdrm
        libxkbcommon
        nspr
        nss
        pango
        systemdLibs
        libx11
        libxcb
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxrandr
        libusb1
        # Library outputs avoid loading conflicting Qt5/Qt6 development hooks.
        (lib.getLib qt5.qtbase)
        (lib.getLib qt6.qtbase)
      ];
      runtimeDependencies = [
        libGL
        vulkan-loader
        libsecret
        libnotify
        libpulseaudio
        pipewire
      ];
      dontBuild = true;
      dontConfigure = true;
      # Preserve the vendor Owl runtime and matching native modules.
      dontStrip = true;
      dontWrapGApps = true;
      unpackPhase = ''
        runHook preUnpack
        dpkg-deb --fsys-tarfile "$src" | tar -x --no-same-owner --no-same-permissions
        runHook postUnpack
      '';
      installPhase = ''
        runHook preInstall

        mkdir -p "$out/lib" "$out/bin"
        cp -a usr/lib/chatgpt "$out/lib/chatgpt"
        cp -a usr/share "$out/share"
        # Alternate musl prebuilds are unused on the glibc host.
        find "$out/lib/chatgpt" -type f \( -name '*musl*.node' -o -path '*-musl/*.node' \) -delete
        patchShebangs "$out/lib/chatgpt/codex-launcher" "$out/lib/chatgpt/resources/cua_node/bin"
        substituteInPlace "$out/share/applications/chatgpt.desktop" --replace-fail 'Exec=chatgpt ' "Exec=$out/bin/chatgpt "

        runHook postInstall
      '';
      preFixup = ''
        addAutoPatchelfSearchPath "$out/lib/chatgpt"
        makeWrapper "$out/lib/chatgpt/ChatGPT" "$out/bin/chatgpt" \
          "''${gappsWrapperArgs[@]}" \
          --suffix PATH : ${
            lib.makeBinPath [
              coreutils
              xdg-utils
            ]
          }
      '';
      meta = {
        description = "Official ChatGPT desktop app for Linux";
        homepage = "https://learn.chatgpt.com/docs/linux/linux-app";
        license = lib.licenses.unfree;
        platforms = [ "x86_64-linux" ];
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
        mainProgram = "chatgpt";
      };
    });
in
final: prev: {
  chatgpt = final.callPackage chatgpt { };
}
