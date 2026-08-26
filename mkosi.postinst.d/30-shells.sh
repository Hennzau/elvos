#!/bin/bash
set -eu -o pipefail

shells="$BUILDROOT/etc/shells"

for shell in /usr/bin/nu /bin/nu; do
        [[ -e $BUILDROOT$shell ]] || continue
        grep -qxF "$shell" "$shells" || echo "$shell" >>"$shells"
done
