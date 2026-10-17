#!/usr/bin/env python3
"""Apply a temporary Hyprland streaming profile; reload normal settings on exit.

Profiles (selected by Sunshine's app preparation commands):
  1080p  - force the streamed output to 1920x1080@30, disable other outputs,
           use the dwindle layout while streaming
  native - keep the current resolution, disable the other outputs
Both profiles pin the streamed output to the origin so Sunshine's absolute
mouse mapping stays exact even when its Wayland layout query fails.
"""
import argparse
import contextlib
import fcntl
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

RUNTIME = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
DIRECTORY = RUNTIME / "sunshine-hypr-display"
STATE = DIRECTORY / "state.json"
ACTIVE_1080P = DIRECTORY / "1080p.active"
ACTIVE_NATIVE = DIRECTORY / "native.active"
MODE = re.compile(r"^(\d+)x(\d+)@(\d+(?:\.\d+)?)(?:Hz)?$")
LOG = Path.home() / ".config/sunshine/sunshine.log"


def active_marker(state):
    return ACTIVE_NATIVE if state.get("profile") == "native" else ACTIVE_1080P


def update_connection(state):
    """Prep undo is app-scoped; Pause disconnects without ending the app."""
    if not LOG.exists():
        return
    stat = LOG.stat()
    offset = state.get("log_offset", max(0, stat.st_size - 262144))
    if state.get("log_inode", stat.st_ino) != stat.st_ino or offset > stat.st_size:
        offset = 0
    with LOG.open("rb") as file:
        file.seek(offset)
        data = file.read()
        # Leave partial lines for the next poll so events are not lost.
        complete = data.rfind(b"\n") + 1
        state["log_offset"] = offset + complete
    state["log_inode"] = stat.st_ino
    for line in data[:complete].decode(errors="replace").splitlines():
        if "CLIENT DISCONNECTED" in line:
            state["connected"] = False
        elif "CLIENT CONNECTED" in line:
            state["connected"] = True
        elif "Executing [Desktop Native]" in line:
            state["active"] = False


def log(message):
    print(f"sunshine-hypr-display: {message}", file=sys.stderr, flush=True)


@contextlib.contextmanager
def locked():
    DIRECTORY.mkdir(mode=0o700, parents=True, exist_ok=True)
    with (DIRECTORY / "state.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        yield


def load():
    return json.loads(STATE.read_text()) if STATE.exists() else None


def save(state):
    temporary = DIRECTORY / "state.tmp"
    temporary.write_text(json.dumps(state))
    temporary.chmod(0o600)
    temporary.replace(STATE)


def run(*args, env=None):
    return subprocess.check_output(args, env=env, text=True, stderr=subprocess.PIPE, timeout=5)


def instance_env(signature=None):
    # Before login, the user runtime/Hyprland instance may not exist at all.
    # This is expected at SDDM and must not fail Sunshine's preparation hook.
    try:
        instances = json.loads(run("hyprctl", "instances", "-j"))
    except (subprocess.SubprocessError, json.JSONDecodeError, FileNotFoundError):
        return None
    if signature:
        instances = [item for item in instances if item["instance"] == signature]
    if len(instances) != 1:
        return None
    env = dict(os.environ, XDG_RUNTIME_DIR=str(RUNTIME))
    env["HYPRLAND_INSTANCE_SIGNATURE"] = instances[0]["instance"]
    return env


def select_mode(monitor, width, height, fps):
    rates = []
    for mode in monitor.get("availableModes", []):
        match = MODE.fullmatch(mode)
        if match and (int(match[1]), int(match[2])) == (width, height):
            rates.append(float(match[3]))
    if not rates:
        raise ValueError(f"{monitor['name']} does not support {width}x{height}")
    # Prefer the requested refresh rate; if unavailable use the nearest rate
    # at least as high as the stream FPS (or the highest available rate).
    higher = [rate for rate in rates if rate >= fps - 0.02]
    rate = min(higher, key=lambda value: abs(value - fps)) if higher else max(rates)
    return f"{width}x{height}@{rate:.5f}"


def restore(state, env):
    ACTIVE_1080P.unlink(missing_ok=True)
    ACTIVE_NATIVE.unlink(missing_ok=True)
    if env:
        run("hyprctl", "reload", env=env)
        log("reloaded normal Hyprland configuration")


def reconcile(signature=None):
    with locked():
        state = load()
        if not state:
            return
        update_connection(state)
        save(state)
        env = instance_env(signature)
        if not env:
            return  # SDDM: defer until the user starts Hyprland.
        owner = state.get("sunshine_pid")
        if not state["active"] or (owner and not Path(f"/proc/{owner}").exists()):
            restore(state, env)
            STATE.unlink(missing_ok=True)
            return
        if state.get("connected") is False:
            if active_marker(state).exists():
                restore(state, env)
                state.pop("instance", None)
                save(state)
                log("stream paused/disconnected; normal settings restored")
            return
        signature = env["HYPRLAND_INSTANCE_SIGNATURE"]
        marker = active_marker(state)
        if state.get("instance") == signature and marker.exists():
            return
        monitors = json.loads(run("hyprctl", "monitors", "-j", env=env))
        monitor = next((item for item in monitors if item["name"] == state["output"]), None)
        if not monitor:
            raise ValueError(f"output {state['output']} is not active")
        profile = state.get("profile", "1080p")
        if profile == "1080p":
            mode = select_mode(monitor, 1920, 1080, 30)
            if abs(float(MODE.fullmatch(mode)[3]) - 30) > 0.03:
                raise ValueError("DP-1 does not support the fixed 1080p30 profile")
        state["instance"] = signature
        save(state)
        ACTIVE_1080P.unlink(missing_ok=True)
        ACTIVE_NATIVE.unlink(missing_ok=True)
        marker.touch(mode=0o600)
        run("hyprctl", "reload", env=env)
        if profile == "native":
            log("applied native (sub-monitor disabled) streaming profile")
        else:
            log("applied 1080p30 / dwindle streaming profile")


def start(profile="1080p"):
    width, height, fps = 1920, 1080, 30
    if min(width, height, fps) <= 0:
        raise ValueError("invalid client dimensions or FPS")
    config = Path.home() / ".config/sunshine/sunshine.conf"
    output = "DP-1"
    for line in config.read_text().splitlines():
        if line.strip().startswith("output_name") and "=" in line:
            output = line.split("=", 1)[1].strip()
    if not output:
        raise ValueError("set Sunshine output_name to an explicit Hyprland output")
    try:
        pid = int(run("systemctl", "show", "sunshine", "-p", "MainPID", "--value").strip())
    except (ValueError, subprocess.SubprocessError):
        pid = 0
    with locked():
        state = load() or {}
        state.update(active=True, width=width, height=height, fps=fps,
                     output=output, sunshine_pid=pid, connected=None,
                     profile=profile)
        if LOG.exists():
            stat = LOG.stat()
            state.update(log_offset=stat.st_size, log_inode=stat.st_ino)
        state.pop("instance", None)
        save(state)
        ACTIVE_1080P.unlink(missing_ok=True)
        ACTIVE_NATIVE.unlink(missing_ok=True)
        active_marker(state).touch(mode=0o600)
    try:
        reconcile()
    except Exception:
        stop()  # Fail the preparation command instead of leaving a stale request.
        raise


def stop():
    with locked():
        state = load()
        if not state:
            return
        state["active"] = False
        save(state)
        ACTIVE_1080P.unlink(missing_ok=True)
        ACTIVE_NATIVE.unlink(missing_ok=True)
    reconcile()


def watch():
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not signature:
        raise ValueError("watch must be launched by Hyprland")
    DIRECTORY.mkdir(mode=0o700, parents=True, exist_ok=True)
    with (DIRECTORY / f"watch-{signature}.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return  # Config reloads must not create duplicate watchers.
        last_error = None
        while (RUNTIME / "hypr" / signature / ".socket.sock").exists():
            try:
                reconcile(signature)
                last_error = None
            except Exception as error:
                if str(error) != last_error:
                    log(str(error))
                    last_error = str(error)
            time.sleep(1)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("start", "stop", "watch", "status"))
    parser.add_argument("--profile", choices=("1080p", "native"), default="1080p",
                        help="start: 1080p = fixed 1080p30 + dwindle; native = keep the "
                             "resolution but disable the other monitors while streaming")
    args = parser.parse_args()
    if args.action == "status":
        with locked():
            print(json.dumps(load(), indent=2))
    elif args.action == "start":
        start(args.profile)
    else:
        {"stop": stop, "watch": watch}[args.action]()


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        log(str(error))
        sys.exit(1)
