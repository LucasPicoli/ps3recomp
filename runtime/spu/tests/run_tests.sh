#!/usr/bin/env bash
# Build and run every integration test in this directory.
#
# Each test is a pair of files:
#   gen_test_<name>.py   - encodes the SPU program and wraps it in an ELF.
#   test_<name>_main.c   - harness with channel-overriding stubs and asserts.
#
# This is a thin batch driver over run_one.sh (which builds+runs a single
# test); CTest registers each test individually via the same run_one.sh, so
# the batch script and the CTest gate share one implementation.
#
# Usage: ./run_tests.sh  [<gcc-path>]
# Honours $GCC and $PYTHON env vars.

HERE="$(cd "$(dirname "$0")" && pwd)"
GCC="${1:-${GCC:-gcc}}"

pass=0
fail=0
failed_tests=()

for gen in "$HERE"/gen_test_*.py; do
    name=$(basename "$gen" .py)
    name=${name#gen_test_}
    main="$HERE/test_${name}_main.c"
    [ -f "$main" ] || { echo "[skip] $name: no test_${name}_main.c"; continue; }

    if out=$(GCC="$GCC" "$HERE/run_one.sh" "$name" 2>&1); then
        echo "[PASS] $name -- $out"
        pass=$((pass+1))
    else
        echo "[FAIL] $name"
        echo "$out" | sed 's/^/   /'
        failed_tests+=("$name")
        fail=$((fail+1))
    fi
done

echo
echo "==========================================="
echo "Results: $pass passed, $fail failed"
[ $fail -eq 0 ] || { echo "Failed: ${failed_tests[*]}"; exit 1; }
