# Google Sans Flex — not packaged for Nix; the Fedora GUI container extracted
# the font from the pinned COPR RPM (gui-04-fonts.sh). Same artifact, same
# sha256 as that script.
{
  lib,
  stdenv,
  fetchurl,
  libarchive,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "google-sans-flex";
  version = "20251118";

  src = fetchurl {
    url = "https://download.copr.fedorainfracloud.org/results/ririko66z/dots-hyprland/fedora-44-x86_64/09820466-google-sans-flex-vf-fonts/google-sans-flex-vf-fonts-20251118^1.git251aa5a-1.fc44.noarch.rpm";
    hash = "sha256-3XR2uq1FK0NdnJ92SVdi7tGVLKYaU79kE0Cvt0sgCKY=";
  };

  nativeBuildInputs = [ libarchive ];

  unpackPhase = ''
    runHook preUnpack
    bsdtar -xf "$src"
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts
    cp -a usr/share/fonts/. $out/share/fonts/
    if [ -d usr/share/licenses ]; then
      mkdir -p $out/share/licenses/google-sans-flex
      cp -a usr/share/licenses/. $out/share/licenses/google-sans-flex/ || true
    fi
    runHook postInstall
  '';

  meta = {
    description = "Google Sans Flex variable font (from the dots-hyprland COPR RPM)";
    homepage = "https://github.com/ririko66z/";
    license = lib.licenses.ofl;
    platforms = lib.platforms.linux;
  };
})
