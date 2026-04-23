# SimpleOS — top-level orchestration
# Target: x86_64-elf · Bootloader: Limine · Emulator: QEMU

SHELL := /bin/bash
.DEFAULT_GOAL := help

ROOT      := $(abspath .)
TOOLCHAIN := $(ROOT)/toolchain
KERNEL    := $(ROOT)/kernel
LIBC      := $(ROOT)/libc
USERLAND  := $(ROOT)/userland
BOOT      := $(ROOT)/boot
SCRIPTS   := $(ROOT)/scripts
BUILD     := $(ROOT)/build
ISO       := $(BUILD)/simpleos.iso

export ROOT BUILD

.PHONY: help all toolchain limine kernel libc userland iso run run-debug clean distclean

help:
	@echo "SimpleOS targets:"
	@echo "  make toolchain   build cross-compiler (x86_64-elf)"
	@echo "  make limine      fetch Limine bootloader binaries"
	@echo "  make kernel      build kernel"
	@echo "  make libc        build libc"
	@echo "  make userland    build userland programs"
	@echo "  make all         kernel + libc + userland"
	@echo "  make iso         produce bootable ISO via Limine"
	@echo "  make run         boot ISO in QEMU"
	@echo "  make run-debug   boot ISO in QEMU with GDB stub (-s -S)"
	@echo "  make clean       remove build artifacts"
	@echo "  make distclean   clean + remove toolchain output + limine"

all: kernel libc userland

toolchain:
	$(SCRIPTS)/build-toolchain.sh

# Fetch Limine only when the host tool is missing; re-run fetch-limine.sh
# directly to force-update to the tip of the pinned branch.
limine: $(BOOT)/limine/limine

$(BOOT)/limine/limine:
	$(SCRIPTS)/fetch-limine.sh

# Submodule targets are no-ops until each submodule gains its own Makefile.
kernel:
	@if [ -f $(KERNEL)/Makefile ]; then $(MAKE) -C $(KERNEL); \
	 else echo "[kernel]   no Makefile yet (Faz 3)"; fi

libc:
	@if [ -f $(LIBC)/Makefile ]; then $(MAKE) -C $(LIBC); \
	 else echo "[libc]     no Makefile yet (Faz 8)"; fi

userland:
	@if [ -f $(USERLAND)/Makefile ]; then $(MAKE) -C $(USERLAND); \
	 else echo "[userland] no Makefile yet (Faz 10)"; fi

iso: all limine
	$(SCRIPTS)/make-iso.sh

run: iso
	$(SCRIPTS)/run-qemu.sh $(ISO)

run-debug: iso
	$(SCRIPTS)/run-qemu-debug.sh $(ISO)

clean:
	@for d in $(KERNEL) $(LIBC) $(USERLAND); do \
	  if [ -f $$d/Makefile ]; then $(MAKE) -C $$d clean; fi; \
	done
	rm -rf $(BUILD)

distclean: clean
	rm -rf $(TOOLCHAIN)/out $(BOOT)/limine
