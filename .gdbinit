# SimpleOS GDB helper — pair with scripts/run-qemu-debug.sh.
# Invoke explicitly: x86_64-elf-gdb build/kernel/simpleos.elf -x .gdbinit
# (GDB ignores CWD .gdbinit by default unless --auto-load-safe-path allows it.)

set confirm off
set pagination off
set disassembly-flavor intel
set architecture i386:x86-64

target remote :1234
