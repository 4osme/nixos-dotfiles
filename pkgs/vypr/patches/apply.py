#!/usr/bin/env python3
# Transcribed from files/scripts/vypr-build.sh of fedora-hyprtomic (the four
# anchor-asserted patches applied to the pinned Vypr v0.5.0 source). Drop the
# patches when upstream fixes them; the asserts fail loudly if the anchors
# move.
import pathlib, sys

p = pathlib.Path(sys.argv[1])
s = p.read_text()

# 1. virsh prints its state words translated; the comparisons expect English.
old = "set -uo pipefail\n"
new = (
    "set -uo pipefail\n\n"
    "# virsh prints its state words translated; the checks below expect English.\n"
    "# ja_JP made \"vypr detect\" try to start an already-running VM.\n"
    "virsh() { LC_ALL=C command virsh \"$@\"; }\n"
)
assert s.count(old) == 1, "locale anchor"
s = s.replace(old, new, 1)

# 2. qemu.conf and the checks that read it: treat an unreadable file as
#    unknown and ask the running QEMU instead; only a value that was actually
#    obtained can fail the check.
old = """qemu_conf() {
    grep -sE "^[[:space:]]*$1[[:space:]]*=" /etc/libvirt/qemu.conf 2>/dev/null | tail -1 |
        sed -E 's/^[^=]*=[[:space:]]*"?([^"]*)"?.*/\\1/'
}"""
new = """qemu_conf() {
    local v
    v=$(grep -sE "^[[:space:]]*$1[[:space:]]*=" /etc/libvirt/qemu.conf 2>/dev/null | tail -1 |
        sed -E 's/^[^=]*=[[:space:]]*"?([^"]*)"?.*/\\1/')
    if [ -z "$v" ]; then
        # /etc/libvirt is root-only on the Fedora base; ask the running QEMU
        # rather than pretending the file says nothing.
        local p
        p=$(ps -C qemu-system-x86_64 -o pid=,args= | awk -v n="-name guest=$VM," 'index($0, n) { print $1; exit }')
        if [ -n "$p" ]; then
            case "$1" in
                user)  v=$(stat -c %U /proc/"$p") ;;
                group) v=$(stat -c %G /proc/"$p") ;;
            esac
        fi
    fi
    printf '%s\\n' "$v"
}"""
assert s.count(old) == 1, "qemu_conf anchor"
s = s.replace(old, new, 1)

old = """ensure_guest_ram() {
    local want; want=$(id -gn)
    if [ "$(qemu_conf group)" != "$want" ]; then"""
new = """ensure_guest_ram() {
    local want have; want=$(id -gn); have=$(qemu_conf group)
    if [ -n "$have" ] && [ "$have" != "$want" ]; then"""
assert s.count(old) == 1, "guest ram anchor"
s = s.replace(old, new, 1)

# 3. ssh/scp also talk to whatever agent the desktop runs (Bitwarden's, say),
#    which then pops unlock dialogs for connections that authenticate with the
#    -i key and never need an agent at all.
old = '-i "$KEY"'
new = '-i "$KEY" -o IdentityAgent=none'
assert s.count(old) == 4, "ssh/scp anchors"
s = s.replace(old, new)

p.write_text(s)

# 4. Fixed-size the application windows (host/src/main.c). With the size hints
#    pinned to the frame size, the compositor refuses user resizes instead of
#    leaving a stretched picture when the guest cannot follow (a maximized
#    guest window made that permanent). SDL commits queued limit changes with
#    the next SetWindowSize, so the adoption below updates hints and size
#    together; the whole-desktop view stays resizable, as it is decorated and
#    dragged by its decorations.
m = pathlib.Path(sys.argv[2])
s = m.read_text()

old = """    views[0].win = SDL_CreateWindow(opt.title, win_w, win_h,
                                    SDL_WINDOW_RESIZABLE | vk_window_flag(opt.backend) |
                                    (decorated ? 0 : SDL_WINDOW_BORDERLESS));
    if (!views[0].win) {
        fprintf(stderr, "vypr: SDL_CreateWindow: %s\\n", SDL_GetError());
        return 1;
    }
"""
new = old + """
    /*
     * Fixed window size: the guest owns the size and the picture is never
     * scaled, so pin the compositor's size hints to the window size - a user
     * resize then does nothing instead of stretching the frame into a size the
     * guest cannot follow. The frame-size adoption below keeps the hints in
     * step. The whole-desktop view stays resizable: it is decorated and is
     * dragged by its decorations.
     */
    if (!decorated) {
        SDL_SetWindowMinimumSize(views[0].win, win_w, win_h);
        SDL_SetWindowMaximumSize(views[0].win, win_w, win_h);
    }
"""
assert s.count(old) == 1, "create anchor"
s = s.replace(old, new, 1)

old = """                    if (!v->is_popup && resize_at == 0 && !(opt.size_w && opt.size_h))
                        SDL_SetWindowSize(v->win, (int)f.width, (int)f.height);
"""
new = """                    if (!v->is_popup && resize_at == 0 && !(opt.size_w && opt.size_h)) {
                        if (opt.window_id != VYPR_DESKTOP_WINDOW_ID) {
                            SDL_SetWindowMinimumSize(v->win, (int)f.width, (int)f.height);
                            SDL_SetWindowMaximumSize(v->win, (int)f.width, (int)f.height);
                        }
                        SDL_SetWindowSize(v->win, (int)f.width, (int)f.height);
                    }
"""
assert s.count(old) == 1, "adoption anchor"
s = s.replace(old, new, 1)

m.write_text(s)
print("window code patched")
