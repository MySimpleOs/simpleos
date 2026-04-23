# SimpleOS — Architectural Decisions

Living document. Append new ADRs with a date and status; do not edit past entries
silently — mark them `superseded` and link forward instead.

---

## ADR-001 — Target architecture: `x86_64-elf`

- **Date**: 2026-04-23
- **Status**: accepted

**Context.** Target is modern 64-bit PC hardware. Long mode gives us NX, a flat
64-bit address space, `syscall`/`sysret`, and rich virtualization support.

**Decision.** All code is cross-compiled for `x86_64-elf` via a purpose-built
toolchain under `toolchain/`.

**Consequences.**
- All assembly is AMD64 — no i386 / no 16-bit real mode in the kernel.
- Kernel enters already in long mode (see ADR-002), so no mode-switch code.
- Paging is 4-level (PML4); Limine's HHDM makes physical access straightforward.

## ADR-002 — Bootloader: Limine

- **Date**: 2026-04-23
- **Status**: accepted

**Context.** Alternatives considered: GRUB + Multiboot2, a custom MBR/stage2,
Limine. Goal: minimize bring-up friction and reach a framebuffer "hello" fast.

**Decision.** Use the Limine bootloader and the Limine boot protocol.

**Consequences.**
- Kernel starts in 64-bit long mode with paging enabled and higher-half mapped.
- HHDM (Higher-Half Direct Map), framebuffer, memory map, RSDP, SMP info, and
  modules are all delivered via protocol requests — no BIOS calls.
- ISO production uses `xorriso` + `limine-install` and yields a hybrid BIOS/UEFI
  image.
- No Multiboot2 header, no A20 handling, no real-mode stubs.

## ADR-003 — Primary emulator: QEMU

- **Date**: 2026-04-23
- **Status**: accepted

**Decision.** `qemu-system-x86_64 -M q35` is the primary development target.
Bochs may be added later for deep CPU-state debugging.

**Consequences.**
- Serial-on-stdio log pipeline (`-serial stdio`).
- GDB stub via `-s -S` for source-level kernel debugging.
- Headless runs are possible, which makes CI smoke tests cheap.

## ADR-004 — Build system: top-level GNU Make

- **Date**: 2026-04-23
- **Status**: accepted

**Decision.** The root `Makefile` orchestrates submodule builds; each submodule
owns its own `Makefile`. No CMake, no Meson.

**Consequences.**
- Targets cross module boundaries via `$(MAKE) -C <submodule>`.
- Build artifacts live under `build/` at the repo root.
- Toolchain install prefix is `toolchain/out/`; users `source scripts/env.sh`
  to put it on `PATH`.

## ADR-005 — libc strategy: freestanding first, hosted later

- **Date**: 2026-04-23
- **Status**: accepted

**Decision.** `libc/` begins as a freestanding subset — `string.h`, a
serial-backed `stdio.h`, minimal `stdlib.h`. Hosted/userland features land once
the kernel has a stable syscall ABI and a VFS (Faz 8+).

**Consequences.**
- The kernel compiles with `-ffreestanding -nostdlib` and does not depend on
  `libc/`.
- Userland programs start linking against `libc/` only after Faz 8.
- Symbol surface grows monotonically; we will not break the freestanding ABI
  once userland starts using it.
