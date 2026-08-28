#!/bin/bash
set -eu -o pipefail

# Arch's avr-gcc is configured with --prefix=/usr and no --with-sysroot, so GCC
# derives its cross library directory as $prefix/$target/lib, i.e. /usr/avr/lib.
# Arch's avr-libc installs to /usr/lib/avr/lib instead, and none of avr-gcc,
# avr-binutils or avr-libc ships anything bridging the two. The result is that
# avr-ld cannot find crt<device>.o, libc, libm or lib<device> and every AVR link
# fails, which shows up as `qmk doctor` failing to compile a test program.
#
# Point the path GCC searches at the path the files are actually in.

link="$BUILDROOT/usr/avr"
libdir="$BUILDROOT/usr/lib/avr"

if [[ ! -d $libdir ]]; then
        echo "${0##*/}: $libdir missing - is avr-libc installed?" >&2
        exit 1
fi

# If a future avr-libc/avr-gcc ships this itself, stop rather than clobber it.
if [[ -e $link && ! -L $link ]]; then
        echo "${0##*/}: /usr/avr already exists and is not a symlink;" \
             "upstream likely fixed this - drop this script" >&2
        exit 1
fi

ln -sfn lib/avr "$link"

mkosi-chroot bash -c '
        set -eu
        d=$(mktemp -d)
        trap "rm -rf $d" EXIT
        printf "int main(void) { return 0; }\n" >"$d/t.c"
        avr-gcc -mmcu=atmega32u4 -x c -o "$d/t.elf" "$d/t.c"
'
