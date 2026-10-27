# Mozkey — the Japanese input method used by the Fcitx 5 profile.
#
# Upstream is Masterisk-F/fcitx-mozkey, a Mozc fork with live conversion and
# local Zenz correction.  It builds with Bazel and resolves its dependencies
# through Bzlmod, so packaging it means:
#
#   * the Bzlmod registry is a pinned Bazel Central Registry checkout, which
#     keeps the module resolution reproducible and offline,
#   * every archive Bazel would download is prefetched by Nix and handed over
#     through --distdir,
#   * MODULE.bazel.lock pins the resolved module graph.
#
# The Bazel build itself therefore never touches the network.
{
  lib,
  stdenv,
  fetchurl,
  runCommand,
  bazel_9,
  pkg-config,
  python3,
  gettext,
  gnutar,
  makeWrapper,
  autoPatchelfHook,
  fcitx5,
  qt6,
  llama-cpp,
  withZenz ? true,
}:

let
  # The upstream checkout.  There is no release tag that contains the Fcitx 5
  # addon yet, so the revision is pinned.
  rev = "c04eb574ec4e4c47df9d92b9bc0136ce0cf958e9";

  # The Bazel Central Registry acts as the Bzlmod registry.
  bcrRev = "4f65d722af1a5be50854622bc663776854cba09d";

  bcr = fetchurl {
    url = "https://github.com/bazelbuild/bazel-central-registry/archive/${bcrRev}.tar.gz";
    hash = "sha256-grTMT2bijS74GuuGKxZPew/1EVVb3M0NmMsBkkO6Zbk=";
  };

  # The archives Bazel downloads while building Mozkey: the Bzlmod modules,
  # the data files mozc pulls in itself and the toolchains the module
  # extensions fetch.  A distdir is keyed by the file name of the URL, so the
  # three material design icons that share a name are not part of it.
  archives = builtins.fromJSON (builtins.readFile ./bazel-archives.json);

  fetchedArchives = map (entry: {
    name = builtins.baseNameOf entry.url;
    path = fetchurl {
      url = entry.url;
      hash = entry.sha256;
      name = builtins.baseNameOf entry.url;
    };
  }) archives;

  distdir = runCommand "fcitx5-mozkey-bazel-distdir" { } ''
    mkdir -p $out
    ${lib.concatMapStrings (archive: ''
      ln -s ${archive.path} $out/${archive.name}
    '') fetchedArchives}
  '';

  # The material design icons are fetched separately: three of them share
  # their file name and the icon archive is assembled by hand anyway.
  materialIcon =
    name: hash:
    fetchurl {
      url = "https://raw.githubusercontent.com/google/material-design-icons/4.0.0/${name}";
      inherit hash;
      name = builtins.replaceStrings [ "/" ] [ "-" ] name;
    };

  materialIcons = {
    dictionarySvg = materialIcon "src/action/chrome_reader_mode/materialiconsoutlined/24px.svg" "sha256-pMe5v7RCp0l7ctdDWMMQNMT+8asqUGWYNHhFgHUawE0=";
    propertiesSvg = materialIcon "src/action/settings/materialiconsround/24px.svg" "sha256-mwGxM74cr/xoDxMtOF0OWUJi1s/Sl1mmPEKAULg/5ig=";
    toolSvg = materialIcon "src/action/build/materialicons/24px.svg" "sha256-3zT7o9CXeNtpUDojtoh2EFHb9ltbzLDXtynGn/YcOAQ=";
    dictionaryPng = materialIcon "png/action/chrome_reader_mode/materialiconsoutlined/48dp/1x/outline_chrome_reader_mode_black_48dp.png" "sha256-bSrHvvoDjU8y4HE2KTrK9dhkWk2uy20GPzS+L/6lm1U=";
    propertiesPng = materialIcon "png/action/settings/materialiconsround/48dp/1x/round_settings_black_48dp.png" "sha256-xK6Lt5kvQxV76dAm92pwOa9uDj3g8iCEIgjf2ow4cUo=";
    toolPng = materialIcon "png/action/build/materialicons/48dp/1x/baseline_build_black_48dp.png" "sha256-JpQzv21pSKk6tqV6c861kwhwIjBGBSz//gHuyjcyfT4=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "fcitx5-mozkey";
  version = "0.7.6";

  src = fetchurl {
    url = "https://github.com/Masterisk-F/fcitx-mozkey/archive/${rev}.tar.gz";
    hash = "sha256-8mjfn9IvPV7lJGhs7aSodFWJW15B7wbZ3nx/G5GqgR0=";
  };

  sourceRoot = "fcitx-mozkey-${rev}";

  # The Qt application (mozc_tool) is wrapped by hand because it lives next
  # to the engine instead of in $out/bin.
  dontWrapQtApps = true;

  nativeBuildInputs = [
    bazel_9
    gettext
    gnutar
    makeWrapper
    pkg-config
    python3
    autoPatchelfHook
  ];

  buildInputs = [
    fcitx5
    qt6.qtbase
  ]
  ++ lib.optionals withZenz [ llama-cpp ];

  patches = [ ./patches/0001-qt6-uic-reject-leading-namespace.patch ];

  postPatch = ''
    # The pinned module graph; upstream does not commit a lock file.
    cp ${./MODULE.bazel.lock} src/MODULE.bazel.lock

    # The addon and the server find each other in a fixed directory, so point
    # it at the package output.
    substituteInPlace src/config.bzl \
      --replace-fail 'LINUX_MOZC_SERVER_DIR = "/usr/lib/mozc"' "LINUX_MOZC_SERVER_DIR = \"''$out/lib/mozc\"" \
      --replace-fail 'LINUX_MOZC_ICONS_DIR = "/usr/share/icons/mozc"' "LINUX_MOZC_ICONS_DIR = \"''$out/share/icons/mozc\""
  '';

  preConfigure = ''
    # The Bazel workspace is the src/ directory of the upstream checkout.
    cd src

    # The pinned Bazel Central Registry is the Bzlmod registry.
    mkdir -p bcr
    ${gnutar}/bin/tar xf ${bcr} --strip-components=1 -C bcr
  '';

  buildPhase = ''
    runHook preBuild

    export bazelOut="$NIX_BUILD_TOP/output"
    export bazelUserRoot="$NIX_BUILD_TOP/tmp"
    export HOME="$NIX_BUILD_TOP"
    export USER=nix
    # Bazel computes its default output user root from $USER, so it has to be
    # set before the server starts.
    export BAZEL_USE_CPP_ONLY_TOOLCHAIN=1

    # Bazel does not pass the nixpkgs compiler flags to the actions it runs,
    # so they have to be handed over explicitly.
    copts=()
    host_copts=()
    linkopts=()
    host_linkopts=()
    for flag in $NIX_CFLAGS_COMPILE; do
      copts+=( "--copt=$flag" )
      host_copts+=( "--host_copt=$flag" )
    done
    for flag in $NIX_CXXSTDLIB_COMPILE; do
      copts+=( "--copt=$flag" )
      host_copts+=( "--host_copt=$flag" )
    done
    for flag in $NIX_LDFLAGS; do
      linkopts+=( "--linkopt=-Wl,$flag" )
      host_linkopts+=( "--host_linkopt=-Wl,$flag" )
    done

    bazel \
      --batch \
      --output_base="$bazelOut" \
      --output_user_root="$bazelUserRoot" \
      build \
      --curses=no \
      "''${copts[@]}" \
      "''${host_copts[@]}" \
      "''${linkopts[@]}" \
      "''${host_linkopts[@]}" \
      --config oss_linux \
      --compilation_mode opt \
      --copt=-fPIC \
      --define server=1 \
      --registry="file://$PWD/bcr" \
      --distdir=${distdir} \
      unix/fcitx5:fcitx5-mozc.so \
      server:mozc_server \
      gui/tool:mozc_tool \
      ${lib.optionalString withZenz "zenz_scorer:mozc_zenz_scorer"}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # The Fcitx 5 addon.
    install -Dm555 bazel-bin/unix/fcitx5/fcitx5-mozc.so \
      $out/lib/fcitx5/fcitx5-mozc.so
    install -Dm444 unix/fcitx5/mozc-addon.conf \
      $out/share/fcitx5/addon/mozc.conf
    install -Dm444 unix/fcitx5/mozc.conf \
      $out/share/fcitx5/inputmethod/mozc.conf

    # The engine and the settings tool.
    install -Dm555 bazel-bin/server/mozc_server $out/lib/mozc/mozc_server
    install -Dm555 bazel-bin/gui/tool/mozc_tool $out/lib/mozc/mozc_tool
    # The tool is a Qt application and lives next to the server, so the Qt
    # plugin path has to be set by hand.
    wrapProgram $out/lib/mozc/mozc_tool \
      --prefix QT_PLUGIN_PATH : ${qt6.qtbase}/${qt6.qtbase.qtPluginPrefix}

    ${lib.optionalString withZenz ''
      # The local Zenz correction runs a llama.cpp server next to the scorer.
      install -Dm555 bazel-bin/zenz_scorer/mozc_zenz_scorer \
        $out/lib/mozc/mozc_zenz_scorer
      ln -s ${llama-cpp}/bin/llama-server $out/lib/mozc/llama-server

      # The published model names a private pre-tokenizer that llama.cpp
      # rejects, so its metadata has to be normalised first.
      mkdir -p $out/lib/mozc/models
      ${python3}/bin/python3 ${./normalize-zenz-gguf.py} \
        win32/installer/zenz_runtime/models/zenz-v3.2-small-Q5_K_M.gguf \
        $out/lib/mozc/models/zenz-v3.2-small-Q5_K_M.gguf
    ''}

    # Translations.
    for pofile in unix/fcitx5/po/*.po; do
      lang=$(basename "$pofile" .po)
      msgfmt "$pofile" -o "$lang.mo"
      install -Dm444 "$lang.mo" \
        "$out/share/locale/$lang/LC_MESSAGES/fcitx5-mozc.mo"
    done

    # Icons.  Upstream packs them with a Python helper that cannot run
    # inside the Bazel sandbox (its interpreter is /usr/bin/env), so they are
    # installed from the source tree instead.
    install -Dm444 data/images/product_icon_32bpp-128.png \
      $out/share/icons/hicolor/128x128/apps/org.fcitx.Fcitx5.fcitx_mozc.png
    ln -s org.fcitx.Fcitx5.fcitx_mozc.png \
      $out/share/icons/hicolor/128x128/apps/fcitx_mozc.png
    install -Dm444 data/images/full_ascii.svg \
      $out/share/icons/hicolor/scalable/apps/fcitx_mozc_alpha_full.svg
    install -Dm444 data/images/full_katakana.svg \
      $out/share/icons/hicolor/scalable/apps/fcitx_mozc_katakana_full.svg
    install -Dm444 data/images/half_ascii.svg \
      $out/share/icons/hicolor/scalable/apps/fcitx_mozc_alpha_half.svg
    install -Dm444 data/images/half_katakana.svg \
      $out/share/icons/hicolor/scalable/apps/fcitx_mozc_katakana_half.svg
    install -Dm444 data/images/hiragana.svg \
      $out/share/icons/hicolor/scalable/apps/fcitx_mozc_hiragana.svg
    install -Dm444 data/images/direct.svg \
      $out/share/icons/hicolor/scalable/apps/fcitx_mozc_direct.svg
    install -Dm444 ${materialIcons.dictionarySvg} \
      $out/share/icons/hicolor/scalable/apps/fcitx_mozc_dictionary.svg
    install -Dm444 ${materialIcons.propertiesSvg} \
      $out/share/icons/hicolor/scalable/apps/fcitx_mozc_properties.svg
    install -Dm444 ${materialIcons.toolSvg} \
      $out/share/icons/hicolor/scalable/apps/fcitx_mozc_tool.svg
    for png in alpha_full alpha_half direct hiragana katakana_full katakana_half; do
      install -Dm444 "data/images/unix/48x48/$png.png" \
        "$out/share/icons/hicolor/48x48/apps/fcitx_mozc_$png.png"
    done
    install -Dm444 ${materialIcons.dictionaryPng} \
      $out/share/icons/hicolor/48x48/apps/fcitx_mozc_dictionary.png
    install -Dm444 ${materialIcons.propertiesPng} \
      $out/share/icons/hicolor/48x48/apps/fcitx_mozc_properties.png
    install -Dm444 ${materialIcons.toolPng} \
      $out/share/icons/hicolor/48x48/apps/fcitx_mozc_tool.png

    runHook postInstall
  '';

  meta = {
    description = "Mozkey, a Japanese input method for Fcitx 5 (Mozc fork with live conversion)";
    homepage = "https://github.com/Masterisk-F/fcitx-mozkey";
    license = with lib.licenses; [
      asl20 # abseil-cpp, the Zenz model
      bsd3 # mozc
      lgpl21Plus # fcitx5
      mit
    ];
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
