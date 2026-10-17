# mozkey IbG (the Japanese IME engine in ~/.config/fcitx5/profile).
#
# The project builds with Bazel and bundles the Zenz runtime (llama.cpp +
# a GGUF model), so rebuilding from source is out of scope for a nixpkgs
# packaging; this pins the upstream prebuilt Arch Linux release (the same
# artifact the AUR's mozkey-ibg-bin uses) and re-points its dynamic
# dependencies at the nixpkgs fcitx5.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  fcitx5,
  qt6,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "fcitx5-mozkey-ibg";
  version = "0.10.4";

  src = fetchurl {
    # Bump the version above and this hash together (SHA256SUMS of the
    # v<version> release of kazormia296/mozkey-ibg, the maintained fork of
    # Masterisk-F/fcitx-mozkey).
    url = "https://github.com/kazormia296/mozkey-ibg/releases/download/v${finalAttrs.version}/mozkey-ibg-v${finalAttrs.version}-archlinux-x86_64.tar.xz";
    hash = "sha256-M7jwGSfDX1Ev1Ki9ykwjFl9lMnZvIeBYBnPcZnnvlY8=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    fcitx5
    qt6.qtbase # mozc_tool (the bundled Qt GUI tool) links Qt6Core/Gui/Widgets
  ];

  # fcitx5 addon + bundled helper binaries: nothing needs the Qt plugin
  # wrapper (autoPatchelf fixes the RPATHs); mozc_tool's GUI is auxiliary.
  dontWrapQtApps = true;

  # Only x86_64: the upstream release is Arch-only (the addon links the
  # fcitx5 sonames and autoPatchelf fixes the RPATH against nixpkgs fcitx5).
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    # The archive's top-level directory is usr/, which stdenv picks as the
    # source root, so the payload is the current directory.
    cp -a . $out/
    runHook postInstall
  '';

  meta = {
    description = "Mozkey IbG Japanese input method for Fcitx 5 (prebuilt upstream release)";
    homepage = "https://github.com/kazormia296/mozkey-ibg";
    license = with lib.licenses; [
      asl20
      bsd3
      lgpl21Plus
      mit
    ];
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
