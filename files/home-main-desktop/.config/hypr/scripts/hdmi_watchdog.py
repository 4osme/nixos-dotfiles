#!/usr/bin/env python3
"""Watchdog for the 4K output (HDMI-A-1 / ASUS VA32U).

The 4K output sometimes stops syncing (black screen / "no signal") after an
input-source switch, an HPD drop or a suspend/resume, even though Hyprland
still believes the output is on.  This watcher polls:

  * the DRM connector (HPD + kernel DPMS),
  * Hyprland's monitor state,
  * DDC/CI (input source + power mode),

and re-syncs the link when the monitor stops responding.  It never fights a
deliberate DPMS-off: it only acts while the compositor says the output is on.

Usage:
    hdmi_watchdog.py            run the watcher (one instance, flock)
    hdmi_watchdog.py --status   print one health report and exit
"""

import fcntl
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import time
from datetime import datetime

OUTPUT = "HDMI-A-1"
DRM_DIR = "/sys/class/drm/card0-" + OUTPUT
STATE_DIR = os.path.join(os.path.expanduser("~"), ".local", "state")
LOG_PATH = os.path.join(STATE_DIR, "hdmi-watchdog.log")
LOCK_PATH = "/run/user/%d/hdmi-watchdog.lock" % os.getuid()
SUNSHINE_DIR = "/run/user/1000/sunshine-hypr-display"
# Written by hypr-stream-display.py while the streaming profile still has to
# put the physical outputs back. Only then may the watchdog re-enable an
# output on its own; an output the user disabled stays disabled.
RESTORE_PENDING = os.path.join(SUNSHINE_DIR, "restore-pending")

MODE_60 = "3840x2160@60.0"
MODE_5994 = "3840x2160@59.94"
POSITION = "900x0"
SCALE = "1.0"

DDC_INPUT = "60"
DDC_POWER = "D6"
INPUT_HDMI1 = 0x11
INPUT_HDMI2 = 0x12
POWER_ON = 0x01

POLL_FAST = 1.0
POLL_HYPR = 3.0
POLL_DDC = 10.0
DDC_FAIL_LIMIT = 2
# Keep the recovery attempts far apart: every attempt makes the monitor
# light up, so a tight loop would turn into a visible on/off cycle.
RECOVERY_COOLDOWN = 60.0
MAX_RECOVERIES = 3
BACKOFF = 600.0

HYPRCTL = shutil.which("hyprctl") or "/run/host/usr/bin/hyprctl"
DDCUTIL = shutil.which("ddcutil") or "/run/host/usr/bin/ddcutil"

running = True
bus = None
next_bus_scan = 0.0
last_conn = None
last_comp_on = None
last_comp_present = None
last_comp_disabled = None
last_input = None
last_power = None
ddc_fail = 0
last_recovery = 0.0
recoveries = 0
backoff_until = 0.0
last_notify = 0.0
refresh_at = 0.0
refresh_reason = ""
verify_at = 0.0
wake_check_at = 0.0
last_ddc_poll = 0.0
last_hypr_poll = 0.0
streaming_logged = False
disconnect_notified = False
# Whether the monitor was seen on (the compositor driving the output). Cleared
# when the compositor puts the output into DPMS-off, so a monitor the user
# slept on purpose is not woken up again.
monitor_on = False


def restore_pending():
    """True while the streaming profile still has to restore the outputs."""
    return os.path.exists(RESTORE_PENDING)


def forget_restore_pending():
    try:
        os.unlink(RESTORE_PENDING)
    except OSError:
        pass


def log(msg):
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        if os.path.exists(LOG_PATH) and os.path.getsize(LOG_PATH) > 1_000_000:
            os.replace(LOG_PATH, LOG_PATH + ".1")
        with open(LOG_PATH, "a") as f:
            f.write("%s %s\n" % (datetime.now().strftime("%Y-%m-%d %H:%M:%S"), msg))
    except OSError:
        pass


def notify(msg, force=False):
    global last_notify
    now = time.time()
    if not force and now - last_notify < 60.0:
        log("notify suppressed: " + msg)
        return
    last_notify = now
    run([HYPRCTL, "notify", "-1", "5000", "rgb(f9e2af)", msg], timeout=5)


def run(cmd, timeout=8):
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, (p.stdout or "") + (p.stderr or "")
    except (subprocess.TimeoutExpired, OSError) as e:
        return 124, str(e)


def read_sysfs(name):
    try:
        with open(os.path.join(DRM_DIR, name)) as f:
            return f.read().strip()
    except OSError:
        return None


def hypr_monitor():
    rc, out = run([HYPRCTL, "monitors", "-j"], timeout=6)
    if rc != 0:
        return None, out.strip()
    try:
        for m in json.loads(out):
            if m.get("name") == OUTPUT:
                return m, ""
    except json.JSONDecodeError as e:
        return None, "json: %s" % e
    return None, ""


def find_ddc_bus():
    rc, out = run([DDCUTIL, "detect", "--brief"], timeout=25)
    if rc != 0:
        return None
    found = None
    for line in out.splitlines():
        line = line.strip()
        if line.startswith("I2C bus:"):
            m = re.search(r"/dev/i2c-(\d+)", line)
            found = int(m.group(1)) if m else None
        elif line.startswith("DRM connector:") and line.endswith("card0-" + OUTPUT):
            return found
    return None


def ddc_get(busno, vcp):
    if busno is None:
        return None, "no bus"
    rc, out = run(
        [DDCUTIL, "--bus", str(busno), "getvcp", vcp],
        timeout=10,
    )
    if rc != 0:
        tail = out.strip().splitlines()
        return None, tail[-1] if tail else "rc=%d" % rc
    m = re.search(r"sl=0x([0-9a-fA-F]+)", out)
    if not m:
        return None, "no sl in ddcutil output"
    return int(m.group(1), 16), ""


def ddc_set(busno, vcp, value):
    if busno is None:
        return False
    rc, _ = run([DDCUTIL, "--bus", str(busno), "setvcp", vcp, hex(value)], timeout=10)
    return rc == 0


def read_ddc_state(force_bus=False):
    """Return (input, power) or (None, None) if DDC is not answering."""
    global bus, next_bus_scan, last_input, last_power
    now = time.time()
    if bus is None or force_bus:
        if now >= next_bus_scan or force_bus:
            bus = find_ddc_bus()
            next_bus_scan = now + 30.0
            if bus is not None:
                log("DDC bus: /dev/i2c-%d" % bus)
    if bus is None:
        return None, None
    inp, ierr = ddc_get(bus, DDC_INPUT)
    pwr, perr = ddc_get(bus, DDC_POWER)
    if inp is None or pwr is None:
        log("DDC read failed: %s" % (ierr or perr))
        return None, None
    last_input, last_power = inp, pwr
    return inp, pwr


def set_mode(mode):
    lua = (
        'hl.monitor({ output = "%s", mode = "%s", position = "%s", scale = %s, '
        'transform = 0, bitdepth = 8, cm = "edid", supports_hdr = -1, '
        'supports_wide_color = -1 })'
    ) % (OUTPUT, mode, POSITION, SCALE)
    rc, out = run([HYPRCTL, "repl", lua], timeout=8)
    return rc == 0


def dpms_on():
    rc, _ = run([HYPRCTL, "dispatch", 'hl.dsp.dpms("on")'], timeout=5)
    return rc == 0


def streaming_active():
    return os.path.exists(os.path.join(SUNSHINE_DIR, "1080p.active")) or os.path.exists(
        os.path.join(SUNSHINE_DIR, "native.active")
    )


def is_bad_now():
    """Fresh check used while recovering."""
    if read_sysfs("status") != "connected":
        return False
    m, _ = hypr_monitor()
    if m is None:
        return True
    if m.get("disabled"):
        return True
    if not m.get("dpmsStatus"):
        return False
    if read_sysfs("dpms") == "Off":
        return True
    inp, pwr = read_ddc_state()
    if inp is None or pwr is None:
        return True
    if inp != INPUT_HDMI1:
        return False
    return pwr != POWER_ON


def recover(reason):
    global last_recovery, recoveries, backoff_until
    if streaming_active():
        return
    now = time.time()
    if now < backoff_until or now - last_recovery < RECOVERY_COOLDOWN:
        return
    last_recovery = now
    recoveries += 1
    log("recovery #%d: %s" % (recoveries, reason))
    notify("HDMI-A-1: re-syncing (%s)" % reason)

    # A monitor that does not answer DDC is asleep. Waking it with DPMS only
    # lights it up for a moment and it falls asleep again (the visible on/off
    # cycle), so skip that step and go for the input cycle, which is what
    # reliably wakes a monitor that dropped its link.
    inp, _ = read_ddc_state()
    if inp is None:
        log("recovery: the monitor does not answer DDC, skipping the DPMS wake-up")
    else:
        dpms_on()
        time.sleep(1.2)
        if not is_bad_now():
            log("recovery ok: dpms on")
            recoveries = 0
            return

    set_mode(MODE_60)
    time.sleep(2.0)
    if not is_bad_now():
        log("recovery ok: mode reapply")
        recoveries = 0
        return

    set_mode(MODE_5994)
    time.sleep(1.5)
    set_mode(MODE_60)
    time.sleep(2.0)
    if not is_bad_now():
        log("recovery ok: mode toggle")
        recoveries = 0
        return

    inp, _ = read_ddc_state()
    if inp in (None, INPUT_HDMI1):
        log("recovery: DDC input cycle")
        ddc_set(bus, DDC_INPUT, INPUT_HDMI2)
        time.sleep(1.5)
        ddc_set(bus, DDC_INPUT, INPUT_HDMI1)
        time.sleep(2.0)
        if not is_bad_now():
            log("recovery ok: input cycle")
            recoveries = 0
            return

    log("recovery failed: %s" % reason)
    notify("HDMI-A-1: still no response - check cable/input")
    if recoveries >= MAX_RECOVERIES:
        backoff_until = time.time() + BACKOFF
        log("backing off for %ds" % int(BACKOFF))
        recoveries = 0


def cmd_status():
    conn = read_sysfs("status")
    kdpms = read_sysfs("dpms")
    m, err = hypr_monitor()
    print("connector:    %s" % conn)
    print("kernel dpms:  %s" % kdpms)
    if m:
        print(
            "hyprland:     present dpms=%s disabled=%s mode=%sx%s@%s focused=%s"
            % (
                m.get("dpmsStatus"),
                m.get("disabled"),
                m.get("width"),
                m.get("height"),
                m.get("refreshRate"),
                m.get("focused"),
            )
        )
    else:
        print("hyprland:     missing (%s)" % (err or "not listed"))
    print("streaming:    %s" % ("yes" if streaming_active() else "no"))
    b = find_ddc_bus()
    print("ddc bus:      %s" % (b if b is not None else "not found"))
    if b is not None:
        inp, ierr = ddc_get(b, DDC_INPUT)
        pwr, perr = ddc_get(b, DDC_POWER)
        print(
            "ddc input:    %s"
            % ("%#04x (HDMI-1)" % inp if inp == INPUT_HDMI1 else ("%#04x" % inp if inp is not None else "error: " + ierr))
        )
        print(
            "ddc power:    %s"
            % ("%#04x (on)" % pwr if pwr == POWER_ON else ("%#04x" % pwr if pwr is not None else "error: " + perr))
        )
    if conn != "connected":
        print("verdict:      DISCONNECTED")
    elif m is None:
        print("verdict:      NOT PRESENT IN HYPRLAND")
    elif m.get("disabled"):
        print("verdict:      DISABLED")
    elif not m.get("dpmsStatus"):
        print("verdict:      DPMS OFF (idle)")
    elif kdpms == "Off":
        print("verdict:      KERNEL DPMS OFF - MISMATCH")
    elif b is None:
        print("verdict:      DDC UNREACHABLE")
    else:
        print("verdict:      OK")
    return 0


def watch():
    global last_conn, last_comp_on, last_comp_present, last_comp_disabled
    global last_hypr_poll, last_ddc_poll, ddc_fail, refresh_at, refresh_reason
    global verify_at, wake_check_at, next_bus_scan, bus, streaming_logged
    global disconnect_notified, last_input, last_power
    global monitor_on

    log("watchdog started (pid %d)" % os.getpid())
    while running:
        now = time.time()

        if streaming_active():
            if not streaming_logged:
                log("Sunshine profile active; watchdog paused")
                streaming_logged = True
            last_conn = read_sysfs("status")
            last_comp_on = None
            last_input = None
            ddc_fail = 0
            time.sleep(2.0)
            continue
        if streaming_logged:
            log("Sunshine profile ended; watchdog resumed")
            streaming_logged = False
            refresh_at = now + 2.0
            refresh_reason = "streaming profile ended"

        conn = read_sysfs("status")
        kdpms = read_sysfs("dpms")

        if now >= last_hypr_poll:
            last_hypr_poll = now + POLL_HYPR
            m, _ = hypr_monitor()
            comp_present = m is not None
            comp_on = bool(m and not m.get("disabled") and m.get("dpmsStatus"))
            comp_disabled = bool(m and m.get("disabled"))
        else:
            comp_present = last_comp_present
            comp_on = last_comp_on
            comp_disabled = last_comp_disabled

        if comp_on:
            monitor_on = True
        elif not comp_disabled:
            # DPMS-off: the monitor went to sleep on purpose. Remember that so
            # a later "output disabled" is not answered by waking it up.
            monitor_on = False

        if last_conn is not None and conn != last_conn:
            log("connector: %s -> %s" % (last_conn, conn))
            if conn == "connected":
                refresh_at = now + 2.0
                refresh_reason = "HPD reconnect"
                disconnect_notified = False
            elif not disconnect_notified:
                notify("HDMI-A-1: connection lost")
                disconnect_notified = True
        last_conn = conn

        if last_comp_on is not None and comp_on != last_comp_on:
            log("compositor dpms: %s -> %s" % (last_comp_on, comp_on))
            if comp_on and not last_comp_on:
                wake_check_at = now + 2.5
        last_comp_on = comp_on
        last_comp_present = comp_present
        last_comp_disabled = comp_disabled

        if now >= last_ddc_poll:
            last_ddc_poll = now + POLL_DDC
            if not comp_on:
                # The compositor has the output off (DPMS-off or disabled), so the
                # monitor is asleep on purpose. A DDC/CI transaction wakes many
                # monitors, and the read then fails while they are waking up:
                # the monitor would flap between on and off. Stay off the bus
                # until the compositor drives the output again.
                ddc_fail = 0
            else:
                if bus is None and now >= next_bus_scan:
                    bus = find_ddc_bus()
                    next_bus_scan = now + 30.0
                    if bus is not None:
                        log("DDC bus: /dev/i2c-%d" % bus)
                if bus is not None:
                    inp, ierr = ddc_get(bus, DDC_INPUT)
                    pwr, perr = ddc_get(bus, DDC_POWER)
                    if inp is not None and pwr is not None:
                        ddc_fail = 0
                        if last_input is not None and inp != last_input:
                            log("input: %#04x -> %#04x" % (last_input, inp))
                            if inp == INPUT_HDMI1 and comp_on:
                                refresh_at = now + 2.5
                                refresh_reason = "input switched back to HDMI-1"
                        last_input, last_power = inp, pwr
                    else:
                        ddc_fail += 1
                        log("DDC poll failed (%d/%d): %s" % (ddc_fail, DDC_FAIL_LIMIT, ierr or perr))
                        if ddc_fail >= DDC_FAIL_LIMIT:
                            bus = None
                            next_bus_scan = now

        if refresh_at and now >= refresh_at:
            refresh_at = 0.0
            log("re-sync: %s" % refresh_reason)
            set_mode(MODE_60)
            verify_at = now + 3.0

        if wake_check_at and now >= wake_check_at:
            wake_check_at = 0.0
            if comp_on:
                inp, pwr = read_ddc_state()
                if inp == INPUT_HDMI1 and pwr == POWER_ON:
                    log("wake: monitor responded")
                else:
                    log(
                        "wake: monitor not responding (input=%s power=%s)"
                        % ("%#04x" % inp if inp is not None else "?", "%#04x" % pwr if pwr is not None else "?")
                    )
                    recover("monitor did not come back after wake")

        if verify_at and now >= verify_at:
            verify_at = 0.0
            if comp_on and is_bad_now():
                recover("mode reapply did not restore the link")

        if comp_present and comp_disabled and conn == "connected":
            # Only recover when the streaming profile still owes us a restore.
            # An output the user disabled on purpose stays disabled, and a
            # monitor that is asleep is not woken up.
            if not restore_pending():
                pass
            elif monitor_on and last_power == POWER_ON:
                recover("output disabled in Hyprland")
                m, _ = hypr_monitor()
                if m is not None and not m.get("disabled"):
                    forget_restore_pending()
                    log("restore finished: HDMI-A-1 is back")
            else:
                log(
                    "HDMI-A-1 is disabled in Hyprland but the monitor is not "
                    "answering DDC (input=%s power=%s); leaving it alone"
                    % (
                        "%#04x" % last_input if last_input is not None else "?",
                        "%#04x" % last_power if last_power is not None else "?",
                    )
                )
        elif comp_on and conn == "connected":
            if kdpms == "Off":
                recover("kernel DPMS off while compositor is on")
            elif last_input is not None and last_input != INPUT_HDMI1:
                pass  # user selected another source; do not fight it
            elif ddc_fail >= DDC_FAIL_LIMIT:
                recover("monitor not answering DDC")
            elif last_power is not None and last_power != POWER_ON:
                recover("monitor reports power %#04x" % last_power)

        time.sleep(POLL_FAST)

    log("watchdog stopped")


def on_signal(signum, frame):
    global running
    running = False


def main():
    if "--status" in sys.argv:
        return cmd_status()

    if "--recover" in sys.argv:
        global last_recovery, recoveries
        last_recovery = 0.0
        recoveries = 0
        recover("manual")
        return 0

    lock = open(LOCK_PATH, "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        print("hdmi_watchdog: already running", file=sys.stderr)
        return 0

    signal.signal(signal.SIGTERM, on_signal)
    signal.signal(signal.SIGINT, on_signal)
    watch()
    return 0


if __name__ == "__main__":
    sys.exit(main())
