# Vypr v0.5.0 (Amzi-01/Vypr) — Windows VM applications as native windows.
# Built from source with the same four anchor-asserted patches as
# fedora-hyprtomic's files/scripts/vypr-build.sh (see patches/apply.py).
{
  lib,
  stdenv,
  cmake,
  ninja,
  fetchFromGitHub,
  fetchurl,
  makeWrapper,
  python3,
  sdl3,
  vulkan-headers,
  vulkan-loader,
  libGL,
  libvirt,
  openssh,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "vypr";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "Amzi-01";
    repo = "Vypr";
    rev = "v${finalAttrs.version}";
    hash = "sha256-5eI6VcILWez0Z6QmNoydd8a8UREZ2BJqrWF5mA8QRhk=";
  };

  # The guest-side installer must be the release asset of the same tag: the
  # protocol versions on both halves have to match (pinned sha256 from
  # vypr-build.sh; bump the version and this hash together).
  vyprSetupExe = fetchurl {
    url = "https://github.com/Amzi-01/Vypr/releases/download/v${finalAttrs.version}/vypr-setup.exe";
    hash = "sha256-6/eDy2dvQAoBgo/bazJ0teoGp1hg9LFZZ5UlfkQh70c=";
  };

  # The build lives in host/ (the top-level CMakeLists is not the app); drive
  # cmake directly like the upstream instructions instead of the cmakeDir
  # hook.
  dontUseCmakeConfigure = true;
  configurePhase = ''
    runHook preConfigure
    cmake -S host -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
    runHook postConfigure
  '';
  buildPhase = ''
    runHook preBuild
    cmake --build build
    runHook postBuild
  '';
  nativeBuildInputs = [
    cmake
    ninja
    makeWrapper
    python3 # the anchor-asserted patch script below
  ];
  buildInputs = [
    sdl3
    vulkan-headers
    vulkan-loader
  ];

  # The patches are applied by the same python patcher the Fedora build uses.
  postPatch = ''
    python3 ${./patches/apply.py} launcher/vypr host/src/main.c
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 build/vyprd $out/bin/vyprd
    install -Dm755 build/vypr-window $out/bin/vypr-window
    install -Dm755 launcher/vypr $out/bin/vypr
    install -Dm755 launcher/vypr-gpu-swap $out/bin/vypr-gpu-swap
    install -Dm755 install/anti-detect.py $out/share/vypr/anti-detect.py
    install -Dm755 install/hooks/vypr-gpu $out/share/vypr/hooks/vypr-gpu
    install -Dm644 install/xorg/20-vypr-gpu-swap.conf $out/share/vypr/xorg/20-vypr-gpu-swap.conf
    install -Dm644 LICENSE $out/share/licenses/vypr/LICENSE
    install -Dm644 launcher/vypr.png $out/share/icons/hicolor/256x256/apps/vypr.png
    install -Dm644 ${finalAttrs.vyprSetupExe} $out/share/vypr/vypr-setup.exe

    runHook postInstall
  '';

  # The launcher shells out to virsh/ssh/scp/ssh-keygen/python3; the window
  # needs the Vulkan loader at runtime (dlopen).
  postFixup = ''
    for bin in vypr vypr-gpu-swap; do
      wrapProgram $out/bin/$bin \
        --prefix PATH : ${
          lib.makeBinPath [
            libvirt
            openssh
            python3
          ]
        } \
        --prefix LD_LIBRARY_PATH : ${
          lib.makeLibraryPath [
            vulkan-loader
            libGL
          ]
        }
    done
    wrapProgram $out/bin/vypr-window \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          vulkan-loader
          libGL
        ]
      }
  '';

  meta = {
    description = "Show applications from a Windows VM as native Linux windows";
    homepage = "https://github.com/Amzi-01/Vypr";
    license = lib.licenses.unlicense;
    platforms = lib.platforms.linux;
    mainProgram = "vypr";
  };
})
