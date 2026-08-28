#!/bin/bash
set -eu -o pipefail

units=(
        getty@tty1.service

        systemd-homed-firstboot.service
        systemd-userdbd.socket
        elvos-subid.service

        gdm.service
        power-profiles-daemon.service
        keyd.service

        iwd.service
        systemd-networkd.service
        systemd-resolved.service
        systemd-timesyncd.service

        bluetooth.service
)

systemctl --root="$BUILDROOT" enable "${units[@]}"

user_units=(
        elvos-dotfiles.service
        ssh-agent.socket
        udiskie.service
)

systemctl --root="$BUILDROOT" --global enable "${user_units[@]}"

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
