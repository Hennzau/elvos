#!/bin/bash
set -eu -o pipefail

locales=(
        en_US.UTF-8
)

for locale in "${locales[@]}"; do
        charset=${locale#*.}

        sed -i -E "s|^#[[:space:]]*(${locale//./\\.} ${charset})[[:space:]]*$|\1|" \
                "$BUILDROOT/etc/locale.gen"

        if ! grep -qx "$locale $charset" "$BUILDROOT/etc/locale.gen"; then
                echo "$locale $charset" >>"$BUILDROOT/etc/locale.gen"
        fi
done

mkosi-chroot locale-gen

for locale in "${locales[@]}"; do
        if ! mkosi-chroot localedef --list-archive | grep -qx "${locale/.UTF-8/.utf8}"; then
                echo "locale $locale missing from /usr/lib/locale/locale-archive" >&2
                exit 1
        fi
done
