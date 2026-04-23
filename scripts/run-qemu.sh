#!/usr/bin/env bash
# Boot a SimpleOS ISO in QEMU.
# Target shape: qemu-system-x86_64 -M q35 -m 512M -cdrom <iso> -serial stdio
# Stub for now; wire up in Faz 2.
set -euo pipefail

ISO="${1:-}"
if [[ -z "$ISO" ]]; then
    echo "usage: $0 <iso>" >&2
    exit 2
fi

echo "scripts/run-qemu.sh: not implemented yet (Faz 2) — requested ISO: $ISO" >&2
exit 1
