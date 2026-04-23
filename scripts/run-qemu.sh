#!/usr/bin/env bash
# Boot a SimpleOS ISO in QEMU.
#   usage: run-qemu.sh [iso]
# Defaults to $SIMPLEOS_ROOT/build/simpleos.iso.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${SIMPLEOS_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

ISO="${1:-$ROOT/build/simpleos.iso}"
[[ -f "$ISO" ]] || { echo "ISO not found: $ISO" >&2; exit 1; }

command -v qemu-system-x86_64 >/dev/null 2>&1 \
    || { echo "qemu-system-x86_64 missing — apt-get install qemu-system-x86" >&2; exit 1; }

exec qemu-system-x86_64 \
    -M q35 \
    -m 512M \
    -smp "${SMP:-4}" \
    -vga virtio \
    -cdrom "$ISO" \
    -serial stdio \
    -no-reboot \
    -no-shutdown
