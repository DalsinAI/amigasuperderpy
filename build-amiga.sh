#!/bin/sh
# Builds SuperDerpy (Sebastian Krzyszkowiak's Allegro 5 game) for GFOS
# (AmigaOS 3.2.3 with GFOpenUp) with a stove, on amigaallegro (Allegro 5 over
# SDL2.module, GL.module and OpenGPU), with FLAC, Ogg Vorbis and TTF:
#   STOVE=.../stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh
# SuperDerpy and amigaallegro are fetched at what sd.lock gives; nothing
# third-party is kept here. Allegro is built once and kept; a run that ends
# out of time says so, and the next run goes on.
# OUT gets Parts/SuperDerpy, a GFOpenUp part:
#   GFOpenUpTool INSTALL Parts/SuperDerpy  -> SYS:Games/SuperDerpy/
# GPL-2.0-or-later, like SuperDerpy. Copyright (c) 2026 AmiCradle Team.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/sd.lock"
STOVE=${STOVE:-"$HOME/AmiCradle/stoves/os32-gcc16-open6"}
WORK="${WORK:-$HOME/.cache/amigasuperderpy/build}"; OUT="${OUT:-$WORK/out}"
JOBS=${JOBS:-$(nproc 2>/dev/null || echo 4)}; export JOBS
TC="$STOVE/prefix"; PATH="$TC/bin:$PATH"; export PATH
mkdir -p "$WORK" "$OUT"; OUT=$(cd "$OUT" && pwd)
t0=$(date +%s)
m68k-amigaos-gcc --version | head -n 1

# --- amigaallegro with FLAC, Ogg Vorbis and TTF (kept between runs) ------------------------------
set +e
ALLEGRO_BUDGET=$(( ${BUDGET_TOTAL:-840} - 60 )) sh "$HERE/scripts/build-allegro.sh" "$STOVE" "$WORK" "$ALLEGRO_GIT" "$ALLEGRO_COMMIT" > "$WORK/allegro.out"
rc=$?
set -e
[ $rc -eq 3 ] && { echo "out of time in allegro, run again to go on"; exit 0; }
[ $rc -eq 0 ] || exit $rc
PFX=$(tail -n 1 "$WORK/allegro.out"); VP="$WORK/vorbis-prefix"
echo "allegro: $PFX ($(( $(date +%s) - t0 )) s)"

# --- SuperDerpy at its pinned commit, with patches/ -----------------------------------
SRC="$WORK/superderpy"
PSUM=$(cat "$HERE"/patches/*.patch 2>/dev/null | sha256sum | cut -c1-16)
if [ "$(cat "$SRC/.patched" 2>/dev/null)" != "$SD_COMMIT-$PSUM" ]; then
    rm -rf "$SRC"; mkdir -p "$SRC"; git -C "$SRC" init -q
    git -C "$SRC" fetch -q --depth 1 "$SD_GIT" "$SD_COMMIT"; git -C "$SRC" checkout -q FETCH_HEAD
    for p in "$HERE"/patches/*.patch; do
        [ -f "$p" ] || continue
        patch -s -d "$SRC" -p1 < "$p" || { echo "patch failed: $p"; exit 1; }
    done
    echo "$SD_COMMIT-$PSUM" > "$SRC/.patched"
fi

# --- compile and link ---------------------------------------------------------------------
SYSROOT="$TC/m68k-amigaos"; DEPS="$SYSROOT/port-deps"
ARCH="-mcrt=nix20 -m68040 -m68881 -pthread"
CF="$ARCH -std=gnu11 -O2 -fomit-frame-pointer -DALLEGRO_STATICLINK=1 -D__AMIGAOS3__=1 -I$SRC/src -I$PFX/include -I$SYSROOT/include"
O="$WORK/obj"; rm -rf "$O"; mkdir -p "$O"
while read -r f; do
    o="$O/$(echo "$f" | tr / _).o"
    m68k-amigaos-gcc $CF -c "$SRC/$f" -o "$o" 2> "$o.log" || { cat "$o.log"; exit 1; }
done < "$HERE/amiga/sources.txt"
m68k-amigaos-gcc $CF -c "$HERE/amiga/amiga_start.c" -o "$O/amiga_start.o"
m68k-amigaos-gcc $ARCH -o "$WORK/SuperDerpy.debug" "$O"/*.o \
    "$PFX/lib/liballegro_monolith-static.a" "$VP/lib/libFLAC.a" "$VP/lib/libvorbisfile.a" "$VP/lib/libvorbis.a" "$VP/lib/libogg.a" \
    "$SYSROOT/lib/libSDL2.a" "$SYSROOT/lib/libGL.a" "$DEPS/lib/libfreetype.a" "$DEPS/lib/libpng.a" "$DEPS/lib/libjpeg.a" "$DEPS/lib/libz.a" -lm -lpthread

# --- the GFOpenUp part: Parts/SuperDerpy -------------------------------------------------------
P="$OUT/Parts/SuperDerpy"; D="$P/Games/SuperDerpy"; rm -rf "$P"; mkdir -p "$D"
m68k-amigaos-strip -o "$D/SuperDerpy" "$WORK/SuperDerpy.debug"
cp -R "$SRC/data" "$D/"; find "$D/data" -name 'CMakeLists.txt' -delete; rm -rf "$D/data/icons" "$D/data/superderpy.desktop"
cp "$SRC/COPYING" "$D/License.txt"; cp "$HERE/README.md" "$D/ReadMe"
cp "$HERE/amiga/icons/SuperDerpy.info" "$HERE/amiga/icons/ReadMe.info" "$D/"
cp "$HERE/amiga/icons/SuperDerpy-drawer.info" "$P/Games/SuperDerpy.info"
sh "$HERE/scripts/write-part.sh" "$P" "$SD_VERSION"
ls -l "$D/SuperDerpy"
strings "$D/SuperDerpy" | grep -q 'SuperDerpy 0.2 (17.11.2026) GFOS' || { echo "no \$VER"; exit 1; }
echo "part: $(grep -c '^copy\|^default' "$P/Part") files, $(du -sk "$P" | cut -f1) KB"
echo "total: $(( $(date +%s) - t0 )) s"
