#!/bin/sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
sh "$HERE/test_lock.sh"; sh "$HERE/test-part.sh"
