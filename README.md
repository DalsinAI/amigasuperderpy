# SuperDerpy for GFOS

SuperDerpy (Sebastian Krzyszkowiak's Allegro 5 game: fly Derpy Hooves
through muffin-zombie levels) built for GFOS (AmigaOS 3.2.3 with GFOpenUp)
on a 68040, on amigaallegro: Allegro 5 drawing through SDL2.module,
GL.module and OpenGPU, with FLAC and Ogg Vorbis sound and TTF text.

## Install

    1> GFOpenUpTool INSTALL Parts/SuperDerpy

installs `SYS:Games/SuperDerpy/` (the game, its data, licence). Needs a 68040
or 68060. The game starts full screen at 800 x 450; set `fullscreen=0` under
`[SuperDerpy]` in its config to play in a window.

## Build

    STOVE=~/AmiCradle/stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh

`sd.lock` pins SuperDerpy and amigaallegro by commit (libogg 1.3.5,
libvorbis 1.3.7 and libFLAC 1.4.3 by tag and commit in
scripts/build-allegro.sh); nothing third-party is kept in this repository.

## Tests

    SD_SRC=<superderpy checkout> sh tests/test_host.sh

## Licence and content

GPL-2.0-or-later, like SuperDerpy (see LICENSE). It is a fan game: its art,
names and characters need a content review before any release of this part.
Port: Copyright (c) 2026 AmiCradle Team.

Designed, tested and delivered by The AmiCradle Team.
