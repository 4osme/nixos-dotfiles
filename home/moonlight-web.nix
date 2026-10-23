# moonlight-web-stream as a manual user service (main-desktop only, imported
# conditionally from home/default.nix). It is intentionally not enabled at
# login: start it with `systemctl --user start moonlight-web-stream`.
#
# The web server resolves `static/` and `server/{config,data}.json` relative
# to its working directory. The state directory holds the writable data and a
# symlink to the immutable frontend shipped by the package.
{ pkgs, ... }:
{
  systemd.user.services.moonlight-web-stream = {
    Unit = {
      Description = "moonlight-web-stream (manual start)";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      StateDirectory = "moonlight-web-stream";
      WorkingDirectory = "%S/moonlight-web-stream";
      ExecStartPre = "${pkgs.coreutils}/bin/ln -sfn ${pkgs.moonlight-web-stream}/share/moonlight-web-stream/static %S/moonlight-web-stream/static";
      ExecStart = "${pkgs.moonlight-web-stream}/bin/web-server";
      Restart = "on-failure";
      RestartSec = 5;
    };
    # No Install section: `systemctl --user start moonlight-web-stream`.
  };
}
