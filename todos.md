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
- [ ] `toolchain/versions.env`: binutils + gcc sürümlerini sabitle
- [ ] `scripts/build-toolchain.sh`: `x86_64-elf` target için binutils → gcc (freestanding, no libc) derle, `toolchain/out/` altına kur
- [ ] `toolchain/out/bin` PATH helper: `scripts/env.sh`
- [ ] Sanity: `x86_64-elf-gcc --version`, `x86_64-elf-ld --version`
- [ ] `toolchain/README.md`: kurulum + yeniden derleme adımları

## Faz 2 — `boot/` + Limine entegrasyonu
- [ ] `boot/limine/`: Limine binary'lerini (stage + EFI) getir (submodule veya scripts/fetch-limine.sh)
- [ ] `boot/limine.conf`: kernel path, cmdline, framebuffer isteği, modules
- [ ] `scripts/make-iso.sh`: `xorriso` + `limine-install` ile hybrid BIOS/UEFI ISO üret
- [ ] `scripts/run-qemu.sh`: `qemu-system-x86_64 -M q35 -m 512M -cdrom simpleos.iso -serial stdio`
- [ ] `scripts/run-qemu-debug.sh`: `-s -S` + GDB hazır `.gdbinit`

## Faz 3 — Minimum kernel ("Hello, framebuffer")
- [ ] `kernel/linker.ld`: higher-half `0xFFFFFFFF80000000`, bölümler hizalı
- [ ] `kernel/src/boot/limine_requests.c`: framebuffer + memmap + HHDM + kernel-address requests
- [ ] `kernel/src/kmain.c`: Limine framebuffer'a pixel yaz
- [ ] `kernel/Makefile`: `-ffreestanding -mno-red-zone -mcmodel=kernel -fno-stack-protector -nostdlib`
- [ ] QEMU'da framebuffer'da renkli kare görünsün — **Milestone 1**

## Faz 4 — Çekirdek altyapı
- [ ] Serial (COM1) erken log, `printk` ailesi
- [ ] Kendi GDT'n (Limine'ınkini değiştir) + TSS
- [ ] IDT + ISR/IRQ stubları (NASM/AT&T asm)
- [ ] CPU exception handler'ları, panic + register dump
- [ ] LAPIC timer (veya HPET), IOAPIC (PIC yerine; x86_64 + Limine = APIC)
- [ ] PS/2 klavye sürücüsü

## Faz 5 — Bellek yönetimi
- [ ] Limine memmap'i parse et
- [ ] Physical frame allocator (bitmap veya buddy)
- [ ] Sayfa tabloları: yeni PML4, higher-half + HHDM eşleme
- [ ] Virtual memory manager
- [ ] Heap: `kmalloc` / `kfree` (bump → slab/free-list)

## Faz 6 — ACPI & SMP (opsiyonel ama erken olursa kolay)
- [ ] RSDP'yi Limine'dan al, MADT parse
- [ ] AP'leri başlat (SMP bootstrap)
- [ ] Per-CPU state

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
