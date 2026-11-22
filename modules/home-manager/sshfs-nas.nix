# User-space automount: afuse owns ~/mnt, SSHFS is only started on access
# to ~/mnt/server. Distribute SSH config, but never keys or known_hosts.
{ pkgs, ... }:
let
  mount = pkgs.writeShellScript "sshfs-nas-mount" ''
    set -eu
    # Never turn arbitrary directory names into SSH destinations.
    [ "$#" -eq 2 ] && [ "$1" = server ] || exit 1

    for attempt in 1 2 3; do
      echo "sshfs-nas: connection attempt $attempt/3" >&2
      if ${pkgs.sshfs}/bin/sshfs sshfs:/mnt "$2" \
        -o ssh_command=${pkgs.openssh}/bin/ssh \
        -o BatchMode=yes,StrictHostKeyChecking=yes,ConnectTimeout=5,ConnectionAttempts=1 \
        -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 \
        -o auto_cache,compression=no,Ciphers=aes128-gcm@openssh.com,max_conns=4 \
        -o dir_cache=yes,dcache_timeout=60,idmap=user,default_permissions; then
        exit 0
      fi
      if [ "$attempt" -lt 3 ]; then
        ${pkgs.coreutils}/bin/sleep 5
      fi
    done
    echo "sshfs-nas: connection failed; access the directory again to retry" >&2
    exit 1
  '';

  populate = pkgs.writeShellScript "sshfs-nas-populate" ''
    printf '%s\n' server
  '';

  start = pkgs.writeShellScript "sshfs-nas-start" ''
    set -eu
    # FUSE needs the host's setuid helpers, not their unprivileged store copies.
    export PATH="/run/wrappers/bin:${pkgs.coreutils}/bin"
    ${pkgs.coreutils}/bin/mkdir -p "$HOME/mnt" "$XDG_RUNTIME_DIR/sshfs-nas"
    # Templates are interpreted by afuse, not systemd (%r/%m stay literal).
    exec ${pkgs.afuse}/bin/afuse -f \
      -o "mount_template=${mount} %r %m" \
      -o "unmount_template=/run/wrappers/bin/fusermount3 -u -z %m" \
      -o "populate_root_command=${populate}" \
      -o "mount_dir=$XDG_RUNTIME_DIR/sshfs-nas" \
      "$HOME/mnt"
  '';

  cleanup = pkgs.writeShellScript "sshfs-nas-cleanup" ''
    # Also recover mounts left behind if afuse crashed. Never recursively
    # delete anything: rmdir only succeeds for an empty, unmounted directory.
    /run/wrappers/bin/fusermount3 -u -z "$HOME/mnt" || true
    for dir in "$XDG_RUNTIME_DIR"/sshfs-nas/afuse-*; do
      [ -d "$dir" ] || continue
      /run/wrappers/bin/fusermount3 -u -z "$dir/server" || true
      ${pkgs.coreutils}/bin/rmdir "$dir/server" "$dir" 2>/dev/null || true
    done
    ${pkgs.coreutils}/bin/rmdir "$XDG_RUNTIME_DIR/sshfs-nas" 2>/dev/null || true
  '';
in
{
  # Only the path to the manually provisioned key goes into the Nix store.
  home.file.".ssh/config".text = ''
    Host sshfs
        HostName 172.16.50.2
        User sshfs
        IdentityFile ~/.ssh/sshfs
        IdentitiesOnly yes
  '';

  systemd.user.services.sshfs-nas = {
    Unit = {
      Description = "On-demand SSHFS NAS (sshfs:/mnt)";
      StartLimitIntervalSec = 0;
    };
    Service = {
      Type = "simple";
      ExecStart = start;
      # Unmounting afuse triggers its normal submount cleanup.
      ExecStop = "-/run/wrappers/bin/fusermount3 -u -z %h/mnt";
      ExecStopPost = cleanup;
      KillMode = "mixed";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStopSec = 20;
      UMask = "0077";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
