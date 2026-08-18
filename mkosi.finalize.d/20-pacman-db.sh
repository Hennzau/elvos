#!/bin/bash
set -eu -o pipefail

if [[ -d $BUILDROOT/var/lib/pacman/local ]]; then
        mkdir -p "$BUILDROOT/usr/lib/pacman"
        rm -rf "$BUILDROOT/usr/lib/pacman/local"
        mv "$BUILDROOT/var/lib/pacman/local" "$BUILDROOT/usr/lib/pacman/local"
fi
