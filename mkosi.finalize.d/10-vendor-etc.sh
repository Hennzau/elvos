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

rm -f "$factory/resolv.conf"

if [[ -L $factory/localtime ]]; then
        target=$(readlink "$factory/localtime")
        ln -sfn "/${target#../}" "$factory/localtime"
fi
