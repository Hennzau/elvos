#!/bin/bash
set -eu -o pipefail

# Enable units, and move all enablement into /usr.
#
# Runs before 10-vendor-etc.sh: that stages /etc into the factory, so these
# symlinks have to be out of /etc by then or they get captured and seeded back.
#
# `systemctl enable` writes to /etc/systemd/system, which this image does not
# ship -- mkosi.repart/12-usr.conf copies /usr alone. Worse, /etc is only
# populated by tmpfiles once PID 1 is already running, and PID 1 resolves the
# boot transaction before that, so a .wants symlink seeded into /etc would take
# effect a boot late. /usr/lib/systemd/system/*.wants is equivalent, is read
# from the first instant, and is covered by verity.
#
# Letting systemctl generate the links rather than committing them by hand
# means the Alias= and Also= chains stay correct on their own -- enabling
# systemd-networkd.service alone pulls in four sockets, the network generator,
# wait-online and the dbus alias.
#
# Trade-off: `systemctl disable` cannot remove these on the installed system,
# an admin has to `systemctl mask` instead. Normal for image-based systems.

units=(
        # Console login. Also installs the autovt@ alias logind uses to spawn a
        # getty when you switch to an unused VT.
        getty@tty1.service

        # Users. homed-firstboot creates the first account; userdbd is what
        # lets nss-systemd resolve homed users at all.
        systemd-homed-firstboot.service
        systemd-userdbd.socket
        elvos-subid.service

        # Graphical session. gdm's [Install] is only Alias=display-manager.service,
        # which is what graphical.target actually wants.
        gdm.service
        power-profiles-daemon.service

        # Network. iwd does wifi association only -- its
        # EnableNetworkConfiguration defaults to false -- so networkd does
        # addressing and resolved does DNS. timesyncd matters more than it
        # looks: a drifted clock breaks TLS and package signature checks.
        iwd.service
        systemd-networkd.service
        systemd-resolved.service
        systemd-timesyncd.service

        # Hardware-gated by ConditionPathIsDirectory=/sys/class/bluetooth, so
        # this costs nothing on machines whose Bluetooth does not work.
        bluetooth.service
)

systemctl --root="$BUILDROOT" enable "${units[@]}"

# Relocate everything systemctl and mkosi's own `preset-all` left in /etc,
# for both the system and user managers.
relocate() {
        local src=$1 dst=$2 entry name

        [[ -d $src ]] || return 0

        for entry in "$src"/*.wants "$src"/*.requires; do
                [[ -d $entry ]] || continue
                name=${entry##*/}
                mkdir -p "$dst/$name"
                cp -a "$entry/." "$dst/$name/"
                rm -rf "$entry"
        done

        # Alias symlinks sitting alongside them, e.g. display-manager.service.
        for entry in "$src"/*; do
                [[ -L $entry ]] || continue
                name=${entry##*/}
                rm -f "$dst/$name"
                cp -a "$entry" "$dst/$name"
                rm -f "$entry"
        done
}

relocate "$BUILDROOT/etc/systemd/system" "$BUILDROOT/usr/lib/systemd/system"
relocate "$BUILDROOT/etc/systemd/user" "$BUILDROOT/usr/lib/systemd/user"
