# The quickshell launcher resolves application icons with its own GTK icon
# resolver (~/.config/quickshell/ii/scripts/resolve-icons.py). nixpkgs python3
# has no pygobject, so wrap it with the right environment; the launcher calls
# `resolve-icons` instead of `python3 <script>`.
{
  python3,
  gtk3,
  glib,
  writeShellApplication,
}:
let
  python = python3.withPackages (ps: [ ps.pygobject3 ]);
in
writeShellApplication {
  name = "resolve-icons";
  runtimeInputs = [ python ];
  text = ''
    export GI_TYPELIB_PATH=${gtk3}/lib/girepository-1.0:${glib}/lib/girepository-1.0''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}
    exec python3 "$@"
  '';
}
