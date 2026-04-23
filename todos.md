# SimpleOS — Todos

Target: **x86_64-elf** · Bootloader: **Limine** · Emulator: **QEMU**

Format: `[ ]` todo, `[x]` done. Faz sırası zorunlu değil ama bağımlılıklar var.

---

## Faz 0 — Kararlar & iskelet
- [x] `docs/DECISIONS.md`: arch=x86_64-elf, boot=Limine, emulator=QEMU, build=Make, libc=freestanding→hosted
- [x] Üst `Makefile`: `all`, `iso`, `run`, `run-debug`, `clean` hedefleri (submodülleri çağırır)
- [x] `.editorconfig`, kök `.clang-format`
- [x] `scripts/` iskeleti: `build-toolchain.sh`, `make-iso.sh`, `run-qemu.sh`, `run-qemu-debug.sh` (+ `env.sh`)

## Faz 1 — `toolchain/`
- [x] `toolchain/versions.env`: binutils 2.43 + gcc 14.2.0 pin (env ile override)
- [x] `scripts/build-toolchain.sh`: `x86_64-elf` target için binutils → gcc (freestanding, no libc) derle, `toolchain/out/` altına kur; re-entrant, sha256 opsiyonel
- [x] `toolchain/out/bin` PATH helper: `scripts/env.sh` (Faz 0'da eklendi)
- [x] Sanity: `x86_64-elf-gcc 14.2.0` + `GNU ld (Binutils) 2.43` doğrulandı (2026-04-23)
- [x] `toolchain/README.md`: kurulum + yeniden derleme + host paket listesi

## Faz 2 — `boot/` + Limine entegrasyonu
- [x] `boot/limine/`: `scripts/fetch-limine.sh` v9.x-binary'i clone'lar + host tool'u build eder (Limine 9.6.7 doğrulandı)
- [x] `boot/limine.conf`: Limine protokolü, `kernel_path: boot():/boot/simpleos.elf`
- [x] `scripts/make-iso.sh`: `xorriso` + `limine bios-install` ile hybrid BIOS/UEFI ISO
- [x] `scripts/run-qemu.sh`: `qemu-system-x86_64 -M q35 -m 512M -serial stdio`
- [x] `scripts/run-qemu-debug.sh`: `-s -S` + `.gdbinit`

## Faz 3 — Minimum kernel ("Hello, framebuffer")
- [x] `kernel/linker.ld`: higher-half `0xffffffff80000000`, 4 PT_LOAD (requests/text/rodata/data), `.eh_frame` DISCARD
- [x] `kernel/src/limine_requests.c`: base revision 3 + framebuffer request + start/end markers
- [x] `kernel/src/kmain.c`: framebuffer'a arka plan + merkezî 200×200 kare
- [x] `kernel/Makefile`: `x86_64-elf-gcc -ffreestanding -mno-red-zone -mcmodel=kernel -mgeneral-regs-only -fno-stack-protector -fno-PIC`
- [x] QEMU'da renkli kare göründü (screendump doğrulandı) — **Milestone 1 ✅**

## Faz 4 — Çekirdek altyapı
- [x] **4.1** Serial (COM1) + `kprintf` (%c %s %d %u %x %X %p %%, width/0-pad)
- [x] **4.2** Kendi GDT + TSS (5 entry + TSS; rsp0 → 16 KiB kernel stack)
- [x] **4.3** IDT + ISR stub'ları + exception handler'ı + panic (int3 ile doğrulandı)
- [x] **4.4** PIC disable + ACPI/MADT parse + LAPIC enable + minimal `mmio_map()` (reserved MMIO için)
- [x] **4.5** LAPIC timer PIT ile kalibre, periodic 100 Hz, IRQ vector 0x20
- [x] **4.6** IOAPIC + PS/2 keyboard (IRQ1 → vector 0x21, scan set 1 → ASCII)

## Faz 5 — Bellek yönetimi
- [x] **5.1** Limine memmap → PMM bitmap (USABLE-only extent, HHDM-accessed, alloc_hint imleci, pre-zero)
- [x] **5.2** Generic `vmm_map/unmap` (W/USER/PCD/NX flags), PMM-backed page tables, `mmio_map` wrapper
- [x] **5.3** Heap: `kmalloc/kfree`, first-fit free-list, forward+backward coalesce, lazy page growth (256 KiB initial @ 0xFFFFFFFF90000000)
- ~~Yeni PML4 / higher-half transition~~ — Limine base rev 3 zaten higher-half + HHDM map'i veriyor; kendi PML4'ümüz Faz 7 (per-process address space) ile gelecek

## Faz 6 — ACPI & SMP (opsiyonel ama erken olursa kolay)
- [x] RSDP'yi Limine'dan al, MADT parse (Faz 4.4'te yapıldı — `acpi.c`, LAPIC+IOAPIC+CPU count çıkarıldı)
- [x] AP'leri başlat (SMP bootstrap) — Limine MP request üzerinden, her AP kendi stack'iyle GDT/IDT/LAPIC yükler
- [x] Per-CPU state — `struct cpu_local` (cpu_id, lapic_id, kernel_stack_top), BSP `kmalloc` ile array'i kuruyor

## Faz 7 — Süreçler & scheduler
- [ ] Kernel thread + context switch
- [ ] Round-robin scheduler, idle task
- [ ] Ring 3'e geçiş, TSS RSP0
- [ ] `syscall`/`sysret` MSR kurulumu + syscall dispatcher

## Faz 8 — `libc/` (önce freestanding, sonra hosted)
- [ ] `string.h`: `memcpy`, `memset`, `memmove`, `memcmp`, `strlen`, `strcmp`, `strncmp`, `strcpy`
- [ ] `stdio.h`: `printf`, `snprintf`, `puts`, `putchar` (syscall üstüne)
- [ ] `stdlib.h`: `malloc`, `free`, `exit`, `abort`
- [ ] Syscall wrapper'ları: `write`, `read`, `open`, `close`, `exit`
- [ ] `crt0.S` + userland linker script

## Faz 9 — VFS + ilk dosya sistemi
- [ ] VFS: `vnode`/`file` ops
- [ ] Limine modules'den initrd (tar/USTAR) mount et
- [ ] `/dev/console`, `/dev/null`

## Faz 10 — `userland/`
- [ ] `init`: ilk user process, `/bin/sh`'i exec et
- [ ] `sh`: minimum (exec, cd, exit)
- [ ] Coreutils minimum: `echo`, `ls`, `cat`, `clear`

## Faz 11 — Kalite
- [ ] CI: GitHub Actions — toolchain cache, kernel build, QEMU headless smoke (`-no-reboot`, log parse)
- [ ] `docs/`: her faz için kısa yazı + ekran görüntüleri
- [ ] `CONTRIBUTING.md`

---

## Aktif milestone
**M1** — QEMU'da Limine ile bootlayan x86_64 kernel framebuffer'a yazsın.

Tick sırası: Faz 0 → Faz 1 → Faz 2 → Faz 3.
