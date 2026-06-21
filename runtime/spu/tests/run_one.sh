#!/usr/bin/env bash
# Build and run ONE SPU integration test by name.
#
#   run_one.sh <name> [<gcc-path>]
#
# Each test is a pair of files:
#   gen_test_<name>.py   - encodes the SPU program and wraps it in an ELF.
#   test_<name>_main.c   - harness with channel-overriding stubs and asserts.
#
# Exit code is the verdict: 0 = pass, non-zero = build error or test failure.
# Honours $GCC, $PYTHON and $SANFLAGS env vars (CTest passes them through;
# SANFLAGS carries -fsanitize=... when the suite is built with PS3RECOMP_SANITIZE).
set -e

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../../.." && pwd)"
TOOLS="$REPO/tools"
RUNTIME_SPU="$REPO/runtime/spu"

name="$1"
GCC="${2:-${GCC:-gcc}}"
PYTHON="${PYTHON:-python3}"
[ -n "$name" ] || { echo "usage: run_one.sh <name> [gcc]" >&2; exit 2; }

gen="$HERE/gen_test_${name}.py"
main="$HERE/test_${name}_main.c"
[ -f "$gen" ]  || { echo "[skip] $name: no gen_test_${name}.py" >&2;  exit 3; }
[ -f "$main" ] || { echo "[skip] $name: no test_${name}_main.c" >&2; exit 3; }

elf="$HERE/test_${name}.elf"
# Use an `out_` prefix for generated dirs so `gen_test_*.py` and `out_*`
# never collide under a `rm -rf gen_*` glob.
gen_out="$HERE/out_${name}"
exe="$HERE/test_${name}.exe"

rm -rf "$gen_out"
"$PYTHON" "$gen" > /dev/null
"$PYTHON" "$TOOLS/spu_lifter.py" --auto-functions "$elf" \
    --output "$gen_out" > /dev/null

# Optional per-test extra build args (extra sources / -I dirs). A
# test_<name>.deps file is sourced with $REPO/$RUNTIME_SPU in scope and may
# set EXTRA="..." (e.g. to link a libs/ HLE module like cellSync.c).
EXTRA=""
[ -f "$HERE/test_${name}.deps" ] && . "$HERE/test_${name}.deps"

if ! "$GCC" -std=c11 -O2 $SANFLAGS -I "$gen_out" -I "$RUNTIME_SPU" \
    "$gen_out/spu_recomp.c" "$main" $EXTRA -o "$exe" \
    2> "$HERE/build_${name}.log"; then
    echo "[FAIL] $name: build error -- see build_${name}.log" >&2
    cat "$HERE/build_${name}.log" >&2
    exit 1
fi

exec "$exe"
