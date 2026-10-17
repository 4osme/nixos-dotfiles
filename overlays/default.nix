# Packages that fedora-hyprtomic built or pinned itself: hyprbind (= the
# custom-built keybind viewer), the quickshell pipewire patch, the mozkey IME,
# the SDDM astronaut theme overlay, Google Sans Flex, Vypr and the CS9711
# libfprint fork.
final: prev: {
  hyprbind = final.callPackage ../pkgs/hyprbind { };
  hypremoji = final.callPackage ../pkgs/hypremoji { };
  vypr = final.callPackage ../pkgs/vypr { };
  hyprtomic-vypr-scripts = final.callPackage ../pkgs/vypr/scripts.nix { };
  fcitx5-mozkey-ibg = final.callPackage ../pkgs/mozkey { };
  sddm-hyprtomic-theme = final.callPackage ../pkgs/sddm-theme { };
  google-sans-flex = final.callPackage ../pkgs/google-sans-flex { };
  libfprint-cs9711 = final.callPackage ../pkgs/libfprint-cs9711 { };
  resolve-icons = final.callPackage ../pkgs/resolve-icons { };

  # fedora-hyprtomic carries a quickshell fix for a SIGSEGV when the default
  # PipeWire sink is destroyed (files/system/patches/, from
  # files/gui-build/patches/ in the source repo). Apply it only while the
  # upstream fix is absent; if the anchors moved, fail loudly like
  # gui-02-quickshell.sh does.
  quickshell = prev.quickshell.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      if grep -q 'delete this;' src/services/pipewire/qml.cpp 2>/dev/null \
         && grep -q 'this->deleteLater();' src/services/pipewire/qml.cpp 2>/dev/null; then
        echo "quickshell: pipewire defer-destroy patch already applied upstream - skipping"
      elif grep -q 'delete this;' src/services/pipewire/qml.cpp 2>/dev/null; then
        echo "quickshell: applying pipewire defer-destroy patch"
        patch -p1 -F3 < ${../files/system/patches/quickshell-pipewire-defer-destroy.patch}
      fi
    '';
  });
}
