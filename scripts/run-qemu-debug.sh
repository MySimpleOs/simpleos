#!/usr/bin/env bash
# Boot a SimpleOS ISO in QEMU with the GDB stub enabled (-s -S).
# Pair with: x86_64-elf-gdb build/kernel.elf -ex 'target remote :1234'
# Stub for now; wire up in Faz 2.
set -euo pipefail

ISO="${1:-}"
if [[ -z "$ISO" ]]; then
    echo "usage: $0 <iso>" >&2
    exit 2
fi

echo "scripts/run-qemu-debug.sh: not implemented yet (Faz 2) — requested ISO: $ISO" >&2
exit 1
