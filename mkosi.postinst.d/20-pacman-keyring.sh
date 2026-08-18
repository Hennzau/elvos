#!/bin/bash
set -eu -o pipefail

mkosi-chroot pacman-key --init
mkosi-chroot pacman-key --populate archlinux
