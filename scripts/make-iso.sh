#!/usr/bin/env bash
# Faz 2 — bundle the kernel and Limine into a hybrid BIOS/UEFI ISO.
#
# Requires: xorriso on the host, Limine fetched into boot/limine (see
# scripts/fetch-limine.sh), and a built kernel ELF at $BUILD/kernel/simpleos.elf.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${SIMPLEOS_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
BUILD="${BUILD:-$ROOT/build}"
BOOT="$ROOT/boot"
LIMINE="$BOOT/limine"
KERNEL="$BUILD/kernel/simpleos.elf"
INITRD="$BUILD/initrd.tar"
ISO="$BUILD/simpleos.iso"
ISO_ROOT="$BUILD/iso_root"
LIMINE_CONF_GEN="$BUILD/limine.conf"
DISPLAY_CONF="$ROOT/rootfs/etc/display.conf"
LIMINE_TEMPLATE="$BOOT/limine.conf.in"

log() { printf '\e[1;34m[iso]\e[0m %s\n' "$*"; }
die() { printf '\e[1;31m[iso]\e[0m %s\n' "$*" >&2; exit 1; }

command -v xorriso >/dev/null 2>&1 || die "xorriso missing — apt-get install xorriso"
[[ -d "$LIMINE" ]]         || die "limine not fetched — run 'make limine' or scripts/fetch-limine.sh"
[[ -x "$LIMINE/limine" ]]  || die "limine host tool not built — run 'make -C $LIMINE'"
[[ -f "$LIMINE_TEMPLATE" ]] || die "missing $LIMINE_TEMPLATE"
[[ -f "$KERNEL" ]]         || die "kernel not built at $KERNEL — build kernel first (Faz 3)"

log "generating Limine config from $DISPLAY_CONF"
"$SCRIPT_DIR/gen-limine-conf.sh" "$DISPLAY_CONF" "$LIMINE_TEMPLATE" "$LIMINE_CONF_GEN"
[[ -f "$LIMINE_CONF_GEN" ]] || die "failed to write $LIMINE_CONF_GEN"

log "staging iso tree at $ISO_ROOT"
rm -rf "$ISO_ROOT"
mkdir -p "$ISO_ROOT/boot/limine" "$ISO_ROOT/EFI/BOOT"

install -m 0644 "$KERNEL"                    "$ISO_ROOT/boot/simpleos.elf"
install -m 0644 "$INITRD"                    "$ISO_ROOT/boot/initrd.tar"
install -m 0644 "$LIMINE_CONF_GEN"           "$ISO_ROOT/boot/limine/limine.conf"
install -m 0644 "$LIMINE/limine-bios.sys"    "$ISO_ROOT/boot/limine/"
install -m 0644 "$LIMINE/limine-bios-cd.bin" "$ISO_ROOT/boot/limine/"
install -m 0644 "$LIMINE/limine-uefi-cd.bin" "$ISO_ROOT/boot/limine/"
install -m 0644 "$LIMINE/BOOTX64.EFI"        "$ISO_ROOT/EFI/BOOT/"
install -m 0644 "$LIMINE/BOOTIA32.EFI"       "$ISO_ROOT/EFI/BOOT/"

log "building ISO at $ISO"
xorriso -as mkisofs \
    -b boot/limine/limine-bios-cd.bin \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    --efi-boot boot/limine/limine-uefi-cd.bin \
    -efi-boot-part --efi-boot-image --protective-msdos-label \
    "$ISO_ROOT" -o "$ISO"

log "installing BIOS boot sector via limine"
"$LIMINE/limine" bios-install "$ISO"

log "done — $ISO ($(du -h "$ISO" | awk '{print $1}'))"
