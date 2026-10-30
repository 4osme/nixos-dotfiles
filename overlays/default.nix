# Packages that fedora-hyprtomic built or pinned itself: hyprbind (the
# custom-built keybind viewer), the mozkey IME, the SDDM astronaut theme
# overlay, Google Sans Flex, Vypr and the CS9711 libfprint fork.
final: prev: {
  hyprbind = final.callPackage ../pkgs/hyprbind { };
  hypremoji = final.callPackage ../pkgs/hypremoji { };
  vypr = final.callPackage ../pkgs/vypr { };
  hyprtomic-vypr-scripts = final.callPackage ../pkgs/vypr/scripts.nix { };
  fcitx5-mozkey = final.callPackage ../pkgs/mozkey { };
  sddm-hyprtomic-theme = final.callPackage ../pkgs/sddm-theme { };
  google-sans-flex = final.callPackage ../pkgs/google-sans-flex { };
  libfprint-cs9711 = final.callPackage ../pkgs/libfprint-cs9711 { };
  moonlight-web-stream = final.callPackage ../pkgs/moonlight-web-stream { };

  # nixpkgs 26.05's tela-circle-icon-theme ships a few dangling XSI alias
  # symlinks and the fixup check rejects the build (so it is not on
  # cache.nixos.org either). The aliases are cosmetic; skip the check.
  tela-circle-icon-theme = prev.tela-circle-icon-theme.overrideAttrs (_: {
    dontCheckForBrokenSymlinks = true;
  });

  # Sunshine with JIS keyboard support — vendored from the sunshine-nix tree
  # (../sunshine-nix → pkgs/sunshine/, see the license notes there). Upstream
  # has not merged the JIS PRs yet, so the patches apply on top of the nixpkgs
  # version (2026.914.233613); rebase 0003 against the new submodule pin when
  # nixpkgs bumps Sunshine.
  sunshine = prev.sunshine.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ../pkgs/sunshine/patches/0001-sunshine-non-normalized-key-flag.patch
      ../pkgs/sunshine/patches/0002-sunshine-wayland-retry.patch
    ];
    postPatch = (old.postPatch or "") + ''
      patch -d third-party/libvirtualhid -p1 < ${../pkgs/sunshine/patches/0003-libvirtualhid-jis-keyboard-mapping.patch}
    '';
  });
}
