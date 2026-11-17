#!/bin/sh
# Builds amigaallegro (Allegro 5 for classic AmigaOS 3.x: SDL2.module, GL.module
# and OpenGPU underneath) at a pinned commit into a static monolith prefix, the
# way amigaopensurge does, and keeps it between runs.
#   build-allegro.sh <stove> <work dir> <amigaallegro git url> <commit>
# Prints the prefix on its last line. Copyright (c) 2026 AmiCradle Team.
set -eu
STOVE=$1; WORK=$2; GITURL=$3; COMMIT=$4
SYSROOT="$STOVE/prefix/m68k-amigaos"; DEPS="$SYSROOT/port-deps"
SRC="$WORK/amigaallegro"; BLD="$WORK/allegro-build"; PFX="$WORK/allegro-prefix"
if [ -f "$PFX/lib/liballegro_monolith-static.a" ] && [ "$(cat "$PFX/.rev" 2>/dev/null)" = "$COMMIT" ]; then
    echo "$PFX"; exit 0
fi
for f in "$SYSROOT/lib/libSDL2.a" "$SYSROOT/lib/libGL.a" "$SYSROOT/include/SDL2/SDL.h" "$DEPS/lib/libpng.a" "$DEPS/lib/libz.a" "$DEPS/lib/libfreetype.a" "$DEPS/lib/libjpeg.a"; do
    [ -e "$f" ] || { echo "stove lacks $f (Allegro needs SDL2.module, GL.module, libpng)" >&2; exit 2; }
done
if [ "$(git -C "$SRC" rev-parse HEAD 2>/dev/null)" != "$COMMIT" ]; then
    rm -rf "$SRC" "$BLD"; mkdir -p "$SRC"; git -C "$SRC" init -q
    git -C "$SRC" fetch -q --depth 1 "$GITURL" "$COMMIT"; git -C "$SRC" checkout -q FETCH_HEAD
fi
# Ogg Vorbis, static, into its own prefix (kept)
VP="$WORK/vorbis-prefix"
xiph() { # name url tag commit
    d="$WORK/$1"
    if [ "$(git -C "$d" rev-parse HEAD 2>/dev/null)" != "$4" ]; then
        rm -rf "$d" "$WORK/$1-build"; git clone -q --depth 1 --branch "$3" "$2" "$d"
        [ "$(git -C "$d" rev-parse HEAD)" = "$4" ] || { echo "$1: not $4" >&2; exit 1; }
    fi
    [ -f "$VP/.$1" ] && return 0
    CFLAGS_FLAC=""
    [ "$1" = flac ] && CFLAGS_FLAC="-Dfseeko=fseek -Dftello=ftell"
    cmake -S "$d" -B "$WORK/$1-build" -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DCMAKE_TOOLCHAIN_FILE="$SRC/cmake/Toolchain-amigaos3.cmake" -DAMIGA_STOVE="$STOVE" \
        -DAMIGA_PORT_PREFIX="$VP" -DCMAKE_INSTALL_PREFIX="$VP" -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF -DINSTALL_DOCS=OFF -DCMAKE_C_FLAGS="$CFLAGS_FLAC" ${XIPH_EXTRA:-} > "$WORK/$1-cmake.log" 2>&1 || { tail -30 "$WORK/$1-cmake.log" >&2; exit 1; }
    cmake --build "$WORK/$1-build" --parallel "${JOBS:-4}" > "$WORK/$1-build.log" 2>&1 || { grep -m20 -A5 error "$WORK/$1-build.log" >&2; exit 1; }
    cmake --install "$WORK/$1-build" > /dev/null; touch "$VP/.$1"
}
xiph ogg https://github.com/xiph/ogg.git v1.3.5 e1774cd77f471443541596e09078e78fdc342e4f
xiph vorbis https://github.com/xiph/vorbis.git v1.3.7 0657aee69dec8508a0011f47f3b69d7538e9d262
XIPH_EXTRA="-DBUILD_CXXLIBS=OFF -DBUILD_PROGRAMS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF -DBUILD_DOCS=OFF -DINSTALL_MANPAGES=OFF -DWITH_OGG=ON -DWITH_STACK_PROTECTOR=OFF -DWITH_FORTIFY_SOURCE=OFF -DENABLE_MULTITHREADING=OFF"
xiph flac https://github.com/xiph/flac.git 1.4.3 28e4f0528c76b296c561e922ba67d43751990599
XIPH_EXTRA=""

# a build cut off by the stove's time limit goes on where it stopped
rm -rf "$PFX"
[ -f "$BLD/CMakeCache.txt" ] || cmake -S "$SRC" -B "$BLD" -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_TOOLCHAIN_FILE="$SRC/cmake/Toolchain-amigaos3.cmake" -DAMIGA_STOVE="$STOVE" \
    -DAMIGA_PORT_PREFIX="$PFX" -DCMAKE_INSTALL_PREFIX="$PFX" -DCMAKE_BUILD_TYPE=Release \
    -DALLEGRO_SDL=ON -DALLEGRO_AMIGA_BITMAP_BATCH_LIMIT=0 -DSHARED=OFF -DWANT_MONOLITH=ON \
    -DWANT_ALLOW_SSE=OFF -DWANT_DOCS=OFF -DWANT_TESTS=OFF -DWANT_EXAMPLES=OFF -DWANT_DEMO=OFF \
    -DWANT_OPENAL=OFF -DWANT_VIDEO=OFF -DWANT_NATIVE_DIALOG=OFF -DWANT_PHYSFS=OFF -DWANT_TTF=ON \
    -DWANT_ACODEC_DYNAMIC_LOAD=OFF -DWANT_FLAC=ON -DWANT_VORBIS=ON -DWANT_OPUS=OFF -DWANT_MODAUDIO=OFF -DWANT_MP3=OFF \
    -DWANT_IMAGE_FREEIMAGE=OFF -DWANT_IMAGE_WEBP=OFF -DWANT_IMAGE_JPG=ON -DWANT_IMAGE_PNG=ON \
    -DSDL2_INCLUDE_DIR="$SYSROOT/include/SDL2" -DSDL2_LIBRARY_TEMP="$SYSROOT/lib/libSDL2.a" \
    -DOPENGL_gl_LIBRARY="$SYSROOT/lib/libGL.a" -DOPENGL_INCLUDE_DIR="$SYSROOT/include" \
    -DPNG_PNG_INCLUDE_DIR="$DEPS/include" -DPNG_LIBRARY="$DEPS/lib/libpng.a" \
    -DZLIB_INCLUDE_DIR="$DEPS/include" -DZLIB_LIBRARY="$DEPS/lib/libz.a" \
    -DFLAC_INCLUDE_DIR="$VP/include" -DFLAC_LIBRARY="$VP/lib/libFLAC.a" \
    -DFREETYPE_INCLUDE_DIRS="$DEPS/include/freetype2" -DFREETYPE_LIBRARY="$DEPS/lib/libfreetype.a" \
    -DJPEG_INCLUDE_DIR="$DEPS/include" -DJPEG_LIBRARY="$DEPS/lib/libjpeg.a" \
    -DOGG_INCLUDE_DIR="$VP/include" -DOGG_LIBRARY="$VP/lib/libogg.a" \
    -DVORBIS_INCLUDE_DIR="$VP/include" -DVORBIS_LIBRARY="$VP/lib/libvorbis.a" -DVORBISFILE_LIBRARY="$VP/lib/libvorbisfile.a" \
    -DALLEGRO_HAVE_FSEEKO=0 -DALLEGRO_HAVE_FTELLO=0 -DALLEGRO_HAVE_STRERROR_R=0 -DALLEGRO_HAVE_STRERROR_S=0 \
    > "$WORK/allegro-cmake.log" 2>&1 || { tail -40 "$WORK/allegro-cmake.log" >&2; rm -rf "$BLD"; exit 1; }
set +e
timeout "${ALLEGRO_BUDGET:-780}" cmake --build "$BLD" --parallel "${JOBS:-4}" > "$WORK/allegro-build.log" 2>&1
rc=$?
set -e
[ $rc -eq 124 ] && { echo "allegro: out of time, run again to go on" >&2; exit 3; }
[ $rc -eq 0 ] || { grep -m20 -B2 -A6 'error' "$WORK/allegro-build.log" >&2; exit 1; }
cmake --install "$BLD" > /dev/null
echo "$COMMIT" > "$PFX/.rev"
echo "$PFX"
