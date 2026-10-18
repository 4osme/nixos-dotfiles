# sigma-file-manager — repackaged from the upstream .deb release.
#
# v2 is a Tauri (Rust + WebKitGTK) app: the release binary links only
# libwebkit2gtk-4.1 / libgtk-3 / libayatana-appindicator3 (see the deb's
# Depends), so the .deb is repackaged with autoPatchelf against nixpkgs
# instead of building the npm/Cargo workspace from source (a source build can
# replace this later; see the README).
#
# The upstream desktop file has no MimeType and a name with spaces; this
# package renames it to sigma-file-manager.desktop and registers
# inode/directory so it can be the default file manager (home/default.nix).
{
  lib,
  stdenv,
  fetchurl,
  libarchive,
  autoPatchelfHook,
  gtk3,
  libayatana-appindicator,
  webkitgtk_4_1,
  glib,
  gdk-pixbuf,
  cairo,
  dbus,
  libsoup_3,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "sigma-file-manager";
  version = "2.2.0";

  src = fetchurl {
    # Bump the version and this hash together (SHA256SUMS of the release).
    url = "https://github.com/aleksey-hoffman/sigma-file-manager/releases/download/v${finalAttrs.version}/Sigma-File-Manager-${finalAttrs.version}-linux.deb";
    hash = "sha256-MferN/Ry1BmixL2VxJ58x+F5lKSNTj7wIs+lS7PC3/E=";
  };

  nativeBuildInputs = [
    libarchive # bsdtar
    autoPatchelfHook
  ];

  buildInputs = [
    cairo
    dbus
    gdk-pixbuf
    glib
    gtk3
    libayatana-appindicator
    libsoup_3
    webkitgtk_4_1
  ];

  unpackPhase = ''
    runHook preUnpack
    bsdtar -xf "$src"
    bsdtar -xf data.tar.gz
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/applications $out/share/icons
    install -m755 usr/bin/sigma-file-manager $out/bin/sigma-file-manager
    cp -a usr/share/applications/. $out/share/applications/
    cp -a usr/share/icons/. $out/share/icons/

    # Space-free desktop file name so it can be referenced from mimeapps.list,
    # plus the FM category and the inode/directory association upstream omits.
    desktop="$out/share/applications/sigma-file-manager.desktop"
    mv "$out/share/applications/Sigma File Manager.desktop" "$desktop"
    substituteInPlace "$desktop" \
      --replace-fail 'Categories=' 'Categories=System;FileTools;FileManager;' \
      --replace-fail 'Terminal=false' $'Terminal=false\nMimeType=inode/directory;'

    runHook postInstall
  '';

  meta = {
    description = "Modern file manager (Tauri/WebKitGTK; repackaged from the upstream .deb)";
    homepage = "https://github.com/aleksey-hoffman/sigma-file-manager";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "sigma-file-manager";
  };
})
