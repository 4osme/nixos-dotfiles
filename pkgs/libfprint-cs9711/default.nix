# libfprint with the out-of-tree CS9711 driver (archeYR/libfprint-CS9711,
# the maintained fork of ddlsmurf/libfprint-CS9711). The Fedora host used the
# cwt/libfprint-cs9711 COPR; main-desktop swaps pkgs.libfprint for this so
# fprintd picks it up. The 1500ms reset-retry patch is the one the Fedora
# packaging also applied (better recognition on this sensor class).
{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  gobject-introspection,
  doctest,
  glib,
  gusb,
  libgudev,
  opencv4,
  openssl,
  pixman,
  udev,
  python3,
}:
stdenv.mkDerivation rec {
  pname = "libfprint-cs9711";
  version = "1.94.10";

  src = fetchFromGitHub {
    owner = "archeYR";
    repo = "libfprint-CS9711";
    rev = "02b285c9703c38d308fbe47a3c566ef1e7f883ca";
    hash = "sha256-QGrBNqbRNqLZIURI66xkenlQamNW+DQU4WS+CLN4zM8=";
  };

  patches = [ ./cs9711-retry-delay-1500ms.patch ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    gobject-introspection
    python3
  ];

  buildInputs = [
    doctest # sigfm (header-only dependency of the fork's matcher)
    glib
    gusb
    libgudev # udev/GUDev for the elanspi driver (SPI support defaults on)
    opencv4 # sigfm (the CS9711 feature matcher)
    openssl # required by the default driver set (uru4000)
    pixman # required by the default driver set (aes3k)
    udev
  ];

  mesonFlags = [
    "-Dintrospection=false"
    "-Ddoc=false"
    "-Dgtk-examples=false"
    # The upstream rules install into the udev package's read-only store path;
    # the rules only add autosuspend hints, so skip them (the driver itself
    # talks to the USB device through libgusb and works without them).
    "-Dudev_rules=disabled"
    "-Dudev_hwdb=disabled"
  ];

  # libfprint-2 is the pkg-config / library name fprintd links against.
  meta = {
    description = "libfprint with the CS9711 driver (Chipsailing fingerprint readers)";
    homepage = "https://github.com/archeYR/libfprint-CS9711";
    license = lib.licenses.lgpl21Plus;
    platforms = lib.platforms.linux;
  };
}
