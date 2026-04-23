#!/usr/bin/env bash
# Boot a SimpleOS ISO in QEMU paused, with the GDB stub listening on :1234.
#   usage: run-qemu-debug.sh [iso]
# In a second terminal:
#   source scripts/env.sh
#   x86_64-elf-gdb build/kernel/simpleos.elf -x .gdbinit
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${SIMPLEOS_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

ISO="${1:-$ROOT/build/simpleos.iso}"
[[ -f "$ISO" ]] || { echo "ISO not found: $ISO" >&2; exit 1; }

command -v qemu-system-x86_64 >/dev/null 2>&1 \
    || { echo "qemu-system-x86_64 missing — apt-get install qemu-system-x86" >&2; exit 1; }

cat >&2 <<'BANNER'
[debug] QEMU is paused at vCPU reset; GDB stub on tcp::1234.
[debug] In another terminal:
[debug]   source scripts/env.sh
[debug]   x86_64-elf-gdb build/kernel/simpleos.elf -x .gdbinit
BANNER

exec qemu-system-x86_64 \
    -M q35 \
    -m 512M \
    -cdrom "$ISO" \
    -serial stdio \
    -no-reboot \
    -no-shutdown \
    -s -S
