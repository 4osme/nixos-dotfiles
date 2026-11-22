#!/usr/bin/env bash
set -euo pipefail

# sysfs "device" excludes virtual Ethernet (veth, bridges, VLANs, etc.).
# Wi-Fi also has ARPHRD_ETHER (type 1), so exclude it explicitly.
ports=()
for port in /sys/class/net/*; do
    [ -e "$port/device" ] || continue
    [ ! -d "$port/wireless" ] && [ ! -d "$port/phy80211" ] || continue
    [ "$(cat "$port/type")" = 1 ] || continue
    ports+=("${port##*/}")
done

if [ "${#ports[@]}" -ne 1 ]; then
    printf 'VLAN 202: expected exactly one physical Ethernet port, found %s (%s); not creating VLAN, retrying later\n' \
        "${#ports[@]}" "${ports[*]}" >&2
    exit 1
fi

parent=${ports[0]}
uuid=1dc248dc-d8a6-488f-bf45-4c58d7463202
directory=/run/NetworkManager/system-connections
profile="$directory/main-desktop-vlan202.nmconnection"
mkdir -p "$directory"
temporary=$(mktemp "$profile.XXXXXX")
trap 'rm -f "$temporary"' EXIT

# Runtime-only profile: re-detect the parent on every boot instead of
# persisting an interface name that might change after hardware replacement.
cat > "$temporary" <<EOF
[connection]
id=main-desktop-vlan202
uuid=$uuid
type=vlan
interface-name=nas202
autoconnect=true
autoconnect-retries=0

[vlan]
id=202
parent=$parent

[ipv4]
method=manual
address1=172.16.50.3/24
never-default=true
ignore-auto-dns=true

[ipv6]
method=disabled
EOF
chmod 600 "$temporary"
mv -f "$temporary" "$profile"

printf 'VLAN 202: using %s; nas202 = 172.16.50.3/24 (no gateway)\n' "$parent"
nmcli connection load "$profile"
nmcli --wait 15 connection up uuid "$uuid"
