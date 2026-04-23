#!/usr/bin/env bash
# Source this file to put the SimpleOS cross-toolchain on your PATH.
#   source scripts/env.sh

_SIMPLEOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SIMPLEOS_ROOT="$_SIMPLEOS_ROOT"
export PATH="$_SIMPLEOS_ROOT/toolchain/out/bin:$PATH"
unset _SIMPLEOS_ROOT
