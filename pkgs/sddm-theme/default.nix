# The login theme: sddm-astronaut-theme (Keyitdev, GPL-3.0) plus the
# hyprtomic overlay of the Fedora image (files/sddm-theme): theme.conf,
# the fingerprint status line (Components/FingerprintStatus.qml) and the
# patched LoginForm.qml, working as share/sddm/themes/hyprtomic.
#
# Reference: files/scripts/install-sddm-theme.sh in fedora-hyprtomic.
{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "sddm-hyprtomic-theme";
  version = "unstable-2026-09-18";

  src = fetchFromGitHub {
    owner = "Keyitdev";
    repo = "sddm-astronaut-theme";
    rev = "abb3163c724935af888ba5ea9ac0c4f22afd8048";
    hash = "sha256-BujSjoQlMH6PZIfn3Ox7hp6JFb2aRGtALOnpAGqqyNE=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    theme=$out/share/sddm/themes/hyprtomic
    mkdir -p "$theme"
    cp -a . "$theme/"

    # The hyprtomic overrides (theme.conf -> Themes/custom.conf and the
    # Components with the fingerprint status line), mirroring
    # install-sddm-theme.sh.
    install -m644 ${../../files/sddm-theme/theme.conf} "$theme/Themes/custom.conf"
    find "$theme" -maxdepth 1 -name 'metadata.desktop' -exec \
      sed -i 's|^ConfigFile=.*|ConfigFile=Themes/custom.conf|' {} \;
    install -m644 ${../../files/sddm-theme/Components/FingerprintStatus.qml} \
      "$theme/Components/FingerprintStatus.qml"
    install -m644 ${../../files/sddm-theme/Components/LoginForm.qml} \
      "$theme/Components/LoginForm.qml"

    # Wallpaper (the source copies the desktop wallpaper into the theme).
    install -m644 ${../../files/home/.local/share/backgrounds/wallpaper.jpg} \
      "$theme/Backgrounds/wallpaper.jpg"

    runHook postInstall
  '';

  meta = {
    description = "SDDM astronaut theme with the hyprtomic fingerprint overlay";
    homepage = "https://github.com/Keyitdev/sddm-astronaut-theme";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
})
