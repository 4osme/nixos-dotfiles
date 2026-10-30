# SDDM with the hyprtomic login theme (the astronaut theme + the fingerprint
# status line from the Fedora image) and the password-first / fingerprint-on-
# empty-submit PAM stack (pam-fingerprint-gate, same as the source install).
{
  pkgs,
  config,
  lib,
  ...
}:
let
  gate = pkgs.writeShellScript "pam-fingerprint-gate" (
    builtins.readFile ../../files/system/pam.d/pam-fingerprint-gate
  );
  pam = config.security.pam.package;
  fprintd = pkgs.fprintd;
in
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    autoNumlock = true;
    theme = "${pkgs.sddm-hyprtomic-theme}/share/sddm/themes/hyprtomic";
    # QML deps of the astronaut theme (the Fedora recipe installed the same
    # set on the host for this theme).
    extraPackages = with pkgs.qt6; [
      qt5compat
      qtdeclarative
      qtmultimedia
      qtsvg
      qtvirtualkeyboard
    ];
  };

  # The Hyprland session from programs.hyprland; with UWSM the Dux Shell
  # launcher can spawn apps through `uwsm app` like the source install.
  services.displayManager.defaultSession = "hyprland-uwsm";

  security.pam.services.sddm.text = ''
    # HyprTomic: password first, fingerprint only when the password field was
    # submitted empty (pam-fingerprint-gate + pam_exec expose_authtok), like
    # /etc/pam.d/sddm on fedora-hyprtomic.
    auth     [success=1 default=ignore] ${pam}/lib/security/pam_exec.so quiet quiet_log expose_authtok ${gate}
    auth     [success=1 default=ignore] ${fprintd}/lib/security/pam_fprintd.so timeout=10 max-tries=2
    auth     required  ${pam}/lib/security/pam_unix.so try_first_pass
    auth     optional  ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so

    account  include login
    password include login
    session  include login
    session  optional ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so auto_start
  '';

  # Bound the reader on the lock screen the same way (native hyprlock
  # fingerprint stays off in hyprlock.conf; both must never claim the reader
  # at once).
  programs.hyprlock.enable = true;
  security.pam.services.hyprlock.text = ''
    # HyprTomic: empty submit opens one bounded fingerprint window (10s,
    # single try), a typed password skips the reader entirely.
    auth     [success=1 default=ignore] ${pam}/lib/security/pam_exec.so quiet quiet_log expose_authtok ${gate}
    auth     [success=done default=ignore] ${fprintd}/lib/security/pam_fprintd.so timeout=10 max-tries=1
    auth     required  ${pam}/lib/security/pam_unix.so
  '';

  # Enroll with `fprintd-enroll`; the CS9711 fork for main-desktop is
  # provided by the environment module (overlay on pkgs.libfprint).
  services.fprintd.enable = true;
}
