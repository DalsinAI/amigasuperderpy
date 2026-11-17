#!/bin/sh
# sd.lock pins full commits; $VER carries the locked version; amiga/sources.txt
# is SuperDerpy's src/CMakeLists.txt SRC_LIST (SD_SRC=<checkout>).
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$HERE/sd.lock"
for c in "$SD_COMMIT" "$ALLEGRO_COMMIT"; do echo "$c" | grep -Eqx '[0-9a-f]{40}' || { echo "FAIL commit $c"; exit 1; }; done
grep -q "SuperDerpy $SD_VERSION " "$HERE/amiga/amiga_start.c" || { echo "FAIL \$VER"; exit 1; }
[ "$(sort -u "$HERE/amiga/sources.txt" | wc -l)" = "$(wc -l < "$HERE/amiga/sources.txt")" ] || { echo "FAIL duplicate sources"; exit 1; }
if [ -n "${SD_SRC:-}" ]; then
    up=$(sed -n '/SET(SRC_LIST/,/)/p' "$SD_SRC/src/CMakeLists.txt" | grep -o '[a-z0-9_/]*\.c' | sed 's#^#src/#')
    [ "$up" = "$(cat "$HERE/amiga/sources.txt")" ] || { echo "FAIL sources differ from upstream SRC_LIST"; exit 1; }
    while read -r f; do [ -f "$SD_SRC/$f" ] || { echo "FAIL missing $f"; exit 1; }; done < "$HERE/amiga/sources.txt"
fi
echo "test_lock: pass"
