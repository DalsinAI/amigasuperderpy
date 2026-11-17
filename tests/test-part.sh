#!/bin/sh
# Unit test for scripts/write-part.sh on a fake part drawer.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
D="$T/Games/SuperDerpy"; mkdir -p "$D/data/fonts" "$D/data/menu" "$D/data/voice"
for f in SuperDerpy SuperDerpy.info ReadMe data/menu/menu.png data/fonts/ShadowsIntoLight.ttf data/voice/x.flac; do : > "$D/$f"; done
sh "$HERE/scripts/write-part.sh" "$T" 0.2
fail() { echo "FAIL: $*"; cat "$T/Part"; exit 1; }
[ "$(sed -n 1p "$T/Part")" = "part SuperDerpy 0.2" ] || fail header
grep -qx 'needs 68040' "$T/Part" || fail needs
grep -qx 'copy "Games/SuperDerpy/SuperDerpy" "SYS:Games/SuperDerpy/SuperDerpy"' "$T/Part" || fail program
grep -qx 'default "Games/SuperDerpy/SuperDerpy.info" "SYS:Games/SuperDerpy/SuperDerpy.info"' "$T/Part" || fail icon
grep -qx 'copy "Games/SuperDerpy/data/fonts/ShadowsIntoLight.ttf" "SYS:Games/SuperDerpy/data/fonts/ShadowsIntoLight.ttf"' "$T/Part" || fail font
[ "$(grep -c '^copy\|^default' "$T/Part")" = 6 ] || fail count
echo "test-part: pass"
