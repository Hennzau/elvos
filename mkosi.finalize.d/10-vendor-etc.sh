#!/bin/bash
set -eu -o pipefail

factory="$BUILDROOT/usr/share/factory/etc"

mkdir -p "$factory"
tar -C "$BUILDROOT/etc" -cf - \
        --exclude=./machine-id \
        --exclude=./resolv.conf \
        --exclude=./mtab \
        --exclude=./os-release \
        --exclude=./.pwd.lock \
        --exclude=./.updated \
        . | tar -C "$factory" -xf -

# Excluding resolv.conf from the tar above only keeps the build's copy out; the
# Arch package installed one into the factory directly, and `C+ /etc` sorts
# before systemd-resolve.conf, so it would land as a regular file and make
# systemd's own `L! /etc/resolv.conf -> ../run/systemd/resolve/stub-resolv.conf`
# skip. Drop it so resolved gets to create the stub symlink and DNS works.
rm -f "$factory/resolv.conf"

if [[ -L $factory/localtime ]]; then
        target=$(readlink "$factory/localtime")
        ln -sfn "/${target#../}" "$factory/localtime"
fi
